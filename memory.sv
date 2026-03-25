module memory(
    input wire clk,
    input wire[63:0] address, pc,
    input wire is_write,
    input wire[63:0] write_data,

    output wire[63:0] read_data,
    output wire[31:0] instruction
);
    localparam MEM_SIZE = 512*1024;
    reg[7:0] bytes [0:MEM_SIZE-1];

    assign instruction = {bytes[pc+3], bytes[pc+2], bytes[pc+1], bytes[pc]};

    integer i;
    always @(posedge clk) begin
        if (is_write) begin
            for(i = 0; i < 8; i = i+1) begin
                bytes[address+i] <= write_data[i*8 +: 8];
            end
        end
    end

    assign read_data = is_write ? 64'b0 : {
        bytes[address+7], bytes[address+6], bytes[address+5], bytes[address+4],
        bytes[address+3], bytes[address+2], bytes[address+1], bytes[address]
    };
endmodule

module register_file (
    input wire clk,
    input wire is_write,
    input wire reset,
    input wire[4:0] write_reg, read_reg1, read_reg2, read_reg3,
    input wire[63:0] write_data,
    
    output wire[63:0] read_data1, read_data2, read_data3,
    output wire[63:0] r31_val
);
    localparam MEM_SIZE = 512*1024;
    reg[63:0] registers[0:31];

    always @(posedge clk) begin
        if (reset) begin
            for (integer i = 0; i < 31; i = i + 1) begin
                registers[i] <= 64'b0;
            end
            registers[31] <= MEM_SIZE;
        end else if (is_write) begin
            registers[write_reg] <= write_data;
        end
    end

    assign read_data1 = registers[read_reg1];
    assign read_data2 = registers[read_reg2];
    assign read_data3 = registers[read_reg3];
    assign r31_val = registers[31];
endmodule