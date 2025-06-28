`include "macros.h"

module WB_stage (
    // handshaking signals
    input  wire                                 valid,
    output wire                                 done,
    // exception signals
    input  wire [         `EXCEPTION_WIDTH-1:0] exception,
    // data signals
    input  wire [                         31:0] CSR_result,
    input  wire [                         31:0] ALU_result,
    input  wire                                 llbit,
    input  wire [                         31:0] MEM_result,
    input  wire [          `MEM_READ_WIDTH-1:0] MEM_read,
    input  wire [         `MEM_WRITE_WIDTH-1:0] MEM_write,
    input  wire                                 GPR_write,
    input  wire [     `GPR_WRITE_SRC_WIDTH-1:0] GPR_write_src,
    input  wire                                 CSR_write,
    input  wire [            `TLB_OP_WIDTH-1:0] TLB_operation,
    output wire                                 llbit_write_enable,
    output wire                                 llbit_write_data,
    output wire                                 GPR_write_enable,
    output wire [                         31:0] GPR_write_data,
    output wire                                 CSR_write_enable,
    output wire [    `TLB_OP_READ:`TLB_OP_SRCH] CSR_TLB_operation,
    output wire [`TLB_OP_WIDTH-1:`TLB_OP_WRITE] TLB_TLB_operation
);
    assign done = 1'b1;

    assign llbit_write_enable = valid & ~|exception &
                               (MEM_read[`MEM_READ_LINK] | MEM_write[`MEM_WRITE_COND] & llbit);

    assign llbit_write_data = MEM_read[`MEM_READ_LINK] & ~(MEM_write[`MEM_WRITE_COND] & llbit);

    assign GPR_write_enable = valid & ~|exception & GPR_write;

    assign GPR_write_data = {32{GPR_write_src[`GPR_WRITE_SRC_CSR]}} & CSR_result |
                            {32{GPR_write_src[`GPR_WRITE_SRC_ALU]}} & ALU_result |
                            {32{GPR_write_src[`GPR_WRITE_SRC_COND]}} & {31'b0, llbit} |
                            {32{GPR_write_src[`GPR_WRITE_SRC_MEM]}} & MEM_result;

    assign CSR_write_enable = valid & ~|exception & CSR_write &
                             ~TLB_operation[`TLB_OP_SRCH] & ~MEM_read[`MEM_READ_LINK];

    assign CSR_TLB_operation = {(`TLB_OP_READ-`TLB_OP_SRCH+1){valid & ~|exception}} &
                               TLB_operation[`TLB_OP_READ:`TLB_OP_SRCH];
    assign TLB_TLB_operation[`TLB_OP_INV] = {`TLB_INVOP_WIDTH{valid & ~|exception}} &
                                            TLB_operation[`TLB_OP_INV];
    assign TLB_TLB_operation[`TLB_OP_FILL:`TLB_OP_WRITE] =
                            {(`TLB_OP_FILL-`TLB_OP_WRITE+1){valid & ~|exception}} &
                            TLB_operation[`TLB_OP_FILL:`TLB_OP_WRITE];
endmodule
