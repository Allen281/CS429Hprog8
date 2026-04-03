`timescale 1ns/1ps

module testbench();

    reg clk;
    reg reset;

    always #5 clk = ~clk;

    reg [4:0] opcode;
    reg [63:0] rd_val, rs_val, rt_val;
    reg signed [11:0] literal;
    reg [63:0] pc, r31_val, load_data;

    wire [63:0] alu_rslt;
    alu dut_alu (
        .opcode(opcode),
        .input1(rs_val),
        .input2(rt_val),
        .rslt(alu_rslt)
    );

    wire branch_is_write;
    wire [63:0] branch_new_pc, branch_write_address, branch_write_data;
    branch dut_branch (
        .opcode(opcode),
        .rd_val(rd_val), .rs_val(rs_val), .rt_val(rt_val),
        .literal(literal), .pc(pc), .r31_val(r31_val), .load_data(load_data),
        .is_write(branch_is_write),
        .new_pc(branch_new_pc),
        .write_address(branch_write_address),
        .write_data(branch_write_data)
    );

    wire mov_is_write_mem, mov_is_write_reg;
    wire [63:0] mov_write_data_mem, mov_write_data_reg, mov_data_address_mem;
    mov dut_mov (
        .opcode(opcode),
        .rd_val(rd_val), .rs_val(rs_val), .rt_val(rt_val),
        .literal(literal), .load_data(load_data),
        .is_write_mem(mov_is_write_mem), .is_write_reg(mov_is_write_reg),
        .write_data_mem(mov_write_data_mem), .write_data_reg(mov_write_data_reg),
        .data_address_mem(mov_data_address_mem)
    );

    wire [63:0] fpu_rslt;
    fpu dut_fpu (
        .opcode(opcode),
        .rs_val(rs_val), .rt_val(rt_val),
        .rslt(fpu_rslt)
    );

    wire main_is_write_reg, main_is_write_mem;
    wire [63:0] main_rslt_pc, main_write_data_reg, main_write_address_mem, main_write_data_mem;
    main_logic dut_main_logic (
        .opcode(opcode),
        .rd_val(rd_val), .rs_val(rs_val), .rt_val(rt_val),
        .literal(literal), .pc(pc), .r31_val(r31_val), .load_data(load_data),
        .is_write_reg(main_is_write_reg), .is_write_mem(main_is_write_mem),
        .rslt_pc(main_rslt_pc),
        .write_data_reg(main_write_data_reg),
        .write_address_mem(main_write_address_mem),
        .write_data_mem(main_write_data_mem)
    );

    reg mem_is_write;
    reg [63:0] mem_address, mem_write_data;
    wire [63:0] mem_read_data;
    wire [31:0] mem_instruction;

    memory dut_memory (
        .clk(clk),
        .address(mem_address), .pc(pc),
        .is_write(mem_is_write), .write_data(mem_write_data),
        .read_data(mem_read_data), .instruction(mem_instruction)
    );

    reg reg_is_write;
    reg [4:0] reg_write_reg, reg_read_reg1, reg_read_reg2, reg_read_reg3;
    reg [63:0] reg_write_data;
    wire [63:0] reg_read_data1, reg_read_data2, reg_read_data3, reg_r31_val;

    register_file dut_register_file (
        .clk(clk), .reset(reset), .is_write(reg_is_write),
        .write_reg(reg_write_reg), .read_reg1(reg_read_reg1), 
        .read_reg2(reg_read_reg2), .read_reg3(reg_read_reg3),
        .write_data(reg_write_data),
        .read_data1(reg_read_data1), .read_data2(reg_read_data2), 
        .read_data3(reg_read_data3), .r31_val(reg_r31_val)
    );


    initial begin
        clk = 0;
        reset = 1;
        opcode = 0; rd_val = 0; rs_val = 0; rt_val = 0;
        literal = 0; pc = 0; r31_val = 0; load_data = 0;
        mem_is_write = 0; mem_address = 0; mem_write_data = 0;
        reg_is_write = 0; reg_write_reg = 0; reg_read_reg1 = 0; 
        reg_read_reg2 = 0; reg_read_reg3 = 0; reg_write_data = 0;
        
        #20 reset = 0;

        $display("========================================");
        $display("Starting Unit Tests...");
        $display("========================================");

        // --- 1. ALU Tests ---
        // Test Integer Addition (Opcode 5'h18)
        opcode = 5'h18; rs_val = 64'd150; rt_val = 64'd250;
        #5;
        if (alu_rslt === 64'd400) $display("[PASS] ALU: Integer Addition");
        else $display("[FAIL] ALU: Integer Addition (Expected: %0d, Got: %0d)", 400, alu_rslt);

        // Test Bitwise XOR (Opcode 5'h02)
        opcode = 5'h02; rs_val = 64'hF0F0; rt_val = 64'h0F0F;
        #5;
        if (alu_rslt === 64'hFFFF) $display("[PASS] ALU: Bitwise XOR");
        else $display("[FAIL] ALU: Bitwise XOR");

        // --- 2. Branch Tests ---
        // Test Unconditional Jump (Opcode 5'h08) -> new_pc = rd_val
        opcode = 5'h08; rd_val = 64'h1000; pc = 64'h0000;
        #5;
        if (branch_new_pc === 64'h1000 && !branch_is_write) $display("[PASS] BRANCH: Unconditional Jump to Register");
        else $display("[FAIL] BRANCH: Unconditional Jump");

        // Test Branch with offset (Opcode 5'h0a) -> new_pc = pc + literal
        opcode = 5'h0a; pc = 64'd100; literal = 12'd20;
        #5;
        if (branch_new_pc === 64'd120) $display("[PASS] BRANCH: Jump with PC Offset");
        else $display("[FAIL] BRANCH: Jump with PC Offset (Got: %0d)", branch_new_pc);

        // --- 3. MOV Tests ---
        // Test Register load (Opcode 5'h11) -> is_write_reg = 1, write_data_reg = rs_val
        opcode = 5'h11; rs_val = 64'hDEADBEEF;
        #5;
        if (mov_is_write_reg && mov_write_data_reg === 64'hDEADBEEF) $display("[PASS] MOV: Register Load");
        else $display("[FAIL] MOV: Register Load");

        // --- 4. FPU Tests ---
        // Test Special Case - Double Zero Addition (Opcode 5'h14)
        opcode = 5'h14; 
        rs_val = 64'h0000000000000000;
        rt_val = 64'h0000000000000000;
        #5;
        if (fpu_rslt === 64'h0000000000000000) $display("[PASS] FPU: Double Zero Addition");
        else $display("[FAIL] FPU: Double Zero Addition");
        
        // --- 5. Main Logic Tests ---
        // Ensure Main Logic routes ALU properly (using ALU add setup)
        opcode = 5'h18; rs_val = 64'd42; rt_val = 64'd42; // Addition
        #5;
        if (main_is_write_reg && main_write_data_reg === 64'd84) $display("[PASS] MAIN LOGIC: Routes ALU Operations correctly");
        else $display("[FAIL] MAIN LOGIC: ALU Routing");

        // --- 6. Memory Tests ---
        // Test Memory Write and Read
        mem_address = 64'h0000_0010;
        mem_write_data = 64'h1122334455667788;
        mem_is_write = 1;
        #10;
        mem_is_write = 0;
        #10;
        if (mem_read_data === 64'h1122334455667788) $display("[PASS] MEMORY: Read/Write validation");
        else $display("[FAIL] MEMORY: Read/Write validation (Expected: 1122334455667788, Got: %h)", mem_read_data);

        // --- 7. Register File Tests ---
        // Test Reset Value of r31
        if (reg_r31_val === (512*1024)) $display("[PASS] REGFILE: r31 reset validation");
        else $display("[FAIL] REGFILE: r31 reset (Got: %0d)", reg_r31_val);

        // Test Register Write/Read
        reg_write_reg = 5'd10;
        reg_write_data = 64'hABCD_EF01;
        reg_is_write = 1;
        #10;
        reg_is_write = 0;
        reg_read_reg1 = 5'd10;
        #10;
        if (reg_read_data1 === 64'hABCD_EF01) $display("[PASS] REGFILE: Register Write/Read validation");
        else $display("[FAIL] REGFILE: Register Write/Read");

        $display("========================================");
        $display("Tests Completed.");
        $display("========================================");
        $finish;
    end

endmodule