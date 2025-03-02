`include "../../macros.vh"

module EXE_reg (
    input  wire                            clk,
    input  wire                            reset,
    // control signals
    input  wire                            flush,
    // handshaking signals
    input  wire                            EXE_done,
    input  wire                            MEM_ready,
    input  wire                            ID_to_EXE_valid,
    output reg                             EXE_valid,
    output wire                            EXE_ready,
    output wire                            EXE_to_MEM_valid,
    // data signals
    input  wire [                    31:0] ID_PC,
    input  wire [                    31:0] ID_link,
    input  wire [                    31:0] ID_imm,
    input  wire [                    31:0] ID_rj_data,
    input  wire [                    31:0] ID_rkd_data,
    input  wire [                    31:0] ID_CNT_result,
    input  wire                            ID_ALU_src1_is_PC,
    input  wire                            ID_ALU_src2_is_imm,
    input  wire [       `ALU_OP_WIDTH-1:0] ID_ALU_operation,
    input  wire                            ID_mul_div_unsigned,
    input  wire [     `MEM_READ_WIDTH-1:0] ID_MEM_read,
    input  wire [    `MEM_WRITE_WIDTH-1:0] ID_MEM_write,
    input  wire                            ID_GPR_write,
    input  wire [                     4:0] ID_GPR_write_num,
    input  wire [`GPR_WRITE_SRC_WIDTH-1:0] ID_GPR_write_src,
    input  wire [   `CSR_NUMBER_WIDTH-1:0] ID_CSR_number,
    input  wire                            ID_CSR_write,
    input  wire [                    31:0] ID_CSR_write_mask,
    input  wire                            ID_return,
    input  wire [      `GPR_NEW_WIDTH-1:0] ID_GPR_new,
    input  wire                            ID_INT,
    input  wire                            ID_ADEF,
    input  wire                            ID_SYS,
    input  wire                            ID_BRK,
    input  wire                            ID_INE,
    output reg  [                    31:0] EXE_PC,
    output reg  [                    31:0] EXE_link,
    output reg  [                    31:0] EXE_imm,
    output reg  [                    31:0] EXE_rj_data,
    output reg  [                    31:0] EXE_rkd_data,
    output reg  [                    31:0] EXE_CNT_result,
    output reg                             EXE_ALU_src1_is_PC,
    output reg                             EXE_ALU_src2_is_imm,
    output reg  [       `ALU_OP_WIDTH-1:0] EXE_ALU_operation,
    output reg                             EXE_mul_div_unsigned,
    output reg  [     `MEM_READ_WIDTH-1:0] EXE_MEM_read,
    output reg  [    `MEM_WRITE_WIDTH-1:0] EXE_MEM_write,
    output reg                             EXE_GPR_write,
    output reg  [                     4:0] EXE_GPR_write_num,
    output reg  [`GPR_WRITE_SRC_WIDTH-1:0] EXE_GPR_write_src,
    output reg  [   `CSR_NUMBER_WIDTH-1:0] EXE_CSR_number,
    output reg                             EXE_CSR_write,
    output reg  [                    31:0] EXE_CSR_write_mask,
    output reg                             EXE_return,
    output reg  [      `GPR_NEW_WIDTH-1:0] EXE_GPR_new,
    output reg                             EXE_INT,
    output reg                             EXE_ADEF,
    output reg                             EXE_SYS,
    output reg                             EXE_BRK,
    output reg                             EXE_INE
);
    assign EXE_ready        = ~EXE_valid | (EXE_done & MEM_ready);
    assign EXE_to_MEM_valid = EXE_valid & EXE_done;

    always @(posedge clk) begin
        if (reset) begin
            EXE_valid <= 1'b0;
        end else if (flush) begin
            EXE_valid <= 1'b0;
        end else begin
            if (EXE_ready) begin
                EXE_valid <= ID_to_EXE_valid;
            end
            if (ID_to_EXE_valid & EXE_ready) begin
                EXE_PC               <= ID_PC;
                EXE_link             <= ID_link;
                EXE_imm              <= ID_imm;
                EXE_rj_data          <= ID_rj_data;
                EXE_rkd_data         <= ID_rkd_data;
                EXE_CNT_result       <= ID_CNT_result;
                EXE_ALU_src1_is_PC   <= ID_ALU_src1_is_PC;
                EXE_ALU_src2_is_imm  <= ID_ALU_src2_is_imm;
                EXE_ALU_operation    <= ID_ALU_operation;
                EXE_mul_div_unsigned <= ID_mul_div_unsigned;
                EXE_MEM_read         <= ID_MEM_read;
                EXE_MEM_write        <= ID_MEM_write;
                EXE_GPR_write        <= ID_GPR_write;
                EXE_GPR_write_num    <= ID_GPR_write_num;
                EXE_GPR_write_src    <= ID_GPR_write_src;
                EXE_CSR_number       <= ID_CSR_number;
                EXE_CSR_write        <= ID_CSR_write;
                EXE_CSR_write_mask   <= ID_CSR_write_mask;
                EXE_return           <= ID_return;
                EXE_GPR_new          <= ID_GPR_new;
                EXE_INT              <= ID_INT;
                EXE_ADEF             <= ID_ADEF;
                EXE_SYS              <= ID_SYS;
                EXE_BRK              <= ID_BRK;
                EXE_INE              <= ID_INE;
            end
        end
    end
endmodule
