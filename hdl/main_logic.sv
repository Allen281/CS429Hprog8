module main_logic(
    input clk,
    input wire[4:0] opcode,
    input wire[63:0] rs_val, rt_val,
    input wire[11:0] literal,
    input wire[63:0] pc, r31, return_address, load_data,

    output reg is_write_reg_rslt, is_write_mem_rslt, is_rd_increment_rslt,
    output reg[63:0] read_rslt, rslt_pc, write_data_reg, write_address_mem, write_data_mem,
    output reg[11:0] rd_increment_amount_rslt;
);
    wire[63:0] alu_rslt, fpu_rslt, write_address_branch, write_data_branch, new_pc, write_data_mem, write_address_mem, write_data_reg, read_rslt_mov;
    wire is_write_branch, is_write_mem, is_write_reg;
    reg is_rd_increment;
    reg[11:0] rd_increment_amount;

    alu int_arith(opcode, rs_val, rt_val, literal, is_rd_increment, rd_increment_amount, alu_rslt);
    fpu float_arith(opcode, rs_val, rt_val, fpu_rslt);
    mov data_movement(clk, opcode, rs_val, rt_val, literal, load_data, is_write_mem, is_write_reg, read_rslt_mov, write_data_mem, write_address_mem, write_data_reg);
    branch control_flow(clk, opcode, rs_val, rt_val, literal, pc, r31, return_address, is_write_branch, new_pc, write_address_branch, write_data_branch);

    always @(*) begin
        is_write_reg_rslt = 0;
        is_write_mem_rslt = 0;
        rslt_pc = pc;
        case (opcode) begin
            5'h18, 5'h19, 5'h1a, 5'h1b, 5'h1c, 5'h1d, 5'h00, 5'h01, 5'h02, 5'h03, 5'h04, 5'h05, 5'h06, 5'h07:
                read_rslt = alu_rslt;
                is_write_reg_rslt = 1;
                rd_increment_amount_rslt = rd_increment_amount;
                is_rd_increment_rslt = is_rd_increment;
            5'h14, 5'h15, 5'h16, 5'h17:
                read_rslt = fpu_rslt;
                is_write_reg_rslt = 1;
            5'h08, 5'h09, 5'h0a, 5'h0b, 5'h0c, 5'h0d, 5'h0e:
                rslt_pc = new_pc;
                is_write_mem_rslt = is_write_branch;
                write_address_mem = write_address_branch;
                write_data_mem = write_data_branch;
            5'h10, 5'h11, 5'h12, 5'h13:
                is_write_reg_rslt = is_write_reg;
                write_data_reg = write_data_reg;
                is_write_mem_rslt = is_write_mem;
                write_address_mem = write_address_mem;
                write_data_mem = write_data_mem;
                read_rslt = read_rslt_mov;
        end
    end
endmodule