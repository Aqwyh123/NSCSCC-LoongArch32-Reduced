`include "../../macros.vh"

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
    input  wire [                     1:0] EXE_ALU_operation_mul,
    input  wire [                    31:0] EXE_ALU_result,
    input  wire [     `MEM_READ_WIDTH-1:0] EXE_MEM_read,
    input  wire [    `MEM_WRITE_WIDTH-1:0] EXE_MEM_write,
    input  wire                            EXE_GPR_write,
    input  wire [                     4:0] EXE_GPR_write_num,
    input  wire [`GPR_WRITE_SRC_WIDTH-1:0] EXE_GPR_write_src,
    input  wire [                    31:0] EXE_CSR_result,
    input  wire                            EXE_CSR_write,
    input  wire [   `CSR_NUMBER_WIDTH-1:0] EXE_CSR_write_number,
    input  wire [                    31:0] EXE_CSR_write_data,
    input  wire                            EXE_ereturn,
    input  wire [      `GPR_NEW_WIDTH-1:0] EXE_GPR_new,
    input  wire                            EXE_INT,
    input  wire                            EXE_ADEF,
    input  wire                            EXE_ALE,
    input  wire                            EXE_SYS,
    input  wire                            EXE_BRK,
    input  wire                            EXE_INE,
    output reg  [                    31:0] MEM_PC,
    output reg  [                     1:0] MEM_ALU_operation_mul,
    output reg  [                    31:0] MEM_EXE_ALU_result,
    output reg  [     `MEM_READ_WIDTH-1:0] MEM_MEM_read,
    output reg  [    `MEM_WRITE_WIDTH-1:0] MEM_MEM_write,
    output reg                             MEM_GPR_write,
    output reg  [                     4:0] MEM_GPR_write_num,
    output reg  [`GPR_WRITE_SRC_WIDTH-1:0] MEM_GPR_write_src,
    output reg  [                    31:0] MEM_CSR_result,
    output reg                             MEM_CSR_write,
    output reg  [   `CSR_NUMBER_WIDTH-1:0] MEM_CSR_write_number,
    output reg  [                    31:0] MEM_CSR_write_data,
    output reg                             MEM_ereturn,
    output reg  [      `GPR_NEW_WIDTH-1:0] MEM_GPR_new,
    output reg                             MEM_INT,
    output reg                             MEM_ADEF,
    output reg                             MEM_ALE,
    output reg                             MEM_SYS,
    output reg                             MEM_BRK,
    output reg                             MEM_INE
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
                MEM_PC                <= EXE_PC;
                MEM_ALU_operation_mul <= EXE_ALU_operation_mul;
                MEM_EXE_ALU_result    <= EXE_ALU_result;
                MEM_MEM_read          <= EXE_MEM_read;
                MEM_MEM_write         <= EXE_MEM_write;
                MEM_GPR_write         <= EXE_GPR_write;
                MEM_GPR_write_num     <= EXE_GPR_write_num;
                MEM_GPR_write_src     <= EXE_GPR_write_src;
                MEM_CSR_result        <= EXE_CSR_result;
                MEM_CSR_write         <= EXE_CSR_write;
                MEM_CSR_write_number  <= EXE_CSR_write_number;
                MEM_CSR_write_data    <= EXE_CSR_write_data;
                MEM_ereturn           <= EXE_ereturn;
                MEM_GPR_new           <= EXE_GPR_new;
                MEM_INT               <= EXE_INT;
                MEM_ADEF              <= EXE_ADEF;
                MEM_ALE               <= EXE_ALE;
                MEM_SYS               <= EXE_SYS;
                MEM_BRK               <= EXE_BRK;
                MEM_INE               <= EXE_INE;
            end
        end
    end
endmodule
