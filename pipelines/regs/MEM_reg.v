`include "../../macros.vh"

module MEM_reg (
    input  wire                           clk,
    input  wire                           reset,
    // handshaking signals
    input  wire                           MEM_done,
    input  wire                           WB_ready,
    input  wire                           EXE_to_MEM_valid,
    output reg                            MEM_valid,
    output wire                           MEM_ready,
    output wire                           MEM_to_WB_valid,
    // data signals
    input  wire [                   31:0] EXE_PC,
    input  wire [                   31:0] EXE_ALU_result,
    input  wire [`MEM_READ_EXT_WIDTH-1:0] EXE_MEM_read_ext,
    input  wire [                    1:0] EXE_MEM_addr_low,
    input  wire                           EXE_GPR_write,
    input  wire [                    4:0] EXE_GPR_write_num,
    input  wire                           EXE_GPR_write_src_is_MEM,
    input  wire [     `GPR_NEW_WIDTH-1:0] EXE_GPR_new,
    output reg  [                   31:0] MEM_PC,
    output reg  [                   31:0] MEM_ALU_result,
    output reg  [`MEM_READ_EXT_WIDTH-1:0] MEM_MEM_read_ext,
    output reg  [                    1:0] MEM_MEM_addr_low,
    output reg                            MEM_GPR_write,
    output reg  [                    4:0] MEM_GPR_write_num,
    output reg                            MEM_GPR_write_src_is_MEM,
    output reg  [     `GPR_NEW_WIDTH-1:0] MEM_GPR_new
);
    assign MEM_ready       = ~MEM_valid | (MEM_done & WB_ready);
    assign MEM_to_WB_valid = MEM_valid & MEM_done;

    always @(posedge clk) begin
        if (reset) begin
            MEM_valid                <= 1'b0;
            MEM_PC                   <= 32'h0;
            MEM_ALU_result           <= 32'h0;
            MEM_MEM_read_ext         <= `MEM_READ_EXT_WIDTH'b0;
            MEM_MEM_addr_low         <= 2'b0;
            MEM_GPR_write            <= 1'b0;
            MEM_GPR_write_num        <= 5'b0;
            MEM_GPR_write_src_is_MEM <= 1'b0;
            MEM_GPR_new              <= `GPR_NEW_WIDTH'b0;
        end else begin
            if (MEM_ready) begin
                MEM_valid <= EXE_to_MEM_valid;
            end
            if (EXE_to_MEM_valid & MEM_ready) begin
                MEM_PC                   <= EXE_PC;
                MEM_ALU_result           <= EXE_ALU_result;
                MEM_MEM_read_ext         <= EXE_MEM_read_ext;
                MEM_MEM_addr_low         <= EXE_MEM_addr_low;
                MEM_GPR_write            <= EXE_GPR_write;
                MEM_GPR_write_num        <= EXE_GPR_write_num;
                MEM_GPR_write_src_is_MEM <= EXE_GPR_write_src_is_MEM;
                MEM_GPR_new              <= EXE_GPR_new;
            end
        end
    end
endmodule
