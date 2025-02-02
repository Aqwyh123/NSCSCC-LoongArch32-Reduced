`include "../../macros.vh"

module IF_reg (
    input  wire        clk,
    input  wire        reset,
    // handshaking signals
    input  wire        IF_done,
    input  wire        ID_ready,
    output reg         IF_valid,
    output wire        IF_ready,
    output wire        IF_to_ID_valid,
    // control signals
    input  wire        ID_bj_enable,
    // data signals
    input  wire [31:0] IF_next_PC,
    output reg  [31:0] IF_PC
);
    assign IF_ready       = ~IF_valid | (IF_done & ID_ready);
    assign IF_to_ID_valid = IF_valid & IF_done;

    always @(posedge clk) begin
        if (reset) begin
            IF_valid <= 1'b0;
            IF_PC    <= `PC_INIT - 32'h4;  // trick: to make next PC be 0x1c000000 during reset
        end else begin
            if (IF_ready) begin
                IF_valid <= 1'b1;
            end else if (ID_bj_enable) begin
                IF_valid <= 1'b0;
            end
            if (IF_ready) begin
                IF_PC <= IF_next_PC;
            end
        end
    end
endmodule
