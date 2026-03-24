module branch(
    input clk,
    input wire[4:0] opcode,
    input wire[63:0] rd, rs, rt,
    input wire signed[11:0] literal,
    input wire[63:0] pc, r31, return_address,

    output wire is_write,
    output reg[63:0] new_pc, write_address, write_data
);

    always @(*) begin
        case (opcode)
            5'h08: new_pc = rd-4;
            5'h09: new_pc = pc + rd - 4;
            5'h0a: new_pc = pc + $signed(literal);
            5'h0b: new_pc = (rs == 0) ? pc : rd-4;
            5'h0c:
                new_pc = rd-4;
                write_address = return_address;
                is_write = 1;
                write_data = pc + 4;
            5'h0d:
                new_pc = return_address-4;
            5'h0e:
                new_pc = (rs <= rt) ? pc : rd-4;
            default:
                new_pc = pc;
        endcase
    end

endmodule