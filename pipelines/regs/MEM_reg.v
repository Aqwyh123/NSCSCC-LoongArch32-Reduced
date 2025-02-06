`include "../../macros.vh"

module MEM_reg (
    input  wire                        clk,
    input  wire                        reset,
    // control signals
    input  wire                        flush,
    // handshaking signals
    input  wire                        MEM_done,
    input  wire                        WB_ready,
    input  wire                        EXE_to_MEM_valid,
    output reg                         MEM_valid,
    output wire                        MEM_ready,
    output wire                        MEM_to_WB_valid,
    // data signals
    input  wire [                31:0] EXE_PC,
    input  wire [                31:0] EXE_rd_data,
    input  wire [                31:0] EXE_ALU_result,
    input  wire [ `MEM_READ_WIDTH-1:0] EXE_MEM_read,
    input  wire [                31:0] EXE_MEM_addr,
    input  wire                        EXE_GPR_write,
    input  wire [                 4:0] EXE_GPR_write_num,
    input  wire [`GPR_WRITE_WIDTH-1:0] EXE_GPR_write_src,
    input  wire [                13:0] EXE_CSR_number,
    input  wire                        EXE_CSR_write,
    input  wire [                31:0] EXE_CSR_write_mask,
    input  wire                        EXE_return,
    input  wire [  `GPR_NEW_WIDTH-1:0] EXE_GPR_new,
    input  wire                        EXE_INT,
    input  wire                        EXE_ADEF,
    input  wire                        EXE_ALE,
    input  wire                        EXE_SYS,
    input  wire                        EXE_BRK,
    input  wire                        EXE_INE,
    output reg  [                31:0] MEM_PC,
    output reg  [                31:0] MEM_rd_data,
    output reg  [                31:0] MEM_ALU_result,
    output reg  [ `MEM_READ_WIDTH-1:0] MEM_MEM_read,
    output reg  [                31:0] MEM_MEM_addr,
    output reg                         MEM_GPR_write,
    output reg  [                 4:0] MEM_GPR_write_num,
    output reg  [`GPR_WRITE_WIDTH-1:0] MEM_GPR_write_src,
    output reg  [                13:0] MEM_CSR_number,
    output reg                         MEM_CSR_write,
    output reg  [                31:0] MEM_CSR_write_mask,
    output reg                         MEM_return,
    output reg  [  `GPR_NEW_WIDTH-1:0] MEM_GPR_new,
    output reg                         MEM_INT,
    output reg                         MEM_ADEF,
    output reg                         MEM_ALE,
    output reg                         MEM_SYS,
    output reg                         MEM_BRK,
    output reg                         MEM_INE
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
                MEM_PC             <= EXE_PC;
                MEM_ALU_result     <= EXE_ALU_result;
                MEM_MEM_read       <= EXE_MEM_read;
                MEM_MEM_addr       <= EXE_MEM_addr;
                MEM_rd_data        <= EXE_rd_data;
                MEM_GPR_write      <= EXE_GPR_write;
                MEM_GPR_write_num  <= EXE_GPR_write_num;
                MEM_GPR_write_src  <= EXE_GPR_write_src;
                MEM_CSR_number     <= EXE_CSR_number;
                MEM_CSR_write      <= EXE_CSR_write;
                MEM_CSR_write_mask <= EXE_CSR_write_mask;
                MEM_return         <= EXE_return;
                MEM_GPR_new        <= EXE_GPR_new;
                MEM_INT            <= EXE_INT;
                MEM_ADEF           <= EXE_ADEF;
                MEM_ALE            <= EXE_ALE;
                MEM_SYS            <= EXE_SYS;
                MEM_BRK            <= EXE_BRK;
                MEM_INE            <= EXE_INE;
            end
        end
    end
endmodule
