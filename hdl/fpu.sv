module float_unpacker(
    input wire[63:0] in,
    output wire sign,
    output wire[11:0] exp,
    output wire[52:0] mant
);
    assign sign = in[63];

    wire[10:0] in_exp = in[62:52];
    wire[51:0] in_mant = in[51:0];

    assign exp = (in_exp == 11'b0) ? 12'd1 : {1'b0, in_exp};
    assign mant = (in_exp == 11'b0) ? {1'b0, in_mant} : {1'b1, in_mant};
endmodule

module fpu_add_sub(
    input wire is_subtract,
    input wire rs_sign, rt_sign,
    input wire signed[11:0] rs_exp, rt_exp,
    input wire[52:0] rs_mant, rt_mant,
    
    output wire rslt_sign,
    output wire signed[12:0] rslt_exp,
    output wire[53:0] rslt_mant
);
    wire new_rt_sign = is_subtract ? ~rt_sign : rt_sign;
    
    wire rs_bigger = rs_exp > rt_exp || (rs_exp == rt_exp && rs_mant >= rt_mant);
    wire[12:0] exp_shift = rs_bigger ? rs_exp - rt_exp : rt_exp - rs_exp;

    wire[53:0] shifted_rs_mant = rs_bigger ? {1'b0, rs_mant} : ({1'b0, rs_mant} >> exp_shift);
    wire[53:0] shifted_rt_mant = rs_bigger ? ({1'b0, rt_mant} >> exp_shift) : {1'b0, rt_mant};

    assign rslt_sign = rs_bigger ? rs_sign : new_rt_sign;
    assign rslt_exp = rs_bigger ? {1'b0, rs_exp} : {1'b0, rt_exp};
    assign rslt_mant = (rs_sign == new_rt_sign) ? (shifted_rs_mant + shifted_rt_mant) : 
                        rs_bigger ? (shifted_rs_mant - shifted_rt_mant) : (shifted_rt_mant - shifted_rs_mant);
endmodule

module fpu_mult_div (
    input wire is_divide,
    input wire rs_sign, rt_sign,
    input wire signed[11:0] rs_exp, rt_exp,
    input wire[52:0] rs_mant, rt_mant,
    
    output wire rslt_sign,
    output wire signed[12:0] rslt_exp,
    output wire[53:0] rslt_mant
);
    wire[105:0] mult_mant = rs_mant * rt_mant;
    wire[104:0] rs_mant_padded = {rs_mant, 52'b0};
    wire[53:0] div_mant = rs_mant_padded / rt_mant;

    assign rslt_sign = rs_sign ^ rt_sign;
    assign rslt_exp = is_divide ? (rs_exp - rt_exp + 1023) : (rs_exp + rt_exp - 1023);
    assign rslt_mant = (is_divide) ? div_mant : mult_mant[105:52];
endmodule

module float_normalizer (
    input wire sign,
    input wire signed[12:0] exp,
    input wire[53:0] mant,
    
    output reg[63:0] rslt
);
    reg signed[13:0] norm_exp;
    reg[52:0] norm_mant;
    reg found;
    integer i;

    always @(*) begin
        norm_exp = exp;
        norm_mant = mant;
        found = 0;

        if(mant == 0) begin
            rslt = {sign, 63'b0};
        end else if (mant[53] == 1'b1) begin
            norm_mant = mant >> 1;
            norm_exp = exp + 1;
        end else begin
            for(i = 52; i >= 0; i = i-1) begin
                if (mant[i] == 1'b1 && !found) begin
                    norm_mant = mant << (52-i);
                    norm_exp = exp - (52-i);
                    found = 1;
                end
            end
        end

        if(norm_exp >= 2047) begin
            rslt = {sign, {11{1'b1}}, 52'b0};
        end else if (norm_exp <= 0 && norm_mant != 0) begin
            norm_mant = norm_mant >> (1 - norm_exp);
            rslt = {sign, 11'b0, norm_mant[51:0]};
        end else if (norm_exp != 0 && norm_mant != 0)begin
            rslt = {sign, norm_exp[10:0], norm_mant[51:0]};
        end
    end
endmodule

module check_special_case(
    input wire[4:0] opcode,
    input wire[63:0] input1, input2,

    output reg is_special,
    output reg[63:0] special_case
);
    wire sign1 = input1[63];
    wire sign2 = input2[63];
    wire[10:0] exp1 = input1[62:52];
    wire[51:0] mant1 = input1[51:0];
    wire[10:0] exp2 = input2[62:52];
    wire[51:0] mant2 = input2[51:0];

    wire is_nan1  = (exp1 == {11{1'b1}} && mant1 != 0);
    wire is_nan2  = (exp2 == {11{1'b1}} && mant2 != 0);
    wire is_inf1  = (exp1 == {11{1'b1}} && mant1 == 0);
    wire is_inf2  = (exp2 == {11{1'b1}} && mant2 == 0);
    wire is_zero1 = (exp1 == 0 && mant1 == 0);
    wire is_zero2 = (exp2 == 0 && mant2 == 0);

    always @(*) begin
        is_special = 0;
        special_case = 63'b0;

        //Nan check
        if (is_nan1 || is_nan2) begin
            is_special = 1;
            special_case = {1'b0, {11{1'b1}}, 52'b1};
        end 
        
        //Double infinity
        else if (is_inf1 && is_inf2) begin
            is_special = 1;
            //Nan
            if ((opcode == 5'h14 && sign1 != sign2) || (opcode == 5'h15 && sign1 == sign2) || (opcode == 5'h17)) begin
                special_case = {1'b0, {11{1'b1}}, 52'b1};
            //Multiplication
            end else if (opcode == 5'h16) begin
                special_case = {sign1 ^ sign2, {11{1'b1}}, 52'b0};
            end else begin
                special_case = {sign1, {11{1'b1}}, 52'b0};
            end
        end 
        
        //inf + 0
        else if ((is_inf1 && is_zero2) || (is_zero1 && is_inf2)) begin
            is_special = 1;
            //inf * 0 = NaN
            if (opcode == 5'h16) begin
                special_case = {1'b0, {11{1'b1}}, 52'b1}; 
            //inf / 0 = inf
            end else if (is_inf1 && opcode == 5'h17) begin
                special_case = {sign1 ^ sign2, {11{1'b1}}, 52'b0}; 
            // 0 / Inf = 0
            end else if (is_zero1 && opcode == 5'h17) begin
                special_case = {sign1 ^ sign2, 63'b0}; 
            end else begin
                if (opcode == 5'h15 && is_inf2) 
                    special_case = {~sign2, {11{1'b1}}, 52'b0};
                else 
                    special_case = is_inf1 ? {sign1, {11{1'b1}}, 52'b0} : {sign2, {11{1'b1}}, 52'b0};
            end
        end 
        
        //Double 0
        else if (is_zero1 && is_zero2) begin
            is_special = 1;
            if (opcode == 5'h14) special_case = {sign1 & sign2, 63'b0};
            else if (opcode == 5'h15) special_case = {sign1 & ~sign2, 63'b0};
            else if (opcode == 5'h16) special_case = {sign1 ^ sign2, 63'b0};
            else if (opcode == 5'h17) special_case = {1'b0, {11{1'b1}}, 52'b1};
        end
        
        //Divide by 0
        else if (is_zero2 && opcode == 5'h17) begin
            is_special = 1;
            special_case = {sign1 ^ sign2, {11{1'b1}}, 52'b0};
        end 
        
        //Infinity
        else if (is_inf1 || is_inf2) begin
            is_special = 1;
            if (opcode == 5'h16) begin
                special_case = {sign1 ^ sign2, {11{1'b1}}, 52'b0};
            end else if (opcode == 5'h17) begin
                if (is_inf1) special_case = {sign1 ^ sign2, {11{1'b1}}, 52'b0};
                else special_case = {sign1 ^ sign2, 63'b0};   
            end else if (opcode == 5'h14) begin
                special_case = is_inf1 ? {sign1, {11{1'b1}}, 52'b0} : {sign2, {11{1'b1}}, 52'b0};
            end else if (opcode == 5'h15) begin
                special_case = is_inf1 ? {sign1, {11{1'b1}}, 52'b0} : {~sign2, {11{1'b1}}, 52'b0};
            end
        end
    end
endmodule

module fpu (
    input wire[4:0] opcode,
    input wire[63:0] rs_val, rt_val,
    output reg[63:0] rslt
);

    wire is_special;
    wire[63:0] special_case;
    check_special_case special_case_checker(
        .opcode(opcode),
        .input1(rs_val),
        .input2(rt_val),
        .is_special(is_special),
        .special_case(special_case)
    );

    wire rs_sign, rt_sign;
    wire[11:0] rs_exp, rt_exp;
    wire[52:0] rs_mant, rt_mant;

    float_unpacker rs_unpack(rs_val, rs_sign, rs_exp, rs_mant);
    float_unpacker rt_unpack(rt_val, rt_sign, rt_exp, rt_mant);

    wire is_subtract = (opcode == 5'h15);
    wire is_divide = (opcode == 5'h17);

    wire add_sign, mult_sign;
    wire signed[12:0] add_exp, mult_exp;
    wire[53:0] add_mant, mult_mant;

    fpu_add_sub add_sub(is_subtract, rs_sign, rt_sign, rs_exp, rt_exp, rs_mant, rt_mant, add_sign, add_exp, add_mant);
    fpu_mult_div mult_div(is_divide, rs_sign, rt_sign, rs_exp, rt_exp, rs_mant, rt_mant, mult_sign, mult_exp, mult_mant);

    wire[63:0] add_rslt, mult_rslt;
    float_normalizer add_norm(add_sign, add_exp, add_mant, add_rslt);
    float_normalizer mult_norm(mult_sign, mult_exp, mult_mant, mult_rslt);
    
    always @(*) begin
        case (opcode)
            5'h14, 5'h15: rslt = add_rslt;
            5'h16, 5'h17: rslt = mult_rslt;
        endcase

        if(is_special) rslt = special_case;
    end
endmodule