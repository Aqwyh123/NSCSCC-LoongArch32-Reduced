`include "../../macros.vh"

module EXE_reg (
    input  wire                        clk,
    input  wire                        reset,
    // handshaking signals
    input  wire                        EXE_busy,
    input  wire                        MEM_ready,
    input  wire                        ID_to_EXE_valid,
    output reg                         EXE_valid,
    output wire                        EXE_ready,
    output wire                        EXE_to_MEM_valid,
    // data signals
    input  wire [                31:0] ID_PC,
    input  wire                        ID_ALU_src1_is_PC,
    input  wire                        ID_ALU_src2_is_imm,
    input  wire [   `ALU_OP_WIDTH-1:0] ID_ALU_operation,
    input  wire [                31:0] ID_imm,
    input  wire [                31:0] ID_rj_data,
    input  wire [                31:0] ID_rkd_data,
    input  wire [ `MEM_READ_WIDTH-1:0] ID_MEM_read,
    input  wire [`MEM_WRITE_WIDTH-1:0] ID_MEM_write,
    input  wire                        ID_GPR_write,
    input  wire [                 4:0] ID_GPR_write_num,
    input  wire                        ID_GPR_write_src_is_MEM,
    output reg  [                31:0] EXE_PC,
    output reg                         EXE_ALU_src1_is_PC,
    output reg                         EXE_ALU_src2_is_imm,
    output reg  [   `ALU_OP_WIDTH-1:0] EXE_ALU_operation,
    output reg  [                31:0] EXE_imm,
    output reg  [                31:0] EXE_rj_data,
    output reg  [                31:0] EXE_rkd_data,
    output reg  [ `MEM_READ_WIDTH-1:0] EXE_MEM_read,
    output reg  [`MEM_WRITE_WIDTH-1:0] EXE_MEM_write,
    output reg                         EXE_GPR_write,
    output reg  [                 4:0] EXE_GPR_write_num,
    output reg                         EXE_GPR_write_src_is_MEM
);
    wire EXE_done = ~EXE_busy;
    assign EXE_ready        = ~EXE_valid | (EXE_done & MEM_ready);
    assign EXE_to_MEM_valid = EXE_valid & EXE_done;

    always @(posedge clk) begin
        if (reset) begin
            EXE_valid                <= 1'b0;
            EXE_PC                   <= 32'h0;
            EXE_ALU_src1_is_PC       <= 1'b0;
            EXE_ALU_src2_is_imm      <= 1'b0;
            EXE_ALU_operation        <= `ALU_OP_WIDTH'b0;
            EXE_imm                  <= 32'b0;
            EXE_rj_data              <= 32'b0;
            EXE_rkd_data             <= 32'b0;
            EXE_MEM_read             <= `MEM_READ_WIDTH'b0;
            EXE_MEM_write            <= `MEM_WRITE_WIDTH'b0;
            EXE_GPR_write            <= 1'b0;
            EXE_GPR_write_num        <= 5'b0;
            EXE_GPR_write_src_is_MEM <= 1'b0;
        end else begin
            if (EXE_ready) begin
                EXE_valid <= ID_to_EXE_valid;
            end
            if (ID_to_EXE_valid & EXE_ready) begin
                EXE_PC                   <= ID_PC;
                EXE_ALU_src1_is_PC       <= ID_ALU_src1_is_PC;
                EXE_ALU_src2_is_imm      <= ID_ALU_src2_is_imm;
                EXE_ALU_operation        <= ID_ALU_operation;
                EXE_imm                  <= ID_imm;
                EXE_rj_data              <= ID_rj_data;
                EXE_rkd_data             <= ID_rkd_data;
                EXE_MEM_read             <= ID_MEM_read;
                EXE_MEM_write            <= ID_MEM_write;
                EXE_GPR_write            <= ID_GPR_write;
                EXE_GPR_write_num        <= ID_GPR_write_num;
                EXE_GPR_write_src_is_MEM <= ID_GPR_write_src_is_MEM;
            end
        end
    end
endmodule
