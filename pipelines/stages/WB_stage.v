`include "../../macros.vh"

module WB_stage (
    // handshaking signals
    input  wire                        valid,
    output wire                        done,
    // exception signals
    input  wire [`EXCEPTION_WIDTH-1:0] exception,
    // data signals
    input  wire [                31:0] ALU_result,
    input  wire [                31:0] MEM_result,
    input  wire [                31:0] CSR_read_data,
    input  wire                        GPR_write,
    input  wire [`GPR_WRITE_WIDTH-1:0] GPR_write_src,
    input  wire                        CSR_write,
    output wire                        GPR_write_enable,
    output wire [                31:0] GPR_write_data,
    output wire                        CSR_write_enable
);
    assign done = 1'b1;

    assign GPR_write_enable = valid & ~|exception & GPR_write;

    assign GPR_write_data = {32{GPR_write_src[`GPR_WRITE_ALU]}} & ALU_result |
                            {32{GPR_write_src[`GPR_WRITE_MEM]}} & MEM_result |
                            {32{GPR_write_src[`GPR_WRITE_CSR]}} & CSR_read_data;

    assign CSR_write_enable = valid & ~|exception & CSR_write;
endmodule
