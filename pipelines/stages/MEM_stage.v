`include "../../macros.vh"

module MEM_stage (
    output wire                        busy,
    input  wire [ `MEM_READ_WIDTH-1:0] MEM_read,
    input  wire [                31:0] MEM_addr,
    input  wire [                31:0] data_sram_rdata,
    output wire [                31:0] MEM_read_data
);
    assign busy           = 1'b0;
    assign MEM_read_data  = data_sram_rdata;
endmodule
