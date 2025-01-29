`include "../../macros.vh"

module ID_reg (
    input  wire        clk,
    input  wire        reset,
    // handshaking signals
    input  wire        ID_busy,
    input  wire        EXE_ready,
    input  wire        IF_to_ID_valid,
    output reg         ID_valid,
    output wire        ID_ready,
    output wire        ID_to_EXE_valid,
    // data signals
    input  wire [31:0] IF_PC,
    input  wire [31:0] IF_inst,
    output reg  [31:0] ID_PC,
    output reg  [31:0] ID_inst
);
    wire ID_done = ~ID_busy;
    assign ID_ready        = ~ID_valid | (ID_done & EXE_ready);
    assign ID_to_EXE_valid = ID_valid & ID_done;

    always @(posedge clk) begin
        if (reset) begin
            ID_valid <= 1'b0;
            ID_PC    <= 32'h0;
            ID_inst  <= 32'h0;
        end else begin
            if (ID_ready) begin
                ID_valid <= IF_to_ID_valid;
            end
            if (IF_to_ID_valid & ID_ready) begin
                ID_PC   <= IF_PC;
                ID_inst <= IF_inst;
            end
        end
    end
endmodule
