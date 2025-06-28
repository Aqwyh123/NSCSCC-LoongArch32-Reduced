`include "macros.h"

module MEM_reg (
    input  wire                            clk,
    input  wire                            reset,
    // control signals
    input  wire                            flush,
    // handshaking signals
    input  wire                            MEM_done,
    input  wire                            WB_ready,
    input  wire                            EXE_to_MEM_valid,
    output reg                             MEM_valid,
    output wire                            MEM_ready,
    output wire                            MEM_to_WB_valid,
    // data signals
    input  wire [                    31:0] EXE_PC,
`ifdef CHIPLAB
    input  wire [                    31:0] EXE_inst,
`endif
    input  wire [                    31:0] EXE_rj_data,
    input  wire [                    31:0] EXE_rkd_data,
`ifdef CHIPLAB
    input  wire [                    31:0] EXE_CSR_read_data,
    input  wire [                    63:0] EXE_CSR_counter,
`endif
    input  wire [                    31:0] EXE_CSR_result,
    input  wire [`ALU_OP_MULH:`ALU_OP_MUL] EXE_ALU_operation,
    input  wire [                    31:0] EXE_ALU_result,
    input  wire [     `MEM_READ_WIDTH-1:0] EXE_MEM_read,
    input  wire [    `MEM_WRITE_WIDTH-1:0] EXE_MEM_write,
    input  wire [      `MEM_BAR_WIDTH-1:0] EXE_MEM_barrier,
`ifdef CHIPLAB
    input  wire [                    31:0] EXE_MEM_paddr,
`endif
    input  wire                            EXE_llbit,
    input  wire                            EXE_GPR_write,
    input  wire [                     4:0] EXE_GPR_write_num,
    input  wire [`GPR_WRITE_SRC_WIDTH-1:0] EXE_GPR_write_src,
    input  wire                            EXE_CSR_write,
    input  wire [   `CSR_NUMBER_WIDTH-1:0] EXE_CSR_write_number,
    input  wire [                    31:0] EXE_CSR_write_data,
    input  wire [       `TLB_OP_WIDTH-1:0] EXE_TLB_operation,
    input  wire                            EXE_ereturn,
    input  wire                            EXE_idle,
    input  wire                            EXE_refetch,
    input  wire [      `GPR_NEW_WIDTH-1:0] EXE_GPR_new,
    input  wire                            EXE_INT,
    input  wire                            EXE_PIL,
    input  wire                            EXE_PIS,
    input  wire                            EXE_PIF,
    input  wire                            EXE_PME,
    input  wire                            EXE_IF_PPI,
    input  wire                            EXE_PPI,
    input  wire                            EXE_ADEF,
    input  wire                            EXE_ALE,
    input  wire                            EXE_SYS,
    input  wire                            EXE_BRK,
    input  wire                            EXE_INE,
    input  wire                            EXE_IPE,
    input  wire                            EXE_IF_TLBR,
    input  wire                            EXE_TLBR,
    output reg  [                    31:0] MEM_PC,
`ifdef CHIPLAB
    output reg  [                    31:0] MEM_inst,
`endif
    output reg  [                    31:0] MEM_rj_data,
    output reg  [                    31:0] MEM_rkd_data,
`ifdef CHIPLAB
    output reg  [                    31:0] MEM_CSR_read_data,
    output reg  [                    63:0] MEM_CSR_counter,
`endif
    output reg  [                    31:0] MEM_CSR_result,
    output reg  [`ALU_OP_MULH:`ALU_OP_MUL] MEM_ALU_operation,
    output reg  [                    31:0] MEM_EXE_ALU_result,
    output reg  [     `MEM_READ_WIDTH-1:0] MEM_MEM_read,
    output reg  [    `MEM_WRITE_WIDTH-1:0] MEM_MEM_write,
    output reg  [      `MEM_BAR_WIDTH-1:0] MEM_MEM_barrier,
`ifdef CHIPLAB
    output reg  [                    31:0] MEM_MEM_paddr,
`endif
    output reg                             MEM_llbit,
    output reg                             MEM_GPR_write,
    output reg  [                     4:0] MEM_GPR_write_num,
    output reg  [`GPR_WRITE_SRC_WIDTH-1:0] MEM_GPR_write_src,
    output reg                             MEM_CSR_write,
    output reg  [   `CSR_NUMBER_WIDTH-1:0] MEM_CSR_write_number,
    output reg  [                    31:0] MEM_CSR_write_data,
    output reg  [       `TLB_OP_WIDTH-1:0] MEM_TLB_operation,
    output reg                             MEM_ereturn,
    output reg                             MEM_idle,
    output reg                             MEM_refetch,
    output reg  [      `GPR_NEW_WIDTH-1:0] MEM_GPR_new,
    output reg                             MEM_INT,
    output reg                             MEM_PIL,
    output reg                             MEM_PIS,
    output reg                             MEM_PIF,
    output reg                             MEM_PME,
    output reg                             MEM_IF_PPI,
    output reg                             MEM_EXE_PPI,
    output reg                             MEM_ADEF,
    output reg                             MEM_ALE,
    output reg                             MEM_SYS,
    output reg                             MEM_BRK,
    output reg                             MEM_INE,
    output reg                             MEM_IPE,
    output reg                             MEM_IF_TLBR,
    output reg                             MEM_EXE_TLBR
);
    assign MEM_ready       = ~MEM_valid | (MEM_done & WB_ready);
    assign MEM_to_WB_valid = MEM_valid & MEM_done;

    always @(posedge clk) begin
        if (reset) begin
            MEM_valid <= 1'b0;
        end else if (flush) begin
            MEM_valid <= 1'b0;
        end else begin
            if (MEM_ready) begin
                MEM_valid <= EXE_to_MEM_valid;
            end
            if (EXE_to_MEM_valid & MEM_ready) begin
                MEM_PC <= EXE_PC;
`ifdef CHIPLAB
                MEM_inst <= EXE_inst;
`endif
                MEM_rj_data  <= EXE_rj_data;
                MEM_rkd_data <= EXE_rkd_data;
`ifdef CHIPLAB
                MEM_CSR_read_data <= EXE_CSR_read_data;
                MEM_CSR_counter   <= EXE_CSR_counter;
`endif
                MEM_CSR_result     <= EXE_CSR_result;
                MEM_ALU_operation  <= EXE_ALU_operation;
                MEM_EXE_ALU_result <= EXE_ALU_result;
                MEM_MEM_read       <= EXE_MEM_read;
                MEM_MEM_write      <= EXE_MEM_write;
                MEM_MEM_barrier    <= EXE_MEM_barrier;
`ifdef CHIPLAB
                MEM_MEM_paddr <= EXE_MEM_paddr;
`endif
                MEM_llbit            <= EXE_llbit;
                MEM_GPR_write        <= EXE_GPR_write;
                MEM_GPR_write_num    <= EXE_GPR_write_num;
                MEM_GPR_write_src    <= EXE_GPR_write_src;
                MEM_CSR_write        <= EXE_CSR_write;
                MEM_CSR_write_number <= EXE_CSR_write_number;
                MEM_CSR_write_data   <= EXE_CSR_write_data;
                MEM_TLB_operation    <= EXE_TLB_operation;
                MEM_ereturn          <= EXE_ereturn;
                MEM_idle             <= EXE_idle;
                MEM_refetch          <= EXE_refetch;
                MEM_GPR_new          <= EXE_GPR_new;
                MEM_INT              <= EXE_INT;
                MEM_PIL              <= EXE_PIL;
                MEM_PIS              <= EXE_PIS;
                MEM_PIF              <= EXE_PIF;
                MEM_PME              <= EXE_PME;
                MEM_IF_PPI           <= EXE_IF_PPI;
                MEM_EXE_PPI          <= EXE_PPI;
                MEM_ADEF             <= EXE_ADEF;
                MEM_ALE              <= EXE_ALE;
                MEM_SYS              <= EXE_SYS;
                MEM_BRK              <= EXE_BRK;
                MEM_INE              <= EXE_INE;
                MEM_IPE              <= EXE_IPE;
                MEM_IF_TLBR          <= EXE_IF_TLBR;
                MEM_EXE_TLBR         <= EXE_TLBR;
            end
        end
    end
endmodule
