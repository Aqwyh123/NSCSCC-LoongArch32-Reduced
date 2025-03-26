`include "../macros.h"

module decoder #(
    parameter WIDTH = 2
) (
    input  wire [     WIDTH-1:0] in,
    output wire [2 ** WIDTH-1:0] out
);
    genvar i;
    generate
        for (i = 0; i < 2 ** WIDTH; i = i + 1) begin : gen_for_dec
            assign out[i] = (in == i);
        end
    endgenerate
endmodule

