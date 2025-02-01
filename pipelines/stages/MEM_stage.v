`include "../../macros.vh"

module MEM_stage (
    output wire                           busy,
    input  wire [`MEM_READ_EXT_WIDTH-1:0] MEM_read_ext,
    input  wire [                    1:0] MEM_addr_low,
    input  wire [                   31:0] MEM_read_data,
    output wire [                   31:0] MEM_result
);
    assign busy       = 1'b0;
    assign MEM_result = MEM_read_data;
endmodule
