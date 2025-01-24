`ifndef DECODER_V
`define DECODER_V
`include "../macros.vh"

module decoder #(
    parameter integer IN_WIDTH  = 2,
    parameter integer OUT_WIDTH = 4
) (
    input  wire [ IN_WIDTH-1:0] in,
    output wire [OUT_WIDTH-1:0] out
);

    genvar i;
    generate
        for (i = 0; i < 2 ** IN_WIDTH; i = i + 1) begin : gen_for_dec
            assign out[i] = (in == i);
        end
    endgenerate

endmodule

`endif
