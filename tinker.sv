`include "hdl/main_logic.sv"
`include "hdl/memory.sv"

module decoder (
    input wire[31:0] instruction,
    output wire[4:0] opcode, rd, rs, rt,
    output wire[11:0] literal
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
    wire[63:0] rd_val, rs_val, rt_val, r31_val, return_address, read_data_mem;

    wire is_write_mem, is_write_reg;
    wire[63:0] write_data_mem, write_data_reg, read_rslt, rslt_pc, write_address_mem;

    decoder dec(
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .rs(rs),
        .rt(rt),
        .literal(literal)
    );

    memory memory(
        .clk(clk),
        .address(write_address_mem),
        .pc(pc),
        .is_write(is_write_mem),
        .write_data(write_data_mem),

        .read_data(read_data_mem),
        .instruction(instruction)
    );

    register_file reg_file(
        .clk(clk),
        .is_write(is_write_reg),
        .reset(reset),
        .write_reg(rd),
        .read_reg1(rd),
        .read_reg2(rs),
        .read_reg3(rt),
        .write_data(write_data_reg),

        .read_data1(rd_val),
        .read_data2(rs_val),
        .read_data3(rt_val),
        .r31_val(r31_val)
    );

    main_logic logic_unit(
        .opcode(opcode),
        .rd_val(rd_val),
        .rs_val(rs_val),
        .rt_val(rt_val),
        .literal(literal),
        .pc(pc),
        .r31_val(r31_val),
        .load_data(read_data_mem),

        .is_write_reg(is_write_reg),
        .is_write_mem(is_write_mem),
        .rslt_pc(rslt_pc),
        .write_data_reg(write_data_reg),
        .write_address_mem(write_address_mem),
        .write_data_mem(write_data_mem)
    );
    
    always @(posedge clk) begin
        if (reset) begin
            pc <= 64'h2000;
        end else begin
            pc <= rslt_pc;
        end
    end

endmodule