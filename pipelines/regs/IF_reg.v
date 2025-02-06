`include "../../macros.vh"

module IF_reg (
    input  wire        clk,
    input  wire        reset,
    // control signals
    input  wire        enter,
    input  wire        __return,
    input  wire [31:0] entry,
    input  wire [31:0] raddr,
    input  wire        cancel,
    // handshaking signals
    input  wire        IF_done,
    input  wire        ID_ready,
    input  wire        pre_IF_to_IF_valid,
    output reg         IF_valid,
    output wire        IF_ready,
    output wire        IF_to_ID_valid,
    // data signals
    input  wire [31:0] pre_IF_PC,
    input  wire        pre_IF_ADEF,
    output reg  [31:0] IF_PC,
    output reg         IF_ADEF
);
    assign IF_ready       = ~IF_valid | (IF_done & ID_ready);
    assign IF_to_ID_valid = IF_valid & IF_done;

    always @(posedge clk) begin
        if (reset) begin
            IF_valid <= 1'b0;
            IF_PC    <= `PC_INIT - 32'h4;  // trick: to make next PC be 0x1c000000 during reset
        end else if (enter) begin
            IF_valid <= 1'b0;
            IF_PC    <= entry - 32'h4;
        end else if (__return) begin
            IF_valid <= 1'b0;
            IF_PC    <= raddr - 32'h4;
        end else begin
            if (IF_ready) begin
                IF_valid <= pre_IF_to_IF_valid;
            end else if (cancel) begin
                IF_valid <= 1'b0;
            end
            if (pre_IF_to_IF_valid & IF_ready) begin
                IF_PC   <= pre_IF_PC;
                IF_ADEF <= pre_IF_ADEF;
            end
        end
    end
endmodule
