`include "macros.h"

module ID_reg (
    input  wire        clk,
    input  wire        reset,
    // control signals
    input  wire        flush,
    // handshaking signals
    input  wire        ID_done,
    input  wire        EXE_ready,
    input  wire        IF_to_ID_valid,
    output reg         ID_valid,
    output wire        ID_ready,
    output wire        ID_to_EXE_valid,
    // data signals
    input  wire [31:0] IF_PC,
    input  wire [31:0] IF_inst,
    input  wire        IF_PIF,
    input  wire        IF_PPI,
    input  wire        IF_ADEF,
    input  wire        IF_TLBR,
    output reg  [31:0] ID_PC,
    output reg  [31:0] ID_inst,
    output reg         ID_PIF,
    output reg         ID_IF_PPI,
    output reg         ID_ADEF,
    output reg         ID_IF_TLBR
);
    assign ID_ready        = ~ID_valid | (ID_done & EXE_ready);
    assign ID_to_EXE_valid = ID_valid & ID_done;

    always @(posedge clk) begin
        if (reset) begin
            ID_valid <= 1'b0;
        end else if (flush) begin
            ID_valid <= 1'b0;
        end else begin
            if (ID_ready) begin
                ID_valid <= IF_to_ID_valid;
            end
            if (IF_to_ID_valid & ID_ready) begin
                ID_PC      <= IF_PC;
                ID_inst    <= IF_inst;
                ID_PIF     <= IF_PIF;
                ID_IF_PPI  <= IF_PPI;
                ID_ADEF    <= IF_ADEF;
                ID_IF_TLBR <= IF_TLBR;
            end
        end
    end
endmodule
