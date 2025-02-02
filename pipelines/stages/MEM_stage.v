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
    wire [31:0] MEM_result = MEM_read_data;
    assign GPR_write_data = GPR_write_src_is_MEM ? MEM_result : ALU_result;
endmodule
