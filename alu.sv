module alu (
    input wire[4:0] opcode,
    input wire[63:0] input1, input2,

    output reg[63:0] rslt
);
    always @(*) begin
        case (opcode)
            //Integer Operations
            5'h18: rslt = $signed(input1)+$signed(input2);
            5'h19: rslt = $signed(input1)+input2;
            5'h1a: rslt = $signed(input1)-$signed(input2);
            5'h1b: rslt = $signed(input1)-input2;
            5'h1c: rslt = $signed(input1)*$signed(input2);
            5'h1d: rslt = $signed(input1)/$signed(input2);

            //Logical Operations
            5'h00: rslt = input1 & input2;
            5'h01: rslt = input1 | input2;
            5'h02: rslt = input1 ^ input2;
            5'h03: rslt = ~input1;

            //Shift Operations
            5'h04: rslt = input1 >> input2;
            5'h05: rslt = input1 >> input2;
            5'h06: rslt = input1 << input2;
            5'h07: rslt = input1 << input2;

            default: rslt = 0;
        endcase
    end
endmodule