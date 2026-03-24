module mov(
    input clk,
    input wire[4:0] opcode,
    input wire[63:0] rd, rs, rt,
    input wire signed[11:0] literal,
    
    output wire is_write_mem, is_write_reg,
    output reg[63:0] read_rslt, write_data_mem, write_address_mem, write_data_reg
);
    reg[63:0] load;
    memory ld(clk, rs + $signed(literal), 0, 0, load);

    always @(*) begin
        case (opcode)
            5'h10:
                is_write_reg = 1;
                write_data_reg = load;
            5'h11:
                is_write_reg = 1;
                write_data_reg = rs;
            5'h12:
                is_write_mem = 1;
                write_address_mem = {r[63:12], literal};
            5'h13:
                is_write_mem = 1;
                write_address_mem = rd + $signed(literal);
                write_data_mem = rs;
        endcase
    end

endmodule