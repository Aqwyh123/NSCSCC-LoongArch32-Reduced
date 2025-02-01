`include "../../macros.vh"

module WB_reg (
    input  wire                        clk,
    input  wire                        reset,
    // handshaking signals
    input  wire                        WB_busy,
    input  wire                        MEM_to_WB_valid,
    output reg                         WB_valid,
    output wire                        WB_ready,
    // data signals
    input  wire [                31:0] MEM_PC,
    input  wire [                31:0] MEM_MEM_read_data,
    input  wire [`GPR_WRITE_WIDTH-1:0] MEM_GPR_write,
    input  wire [                 4:0] MEM_GPR_write_num,
    input  wire [                31:0] MEM_GPR_write_data,
    output reg  [                31:0] WB_PC,
    output reg  [                31:0] WB_MEM_read_data,
    output reg  [`GPR_WRITE_WIDTH-1:0] WB_GPR_write,
    output reg  [                 4:0] WB_GPR_write_num,
    output reg  [                31:0] WB_MEM_GPR_write_data
);
    assign WB_ready = ~WB_valid | (~WB_busy & 1'b1);

    always @(posedge clk) begin
        if (reset) begin
            WB_valid              <= 1'b0;
            WB_PC                 <= 32'h0;
            WB_MEM_read_data      <= 32'h0;
            WB_GPR_write          <= `GPR_WRITE_WIDTH'b0;
            WB_GPR_write_num      <= 5'b0;
            WB_MEM_GPR_write_data <= 32'h0;
        end else begin
            if (WB_ready) begin
                WB_valid <= MEM_to_WB_valid;
            end
            if (MEM_to_WB_valid & WB_ready) begin
                WB_PC                 <= MEM_PC;
                WB_MEM_read_data      <= MEM_MEM_read_data;
                WB_GPR_write          <= MEM_GPR_write;
                WB_GPR_write_num      <= MEM_GPR_write_num;
                WB_MEM_GPR_write_data <= MEM_GPR_write_data;
            end
        end
    end
endmodule
