module memory(
    input wire clk,
    input wire[63:0] address,
    input wire[63:0] r31_val,

    input wire is_write,
    input wire[63:0] write_data,

    output reg[63:0] read_data,
    output wire[32:0] instruction,
    output wire[63:0] return_address
);
    localparam MEM_SIZE = 512*1024;
    reg[7:0] bytes [0:MEM_SIZE-1];

    assign instruction = {bytes[address], bytes[address+1], bytes[address+2], bytes[address+3]};
    assign return_address = r31_val - 8;

    integer i;
    always @(posedge clk) begin
        if (is_write) begin
            for(i = 0; i < 8; i = i+1) begin
                bytes[address+i] <= write_data[i*8 +: 8];
            end
        end
    end

    always @(*) begin
        read_data = 64'b0;
        if(!is_write) begin
            for(i = 0; i < 8; i = i+1) begin
                read_data[i*8 +: 8] = bytes[address+i];
            end
        end
    end
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
            for (int i = 0; i < 31; i = i + 1) begin
                registers[i] <= 64'b0;
            end
            registers[31] <= MEM_SIZE;
        end else if (is_write) begin
            if(is_rd_increment_literal) begin
                registers[write_reg] <= registers[write_reg] + literal;
            end else if(is_rd_modify_literal) begin
                registers[write_reg] <= {registers[write_reg][63:12], literal};
            end else begin
                registers[write_reg] <= write_data;
            end
        end
    end

    assign read_data1 = registers[read_reg1];
    assign read_data2 = registers[read_reg2];
    assign read_data3 = registers[read_reg3];
    assign r31_val = registers[31];
endmodule