`include "../../macros.vh"

module EXE_reg (
    input  wire                            clk,
    input  wire                            reset,
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
    input  wire [                     4:0] ID_GPR_read_num1,
    input  wire [                     4:0] ID_GPR_read_num2,
    input  wire [                    31:0] ID_GPR_read_data1,
    input  wire [                    31:0] ID_GPR_read_data2,
    input  wire                            ID_ALU_src1_is_PC,
    input  wire                            ID_ALU_src2_is_imm,
    input  wire [       `ALU_OP_WIDTH-1:0] ID_ALU_operation,
    input  wire                            ID_MEM_read,
    input  wire [ `MEM_READ_EXT_WIDTH-1:0] ID_MEM_read_ext,
    input  wire                            ID_MEM_write,
    input  wire [`MEM_WRITE_EXT_WIDTH-1:0] ID_MEM_write_ext,
    input  wire                            ID_GPR_write,
    input  wire [                     4:0] ID_GPR_write_num,
    input  wire                            ID_GPR_write_src_is_MEM,
    input  wire [      `GPR_NEW_WIDTH-1:0] ID_GPR_new,
    output reg  [                    31:0] EXE_PC,
    output reg  [                    31:0] EXE_link,
    output reg  [                    31:0] EXE_imm,
    output reg  [                     4:0] EXE_GPR_read_num1,
    output reg  [                     4:0] EXE_GPR_read_num2,
    output reg  [                    31:0] EXE_GPR_read_data1,
    output reg  [                    31:0] EXE_GPR_read_data2,
    output reg                             EXE_ALU_src1_is_PC,
    output reg                             EXE_ALU_src2_is_imm,
    output reg  [       `ALU_OP_WIDTH-1:0] EXE_ALU_operation,
    output reg                             EXE_MEM_read,
    output reg  [ `MEM_READ_EXT_WIDTH-1:0] EXE_MEM_read_ext,
    output reg                             EXE_MEM_write,
    output reg  [`MEM_WRITE_EXT_WIDTH-1:0] EXE_MEM_write_ext,
    output reg                             EXE_GPR_write,
    output reg  [                     4:0] EXE_GPR_write_num,
    output reg                             EXE_GPR_write_src_is_MEM,
    output reg  [      `GPR_NEW_WIDTH-1:0] EXE_GPR_new
);
    assign EXE_ready        = ~EXE_valid | (EXE_done & MEM_ready);
    assign EXE_to_MEM_valid = EXE_valid & EXE_done;

    always @(posedge clk) begin
        if (reset) begin
            EXE_valid                <= 1'b0;
            EXE_PC                   <= 32'h0;
            EXE_link                 <= 32'h0;
            EXE_imm                  <= 32'h0;
            EXE_GPR_read_num1        <= 5'b0;
            EXE_GPR_read_num2        <= 5'b0;
            EXE_GPR_read_data1       <= 32'h0;
            EXE_GPR_read_data2       <= 32'h0;
            EXE_ALU_src1_is_PC       <= 1'b0;
            EXE_ALU_src2_is_imm      <= 1'b0;
            EXE_ALU_operation        <= `ALU_OP_WIDTH'b0;
            EXE_MEM_read             <= 1'b0;
            EXE_MEM_read_ext         <= `MEM_READ_EXT_WIDTH'b0;
            EXE_MEM_write            <= 1'b0;
            EXE_MEM_write_ext        <= `MEM_WRITE_EXT_WIDTH'b0;
            EXE_GPR_write            <= 1'b0;
            EXE_GPR_write_num        <= 5'b0;
            EXE_GPR_write_src_is_MEM <= 1'b0;
            EXE_GPR_new              <= `GPR_NEW_WIDTH'b0;
        end else begin
            if (EXE_ready) begin
                EXE_valid <= ID_to_EXE_valid;
            end
            if (ID_to_EXE_valid & EXE_ready) begin
                EXE_PC                   <= ID_PC;
                EXE_link                 <= ID_link;
                EXE_imm                  <= ID_imm;
                EXE_GPR_read_num1        <= ID_GPR_read_num1;
                EXE_GPR_read_num2        <= ID_GPR_read_num2;
                EXE_GPR_read_data1       <= ID_GPR_read_data1;
                EXE_GPR_read_data2       <= ID_GPR_read_data2;
                EXE_ALU_src1_is_PC       <= ID_ALU_src1_is_PC;
                EXE_ALU_src2_is_imm      <= ID_ALU_src2_is_imm;
                EXE_ALU_operation        <= ID_ALU_operation;
                EXE_MEM_read             <= ID_MEM_read;
                EXE_MEM_read_ext         <= ID_MEM_read_ext;
                EXE_MEM_write            <= ID_MEM_write;
                EXE_MEM_write_ext        <= ID_MEM_write_ext;
                EXE_GPR_write            <= ID_GPR_write;
                EXE_GPR_write_num        <= ID_GPR_write_num;
                EXE_GPR_write_src_is_MEM <= ID_GPR_write_src_is_MEM;
                EXE_GPR_new              <= ID_GPR_new;
            end
        end
    end
endmodule
