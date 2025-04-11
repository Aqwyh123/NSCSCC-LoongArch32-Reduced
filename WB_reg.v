`include "macros.h"

module WB_reg (
    input  wire                            clk,
    input  wire                            reset,
    // control signals
    input  wire                            flush,
    // handshaking signals
    input  wire                            WB_done,
    input  wire                            MEM_to_WB_valid,
    output reg                             WB_valid,
    output wire                            WB_ready,
    // data signals
    input  wire [                    31:0] MEM_PC,
`ifdef CHIPLAB
    input  wire [                    31:0] MEM_inst,
`endif
    input  wire [                    31:0] MEM_rj_data,
    input  wire [                    31:0] MEM_rkd_data,
`ifdef CHIPLAB
    input  wire [                    31:0] MEM_CSR_read_data,
    input  wire [                    63:0] MEM_CSR_counter,
`endif
    input  wire [                    31:0] MEM_CSR_result,
    input  wire [                    31:0] MEM_ALU_result,
`ifdef CHIPLAB
    input  wire [     `MEM_READ_WIDTH-1:0] MEM_MEM_read,
    input  wire [    `MEM_WRITE_WIDTH-1:0] MEM_MEM_write,
    input  wire [                    31:0] MEM_MEM_paddr,
`endif
    input  wire [                    31:0] MEM_MEM_result,
    input  wire                            MEM_GPR_write,
    input  wire [                     4:0] MEM_GPR_write_num,
    input  wire [`GPR_WRITE_SRC_WIDTH-1:0] MEM_GPR_write_src,
    input  wire                            MEM_CSR_write,
    input  wire [   `CSR_NUMBER_WIDTH-1:0] MEM_CSR_write_number,
    input  wire [                    31:0] MEM_CSR_write_data,
    input  wire [       `TLB_OP_WIDTH-1:0] MEM_TLB_operation,
    input  wire                            MEM_refetch,
    input  wire                            MEM_ereturn,
    input  wire                            MEM_INT,
    input  wire                            MEM_PIL,
    input  wire                            MEM_PIS,
    input  wire                            MEM_PIF,
    input  wire                            MEM_PME,
    input  wire                            MEM_IF_PPI,
    input  wire                            MEM_EXE_PPI,
    input  wire                            MEM_ADEF,
    input  wire                            MEM_ALE,
    input  wire                            MEM_SYS,
    input  wire                            MEM_BRK,
    input  wire                            MEM_INE,
    input  wire                            MEM_IF_TLBR,
    input  wire                            MEM_EXE_TLBR,
    output reg  [                    31:0] WB_PC,
`ifdef CHIPLAB
    output reg  [                    31:0] WB_inst,
`endif
    output reg  [                    31:0] WB_rj_data,
    output reg  [                    31:0] WB_rkd_data,
`ifdef CHIPLAB
    output reg  [                    31:0] WB_CSR_read_data,
    output reg  [                    63:0] WB_CSR_counter,
`endif
    output reg  [                    31:0] WB_CSR_result,
    output reg  [                    31:0] WB_ALU_result,
`ifdef CHIPLAB
    output reg  [     `MEM_READ_WIDTH-1:0] WB_MEM_read,
    output reg  [    `MEM_WRITE_WIDTH-1:0] WB_MEM_write,
    output reg  [                    31:0] WB_MEM_paddr,
`endif
    output reg  [                    31:0] WB_MEM_result,
    output reg                             WB_GPR_write,
    output reg  [                     4:0] WB_GPR_write_num,
    output reg  [`GPR_WRITE_SRC_WIDTH-1:0] WB_GPR_write_src,
    output reg                             WB_CSR_write,
    output reg  [   `CSR_NUMBER_WIDTH-1:0] WB_CSR_write_number,
    output reg  [                    31:0] WB_CSR_write_data,
    output reg  [       `TLB_OP_WIDTH-1:0] WB_TLB_operation,
    output reg                             WB_ereturn,
    output reg                             WB_refetch,
    output reg                             WB_INT,
    output reg                             WB_PIL,
    output reg                             WB_PIS,
    output reg                             WB_PIF,
    output reg                             WB_PME,
    output reg                             WB_IF_PPI,
    output reg                             WB_EXE_PPI,
    output reg                             WB_ADEF,
    output reg                             WB_ALE,
    output reg                             WB_SYS,
    output reg                             WB_BRK,
    output reg                             WB_INE,
    output reg                             WB_IF_TLBR,
    output reg                             WB_EXE_TLBR
);
    assign WB_ready = ~WB_valid | (WB_done & 1'b1);

    always @(posedge clk) begin
        if (reset) begin
            WB_valid <= 1'b0;
        end else if (flush) begin
            WB_valid <= 1'b0;
        end else begin
            if (WB_ready) begin
                WB_valid <= MEM_to_WB_valid;
            end
            if (MEM_to_WB_valid & WB_ready) begin
                WB_PC <= MEM_PC;
`ifdef CHIPLAB
                WB_inst <= MEM_inst;
`endif
                WB_rj_data  <= MEM_rj_data;
                WB_rkd_data <= MEM_rkd_data;
`ifdef CHIPLAB
                WB_CSR_read_data <= MEM_CSR_read_data;
                WB_CSR_counter   <= MEM_CSR_counter;
`endif
                WB_CSR_result <= MEM_CSR_result;
                WB_ALU_result <= MEM_ALU_result;
`ifdef CHIPLAB
                WB_MEM_read  <= MEM_MEM_read;
                WB_MEM_write <= MEM_MEM_write;
                WB_MEM_paddr <= MEM_MEM_paddr;
`endif
                WB_MEM_result       <= MEM_MEM_result;
                WB_GPR_write        <= MEM_GPR_write;
                WB_GPR_write_src    <= MEM_GPR_write_src;
                WB_GPR_write_num    <= MEM_GPR_write_num;
                WB_CSR_write_number <= MEM_CSR_write_number;
                WB_CSR_write        <= MEM_CSR_write;
                WB_CSR_write_data   <= MEM_CSR_write_data;
                WB_TLB_operation    <= MEM_TLB_operation;
                WB_ereturn          <= MEM_ereturn;
                WB_refetch          <= MEM_refetch;
                WB_INT              <= MEM_INT;
                WB_PIL              <= MEM_PIL;
                WB_PIS              <= MEM_PIS;
                WB_PIF              <= MEM_PIF;
                WB_PME              <= MEM_PME;
                WB_IF_PPI           <= MEM_IF_PPI;
                WB_EXE_PPI          <= MEM_EXE_PPI;
                WB_ADEF             <= MEM_ADEF;
                WB_ALE              <= MEM_ALE;
                WB_SYS              <= MEM_SYS;
                WB_BRK              <= MEM_BRK;
                WB_INE              <= MEM_INE;
                WB_IF_TLBR          <= MEM_IF_TLBR;
                WB_EXE_TLBR         <= MEM_EXE_TLBR;
            end
        end
    end
endmodule
