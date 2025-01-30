`include "../../macros.vh"


module MEM_reg (
    input  wire                       clk,
    input  wire                       reset,
    // handshaking signals
    input  wire                       MEM_busy,
    input  wire                       WB_ready,
    input  wire                       EXE_to_MEM_valid,
    output reg                        MEM_valid,
    output wire                       MEM_ready,
    output wire                       MEM_to_WB_valid,
    // data signals
    input  wire [               31:0] EXE_PC,
    input  wire [`MEM_READ_WIDTH-1:0] EXE_MEM_read,
    input  wire [               31:0] EXE_MEM_addr,
    input  wire                       EXE_GPR_write,
    input  wire [                4:0] EXE_GPR_write_num,
    input  wire                       EXE_GPR_write_src_is_MEM,
    input  wire [               31:0] EXE_ALU_result,
    output reg  [               31:0] MEM_PC,
    output reg  [`MEM_READ_WIDTH-1:0] MEM_MEM_read,
    output reg  [               31:0] MEM_MEM_addr,
    output reg                        MEM_GPR_write,
    output reg  [                4:0] MEM_GPR_write_num,
    output reg                        MEM_GPR_write_src_is_MEM,
    output reg  [               31:0] MEM_ALU_result
);
    assign MEM_ready       = ~MEM_valid | (~MEM_busy & WB_ready);
    assign MEM_to_WB_valid = MEM_valid & ~MEM_busy;

    always @(posedge clk) begin
        if (reset) begin
            MEM_valid                <= 1'b0;
            MEM_PC                   <= 32'h0;
            MEM_MEM_read             <= `MEM_READ_WIDTH'b0;
            MEM_MEM_addr             <= 32'h0;
            MEM_GPR_write            <= 1'b0;
            MEM_GPR_write_num        <= 5'b0;
            MEM_GPR_write_src_is_MEM <= 1'b0;
            MEM_ALU_result           <= 32'b0;
        end else begin
            if (MEM_ready) begin
                MEM_valid <= EXE_to_MEM_valid;
            end
            if (EXE_to_MEM_valid & MEM_ready) begin
                MEM_PC                   <= EXE_PC;
                MEM_MEM_read             <= EXE_MEM_read;
                MEM_MEM_addr             <= EXE_MEM_addr;
                MEM_GPR_write            <= EXE_GPR_write;
                MEM_GPR_write_num        <= EXE_GPR_write_num;
                MEM_GPR_write_src_is_MEM <= EXE_GPR_write_src_is_MEM;
                MEM_ALU_result           <= EXE_ALU_result;
            end
        end
    end
endmodule
