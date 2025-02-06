`include "../../macros.vh"

module MEM_stage (
    // handshaking signals
    output wire                       done,
    // data signals
    input  wire [`MEM_READ_WIDTH-1:0] MEM_read,
    input  wire [                1:0] MEM_addr_low,
    input  wire [               31:0] MEM_read_data,
    output wire [               31:0] MEM_result
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
    assign MEM_result = {32{MEM_read[`MEM_READ_BYTE]}} & MEM_byte_result |
                        {32{MEM_read[`MEM_READ_HALF]}} & MEM_half_result |
                        {32{MEM_read[`MEM_READ_WORD]}} & MEM_read_data |
                        {32{MEM_read[`MEM_READ_BYTEU]}} & MEM_byteu_result |
                        {32{MEM_read[`MEM_READ_HALFU]}} & MEM_halfu_result;
endmodule
