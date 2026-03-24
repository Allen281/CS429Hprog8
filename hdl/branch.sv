module branch(
    input wire[4:0] opcode,
    input wire[63:0] rd_val, rs_val, rt_val,
    input wire signed[11:0] literal,
    input wire[63:0] pc, r31, return_address,

    output reg is_write,
    output reg[63:0] new_pc, write_address, write_data
);

    always @(*) begin
        case (opcode)
            5'h08: new_pc = rd_val-4;
            5'h09: new_pc = pc + rd_val-4;
            5'h0a: new_pc = pc + $signed(literal)-4;
            5'h0b: new_pc = (rs_val == 0) ? pc : rd_val-4;
            5'h0c: begin
                new_pc = rd_val-4;
                write_address = return_address;
                is_write = 1;
                write_data = pc+4;
            end
            5'h0d: new_pc = return_address-4;
            5'h0e: new_pc = (rs_val <= rt_val) ? pc : rd_val-4;
            default: new_pc = pc;
        endcase
    end

endmodule