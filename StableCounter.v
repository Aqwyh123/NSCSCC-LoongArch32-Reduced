`include "macros.h"

module StableCounter (
    input  wire        clk,
    input  wire        reset,
    output reg  [63:0] data
);
    always @(posedge clk) begin
        if (reset) begin
            data <= 64'b0;
        end else begin
            data <= data + 1'b1;
        end
    end
endmodule
