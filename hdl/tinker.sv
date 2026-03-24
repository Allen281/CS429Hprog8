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

module tinker_core(
    input clk,
    input reset
);
    reg[63:0] pc;

    wire[31:0] instruction;
    wire[4:0] opcode, rd, rs, rt;
    wire[11:0] literal;
    wire[63:0] rs_val, rt_val, alu_rslt, fpu_rslt, mem_rslt, write_data;
    wire is_write;

    decoder decode(instruction, opcode, rd, rs, rt, literal);
    register_file regs(clk, is_write, reset, rd, rs, rt, write_data, rs_val, rt_val);

    alu int_arith(opcode, rd_val, rs_val, rt_val, literal, alu_rslt);
    fpu float_arith(opcode, rd_val, rs_val, rt_val, literal, fpu_rslt);
    memory mem(clk, address, is_write, write_data, mem_rslt);

    always @(posedge clk) begin
        if (reset) begin
            pc <= 64'h2000;
        end else begin
            pc <= pc + 4;
        end
    end

    assign write_data = (opcode == 5'h14 || opcode == 5'h15 || opcode == 5'h16 || opcode == 5'h17) ? fpu_rslt : alu_rslt;
    assign is_write = opcode == 5'h13;

endmodule

