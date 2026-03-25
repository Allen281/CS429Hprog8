module mov(
    input wire[4:0] opcode,
    input wire[63:0] rd_val,rs_val, rt_val,
    input wire signed[11:0] literal,
    input wire[63:0] load_data,
    
    output reg is_write_mem, is_write_reg, 
    output reg[63:0] write_data_mem, write_data_reg, data_address_mem
);
    always @(*) begin
        is_write_mem = 0;
        is_write_reg = 0;
        write_data_mem = 0;
        write_data_reg = 0;
        data_address_mem = 0;

        case (opcode)
            5'h10: begin
                is_write_reg = 1;
                data_address_mem = rs_val + $signed(literal);
                write_data_reg = load_data;
            end
            5'h11: begin
                is_write_reg = 1;
                write_data_reg = rs_val;
            end
            5'h12: begin
                is_write_reg = 1;
                write_data_reg = {rd_val[63:12], literal};
            end
            5'h13: begin
                is_write_mem = 1;
                data_address_mem = rd_val + $signed(literal);
                write_data_mem = rs_val;
            end
        endcase
    end

endmodule