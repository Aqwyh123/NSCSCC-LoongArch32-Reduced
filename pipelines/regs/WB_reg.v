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
    input  wire [                    31:0] MEM_rd_data,
    input  wire [                    31:0] MEM_CNT_result,
    input  wire [                    31:0] MEM_ALU_result,
    input  wire [                    31:0] MEM_mul_result,
    input  wire [                    31:0] MEM_MEM_result,
    input  wire [                    31:0] MEM_MEM_addr,
    input  wire                            MEM_GPR_write,
    input  wire [                     4:0] MEM_GPR_write_num,
    input  wire [`GPR_WRITE_SRC_WIDTH-1:0] MEM_GPR_write_src,
    input  wire [   `CSR_NUMBER_WIDTH-1:0] MEM_CSR_number,
    input  wire                            MEM_CSR_write,
    input  wire [                    31:0] MEM_CSR_write_mask,
    input  wire                            MEM_return,
    input  wire                            MEM_INT,
    input  wire                            MEM_ADEF,
    input  wire                            MEM_ALE,
    input  wire                            MEM_SYS,
    input  wire                            MEM_BRK,
    input  wire                            MEM_INE,
    output reg  [                    31:0] WB_PC,
    output reg  [                    31:0] WB_rd_data,
    output reg  [                    31:0] WB_CNT_result,
    output reg  [                    31:0] WB_ALU_result,
    output reg  [                    31:0] WB_mul_result,
    output reg  [                    31:0] WB_MEM_result,
    output reg  [                    31:0] WB_MEM_addr,
    output reg                             WB_GPR_write,
    output reg  [                     4:0] WB_GPR_write_num,
    output reg  [`GPR_WRITE_SRC_WIDTH-1:0] WB_GPR_write_src,
    output reg  [   `CSR_NUMBER_WIDTH-1:0] WB_CSR_number,
    output reg                             WB_CSR_write,
    output reg  [                    31:0] WB_CSR_write_mask,
    output reg                             WB_return,
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
                WB_PC             <= MEM_PC;
                WB_rd_data        <= MEM_rd_data;
                WB_CNT_result     <= MEM_CNT_result;
                WB_ALU_result     <= MEM_ALU_result;
                WB_mul_result     <= MEM_mul_result;
                WB_MEM_result     <= MEM_MEM_result;
                WB_MEM_addr       <= MEM_MEM_addr;
                WB_GPR_write      <= MEM_GPR_write;
                WB_GPR_write_src  <= MEM_GPR_write_src;
                WB_GPR_write_num  <= MEM_GPR_write_num;
                WB_CSR_number     <= MEM_CSR_number;
                WB_CSR_write      <= MEM_CSR_write;
                WB_CSR_write_mask <= MEM_CSR_write_mask;
                WB_return         <= MEM_return;
                WB_INT            <= MEM_INT;
                WB_ADEF           <= MEM_ADEF;
                WB_ALE            <= MEM_ALE;
                WB_SYS            <= MEM_SYS;
                WB_BRK            <= MEM_BRK;
                WB_INE            <= MEM_INE;
            end
        end
    end
endmodule
