`include "../../macros.vh"

module WB_reg (
    input  wire        clk,
    input  wire        reset,
    // handshaking signals
    input  wire        WB_busy,
    input  wire        MEM_to_WB_valid,
    output reg         WB_valid,
    output wire        WB_ready,
    // data signals
    input  wire [31:0] MEM_PC,
    input  wire        MEM_GPR_write,
    input  wire [ 4:0] MEM_GPR_write_num,
    input  wire        MEM_GPR_write_src_is_MEM,
    input  wire [31:0] MEM_ALU_result,
    input  wire [31:0] MEM_MEM_read_data,
    output reg  [31:0] WB_PC,
    output reg         WB_GPR_write,
    output reg  [ 4:0] WB_GPR_write_num,
    output reg         WB_GPR_write_src_is_MEM,
    output reg  [31:0] WB_ALU_result,
    output reg  [31:0] WB_MEM_read_data
);
    wire WB_done = ~WB_busy;
    assign WB_ready = ~WB_valid | (WB_done & 1'b1);

    always @(posedge clk) begin
        if (reset) begin
            WB_valid                <= 1'b0;
            WB_PC                   <= 32'h0;
            WB_GPR_write            <= 1'b0;
            WB_GPR_write_num        <= 5'b0;
            WB_GPR_write_src_is_MEM <= 1'b0;
            WB_ALU_result           <= 32'b0;
            WB_MEM_read_data        <= 32'b0;
        end else begin
            if (WB_ready) begin
                WB_valid <= MEM_to_WB_valid;
            end
            if (MEM_to_WB_valid & WB_ready) begin
                WB_PC                   <= MEM_PC;
                WB_GPR_write            <= MEM_GPR_write;
                WB_GPR_write_num        <= MEM_GPR_write_num;
                WB_GPR_write_src_is_MEM <= MEM_GPR_write_src_is_MEM;
                WB_ALU_result           <= MEM_ALU_result;
                WB_MEM_read_data        <= MEM_MEM_read_data;
            end
        end
    end
endmodule
