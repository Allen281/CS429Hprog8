module decoder (
    input wire[31:0] instruction,
    output wire[4:0] opcode,
    output wire[4:0] rd, rs, rt,
    output wire[11:0] literal,
);

    assign opcode = instruction[31:27];
    assign rd = instruction[26:22];
    assign rs = instruction[21:17];
    assign rt = instruction[16:12];
    assign literal = instruction[11:0];
endmodule

module fetcher(
    input clk,
    input reg[63:0] pc,
    output reg[31:0] instruction
);
    memory next_instruction(clk, pc, 0, 0, instruction);
endmodule

module tinker_core(
    input clk,
    input reset
);
    reg[63:0] pc;
    wire[31:0] instruction;

    fetcher fetch(clk, pc, instruction);

    wire[4:0] opcode, rd, rs, rt;
    wire[11:0] literal, rd_increment_amount;
    wire[63:0] rs_val, rt_val;
    wire is_write_reg, is_write_mem, is_rd_increment;
    wire[63:0] write_address_mem;

    decoder decode(instruction, opcode, rd, rs, rt, literal);

    register_file regs(clk, is_write_reg, reset, rd, rs, rt, write_data, is_rd_increment, rd_increment_amount, rs_val, rt_val);
    memory mem(clk, write_address_mem, is_write_mem, write_data, mem_rslt);

    main_logic logic(clk, opcode, rs_val, rt_val, literal, pc, regs.registers[31], return_address, mem_rslt, is_write_reg, is_write_mem, is_rd_increment, read_rslt, rslt_pc, write_data_reg, write_address_mem, write_data_mem, rd_increment_amount);

    always @(posedge clk) begin
        if (reset) begin
            pc <= 64'h2000;
        end else begin
            pc <= pc + 4;
        end
    end

endmodule

