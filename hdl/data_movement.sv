module mov(
    input clk,
    input wire[4:0] opcode,
    input wire[63:0] rs_val, rt_val,
    input wire signed[11:0] literal,
    input wire[63:0] load_data,
    
    output reg is_write_mem, is_write_reg, is_rd_modify_literal,
    output reg[63:0] read_rslt, write_data_mem, write_offset_mem, write_data_reg
);
    always @(*) begin
        case (opcode)
            5'h10:
                is_write_reg = 1;
                write_data_reg = load_data;
            5'h11:
                is_write_reg = 1;
                write_data_reg = rs_val;
            5'h12:
                is_write_reg = 1;
                is_rd_modify_literal = 1;
            5'h13:
                is_write_mem = 1;
                write_offset_mem = $signed(literal);
                write_data_mem = rs_val;
        endcase
    end

endmodule