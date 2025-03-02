`include "../../macros.vh"

module MEM_stage (
    // handshaking signals
    output wire                        done,
    // control signals
    input  wire [`EXCEPTION_WIDTH-1:0] exception,
    // SRAM-like Bus
    input  wire                        data_sram_data_ok,
    input  wire [                31:0] data_sram_rdata,
    // data signals
    input  wire                        mul_is_low,
    input  wire [                63:0] mul_data,
    output wire [                31:0] mul_result,
    input  wire [ `MEM_READ_WIDTH-1:0] MEM_read,
    input  wire [`MEM_WRITE_WIDTH-1:0] MEM_write,
    input  wire [                 1:0] MEM_addr_1_0,
    output wire [                31:0] MEM_result
);
    assign done       = ~|exception & (|MEM_read | |MEM_write) ? data_sram_data_ok : 1'b1;

    assign mul_result = mul_is_low ? mul_data[31:0] : mul_data[63:32];

    wire [3:0] MEM_byte_enable;
    decoder #(
        .IN_WIDTH (2),
        .OUT_WIDTH(4)
    ) decoder_2_4 (
        .in (MEM_addr_1_0),
        .out(MEM_byte_enable)
    );

    wire [31:0] MEM_byte_result = {32{MEM_byte_enable[0]}} &
                                  {{24{data_sram_rdata[7]}}, data_sram_rdata[7:0]} |
                                  {32{MEM_byte_enable[1]}} &
                                  {{24{data_sram_rdata[15]}}, data_sram_rdata[15:8]} |
                                  {32{MEM_byte_enable[2]}} &
                                  {{24{data_sram_rdata[23]}}, data_sram_rdata[23:16]} |
                                  {32{MEM_byte_enable[3]}} &
                                  {{24{data_sram_rdata[31]}}, data_sram_rdata[31:24]};
    wire [31:0] MEM_half_result = MEM_addr_1_0[1] ?
                                  {{16{data_sram_rdata[31]}}, data_sram_rdata[31:16]} :
                                  {{16{data_sram_rdata[15]}}, data_sram_rdata[15:0]};
    wire [31:0] MEM_byteu_result = {32{MEM_byte_enable[0]}} &
                                   {24'b0, data_sram_rdata[7:0]} |
                                   {32{MEM_byte_enable[1]}} &
                                   {24'b0, data_sram_rdata[15:8]} |
                                   {32{MEM_byte_enable[2]}} &
                                   {24'b0, data_sram_rdata[23:16]} |
                                   {32{MEM_byte_enable[3]}} &
                                   {24'b0, data_sram_rdata[31:24]};
    wire [31:0] MEM_halfu_result = MEM_addr_1_0[1] ?
                                   {16'b0, data_sram_rdata[31:16]} :
                                   {16'b0, data_sram_rdata[15:0]};
    assign MEM_result = {32{MEM_read[`MEM_READ_BYTE]}} & MEM_byte_result |
                        {32{MEM_read[`MEM_READ_HALF]}} & MEM_half_result |
                        {32{MEM_read[`MEM_READ_WORD]}} & data_sram_rdata |
                        {32{MEM_read[`MEM_READ_BYTEU]}} & MEM_byteu_result |
                        {32{MEM_read[`MEM_READ_HALFU]}} & MEM_halfu_result;
endmodule
