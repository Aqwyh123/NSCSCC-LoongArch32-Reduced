`include "../../macros.vh"

module WB_stage (
    output wire        busy,
    input  wire        valid,
    input  wire        GPR_write_src_is_MEM,
    input  wire        GPR_write,
    input  wire [31:0] ALU_result,
    input  wire [31:0] MEM_read_data,
    output wire        GPR_write_enable,
    output wire [31:0] GPR_write_data
);
    assign busy             = 1'b0;

    assign GPR_write_enable = GPR_write & valid;
    assign GPR_write_data   = GPR_write_src_is_MEM ? MEM_read_data : ALU_result;
endmodule
