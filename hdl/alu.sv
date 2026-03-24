module alu (
    input wire[4:0] opcode,
    input wire[63:0] rs,
    input wire[63:0] rt,
    input wire[11:0] literal,

    output reg is_rd_increment,
    output reg signed[11:0] rd_increment_amount,
    output reg[63:0] rslt
);
    always @(*) begin
        is_rd_increment = 0;

        case (opcode)
            //Integer Operations
            5'h18: rslt = $signed(rs)+$signed(rt);
            5'h19:
                is_rd_increment = 1;
                rd_increment_amount = literal;
            5'h1a: rslt = $signed(rs)-$signed(rt);
            5'h1b:
                is_rd_increment = 1;
                rd_increment_amount = -literal;
            5'h1c: rslt = $signed(rs)*$signed(rt);
            5'h1d: rslt = $signed(rs)/$signed(rt);

            //Logical Operations
            5'h00: rslt = rs & rt;
            5'h01: rslt = rs | rt;
            5'h02: rslt = rs ^ rt;
            5'h03: rslt = ~rs;

            //Shift Operations
            5'h04: rslt = rs >> rt;
            5'h05: rslt = rd >> literal;
            5'h06: rslt = rs << rt;
            5'h07: rslt = rd << literal;

            default: rslt = 0;
        endcase
    end

endmodule