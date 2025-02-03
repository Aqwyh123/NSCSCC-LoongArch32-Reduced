`include "../../macros.vh"

module MEM_stage (
    output wire                           done,
    input  wire [                   31:0] ALU_result,
    input  wire [`MEM_READ_EXT_WIDTH-1:0] MEM_read_ext,
    input  wire [                    1:0] MEM_addr_low,
    input  wire [                   31:0] MEM_read_data,
    input  wire                           GPR_write_src_is_MEM,
    output wire [                   31:0] GPR_write_data
);
    assign done = 1'b1;

    wire [3:0] MEM_byte_enable;
    decoder #(
        .IN_WIDTH (2),
        .OUT_WIDTH(4)
    ) decoder_2_4 (
        .in (MEM_addr_low),
        .out(MEM_byte_enable)
    );

    wire [31:0] MEM_byte_result = {32{MEM_byte_enable[0]}} &
                                  {{24{MEM_read_data[7]}}, MEM_read_data[7:0]} |
                                  {32{MEM_byte_enable[1]}} &
                                  {{24{MEM_read_data[15]}}, MEM_read_data[15:8]} |
                                  {32{MEM_byte_enable[2]}} &
                                  {{24{MEM_read_data[23]}}, MEM_read_data[23:16]} |
                                  {32{MEM_byte_enable[3]}} &
                                  {{24{MEM_read_data[31]}}, MEM_read_data[31:24]};
    wire [31:0] MEM_half_result = MEM_addr_low[1] ?
                                  {{16{MEM_read_data[31]}}, MEM_read_data[31:16]} :
                                  {{16{MEM_read_data[15]}}, MEM_read_data[15:0]};
    wire [31:0] MEM_byteu_result = {32{MEM_byte_enable[0]}} &
                                   {24'b0, MEM_read_data[7:0]} |
                                   {32{MEM_byte_enable[1]}} &
                                   {24'b0, MEM_read_data[15:8]} |
                                   {32{MEM_byte_enable[2]}} &
                                   {24'b0, MEM_read_data[23:16]} |
                                   {32{MEM_byte_enable[3]}} &
                                   {24'b0, MEM_read_data[31:24]};
    wire [31:0] MEM_halfu_result = MEM_addr_low[1] ?
                                   {16'b0, MEM_read_data[31:16]} :
                                   {16'b0, MEM_read_data[15:0]};
    wire [31:0] MEM_result = {32{MEM_read_ext[`MEM_READ_EXT_BYTE]}} & MEM_byte_result |
                             {32{MEM_read_ext[`MEM_READ_EXT_HALF]}} & MEM_half_result |
                             {32{MEM_read_ext[`MEM_READ_EXT_WORD]}} & MEM_read_data |
                             {32{MEM_read_ext[`MEM_READ_EXT_BYTEU]}} & MEM_byteu_result |
                             {32{MEM_read_ext[`MEM_READ_EXT_HALFU]}} & MEM_halfu_result;

    assign GPR_write_data = GPR_write_src_is_MEM ? MEM_result : ALU_result;
endmodule
