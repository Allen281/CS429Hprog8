`timescale 1ns / 1ps

module tb_tinker();
    // 1. Declare signals to connect to the CPU
    reg clk;
    reg reset;

    // 2. Instantiate your CPU core (Device Under Test)
    tinker_core dut (
        .clk(clk),
        .reset(reset)
    );

    // 3. Generate a Clock Signal (toggles every 5 nanoseconds)
    always #5 clk = ~clk;

    // 4. Main Simulation Sequence
    initial begin
        $readmemh("test.hex", dut.memory.bytes, 'h2000); // Load test program into memory

        // Initialize signals
        clk = 0;
        reset = 1;

        // Hold reset for 20ns, then let the CPU start running
        #20;
        reset = 0;
        $display("--- CPU OUT OF RESET ---");

        // Let the CPU run for 1000ns, then stop the simulation
        #1000;
        $display("--- SIMULATION FINISHED ---");
        $finish;
    end

    // 5. Monitor the CPU's behavior every clock cycle
    always @(posedge clk) begin
        if (!reset) begin
            $display("Time: %0t | PC: %h | Inst: %h | r1: %0d | r2: %0d", 
                      $time, dut.pc, dut.instruction, dut.reg_file.registers[1], dut.reg_file.registers[2]);
        end
    end

endmodule