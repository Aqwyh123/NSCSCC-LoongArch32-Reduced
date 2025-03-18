`include "../../macros.vh"

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
    input  wire [                    31:0] MEM_rj_data,
    input  wire [                    31:0] MEM_rkd_data,
    input  wire [                    31:0] MEM_ALU_result,
    input  wire [                    31:0] MEM_MEM_result,
    input  wire [                    31:0] MEM_CSR_result,
    input  wire                            MEM_GPR_write,
    input  wire [                     4:0] MEM_GPR_write_num,
    input  wire [`GPR_WRITE_SRC_WIDTH-1:0] MEM_GPR_write_src,
    input  wire                            MEM_CSR_write,
    input  wire [   `CSR_NUMBER_WIDTH-1:0] MEM_CSR_write_number,
    input  wire [                    31:0] MEM_CSR_write_data,
    input  wire [       `TLB_OP_WIDTH-1:0] MEM_TLB_operation,
    input  wire [                     4:0] MEM_invtlb_op,
    input  wire                            MEM_refetch,
    input  wire                            MEM_ereturn,
    input  wire                            MEM_INT,
    input  wire                            MEM_ADEF,
    input  wire                            MEM_ALE,
    input  wire                            MEM_SYS,
    input  wire                            MEM_BRK,
    input  wire                            MEM_INE,
    output reg  [                    31:0] WB_PC,
    output reg  [                    31:0] WB_rj_data,
    output reg  [                    31:0] WB_rkd_data,
    output reg  [                    31:0] WB_ALU_result,
    output reg  [                    31:0] WB_MEM_result,
    output reg  [                    31:0] WB_CSR_result,
    output reg                             WB_GPR_write,
    output reg  [                     4:0] WB_GPR_write_num,
    output reg  [`GPR_WRITE_SRC_WIDTH-1:0] WB_GPR_write_src,
    output reg                             WB_CSR_write,
    output reg  [   `CSR_NUMBER_WIDTH-1:0] WB_CSR_write_number,
    output reg  [                    31:0] WB_CSR_write_data,
    output reg  [       `TLB_OP_WIDTH-1:0] WB_TLB_operation,
    output reg  [                     4:0] WB_invtlb_op,
    output reg                             WB_ereturn,
    output reg                             WB_refetch,
    output reg                             WB_INT,
    output reg                             WB_ADEF,
    output reg                             WB_ALE,
    output reg                             WB_SYS,
    output reg                             WB_BRK,
    output reg                             WB_INE
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
                WB_PC               <= MEM_PC;
                WB_rj_data          <= MEM_rj_data;
                WB_rkd_data         <= MEM_rkd_data;
                WB_ALU_result       <= MEM_ALU_result;
                WB_MEM_result       <= MEM_MEM_result;
                WB_CSR_result       <= MEM_CSR_result;
                WB_GPR_write        <= MEM_GPR_write;
                WB_GPR_write_src    <= MEM_GPR_write_src;
                WB_GPR_write_num    <= MEM_GPR_write_num;
                WB_CSR_write_number <= MEM_CSR_write_number;
                WB_CSR_write        <= MEM_CSR_write;
                WB_CSR_write_data   <= MEM_CSR_write_data;
                WB_TLB_operation    <= MEM_TLB_operation;
                WB_invtlb_op        <= MEM_invtlb_op;
                WB_ereturn          <= MEM_ereturn;
                WB_refetch          <= MEM_refetch;
                WB_INT              <= MEM_INT;
                WB_ADEF             <= MEM_ADEF;
                WB_ALE              <= MEM_ALE;
                WB_SYS              <= MEM_SYS;
                WB_BRK              <= MEM_BRK;
                WB_INE              <= MEM_INE;
            end
        end
    end
endmodule
