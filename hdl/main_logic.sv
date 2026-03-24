module main_logic(
    input clk,
    input wire[4:0] opcode,
    input wire[63:0] rd_val, rs_val, rt_val,
    input wire[11:0] literal,
    input wire[63:0] pc, r31_val, return_address, load_data,

    output reg is_write_reg, is_write_mem,
    output reg[63:0] rslt_pc, write_data_reg, write_address_mem, write_data_mem
);
    reg[63:0] alu_rslt;
    alu alu_unit(
        .opcode(opcode),
        .rd_val(rd_val),
        .rs_val(rs_val),
        .rt_val(rt_val),
        .literal(literal),
        .rslt(alu_rslt)
    );

    reg[63:0] fpu_rslt;
    fpu fpu_unit(
        .opcode(opcode),
        .rs_val(rs_val),
        .rt_val(rt_val),
        .literal(literal),
        .rslt(fpu_rslt)
    );

    reg is_write_branch;
    reg[63:0] new_pc, write_address_branch, write_data_branch;
    branch branch_unit(
        .opcode(opcode),
        .rd_val(rd_val),
        .rs_val(rs_val),
        .rt_val(rt_val),
        .literal(literal),
        .pc(pc),
        .r31_val(r31_val),
        .return_address(return_address),

        .is_write(is_write_branch),
        .new_pc(new_pc),
        .write_address(write_address_branch),
        .write_data(write_data_branch)
    );

    reg is_write_mov_reg, is_write_mov_mem;
    reg[63:0] write_data_mov_reg, write_address_mov_mem, write_data_mov_mem;
    mov mov_unit(
        .opcode(opcode),
        .rd_val(rd_val),
        .rs_val(rs_val),
        .rt_val(rt_val),
        .literal(literal),
        .load_data(load_data),

        .is_write_mem(is_write_mov_mem),
        .is_write_reg(is_write_mov_reg),
        .write_data_mem(write_data_mov_mem),
        .write_data_reg(write_data_mov_reg)
    );
    

    always @(posedge clk) begin
        is_write_reg = 0;
        is_write_mem = 0;
        rslt_pc = pc + 4;
        case (opcode) begin
            5'h18, 5'h19, 5'h1a, 5'h1b, 5'h1c, 5'h1d, 5'h00, 5'h01, 5'h02, 5'h03, 5'h04, 5'h05, 5'h06, 5'h07: begin
                write_data_reg = alu_rslt;
                is_write_reg = 1;
            end
            5'h14, 5'h15, 5'h16, 5'h17: begin
                write_data_reg = fpu_rslt;
                is_write_reg = 1;
            end
            5'h08, 5'h09, 5'h0a, 5'h0b, 5'h0c, 5'h0d, 5'h0e: begin
                rslt_pc = new_pc;
                is_write_mem = is_write_branch;
                write_address_mem = write_address_branch;
                write_data_mem = write_data_branch;
            end
            5'h10, 5'h11, 5'h12, 5'h13: begin
                is_write_reg = is_write_mov_reg;
                write_data_reg = write_data_mov_reg;
                is_write_mem = is_write_mov_mem;
                write_address_mem = write_address_mov_mem;
                write_data_mem = write_data_mov_mem;
                write_data_reg = write_data_mov_reg;
            end
        end
    end
endmodule