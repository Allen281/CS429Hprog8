module alu (
    input wire[4:0] opcode,
    input wire[63:0] rd_val, rs_val, rt_val,
    input wire[11:0] literal,

    output reg[63:0] rslt
);
    always @(*) begin
        case (opcode)
            //Integer Operations
            5'h18: rslt = $signed(rs_val)+$signed(rt_val);
            5'h19: rslt = $signed(rd_val)+$signed(literal);
            5'h1a: rslt = $signed(rs_val)-$signed(rt_val);
            5'h1b: rslt = $signed(rd_val)-$signed(literal);
            5'h1c: rslt = $signed(rs_val)*$signed(rt_val);
            5'h1d: rslt = $signed(rs_val)/$signed(rt_val);

            //Logical Operations
            5'h00: rslt = rs_val & rt_val;
            5'h01: rslt = rs_val | rt_val;
            5'h02: rslt = rs_val ^ rt_val;
            5'h03: rslt = ~rs_val;

            //Shift Operations
            5'h04: rslt = rs_val >> rt_val;
            5'h05: rslt = rd_val >> literal;
            5'h06: rslt = rs_val << rt_val;
            5'h07: rslt = rd_val << literal;

            default: rslt = 0;
        endcase
    end

endmodule