`include "../macros.vh"

module encoder #(
    parameter WIDTH = 32
) (
    input  wire [        WIDTH-1:0] in,
    output wor  [$clog2(WIDTH)-1:0] out
);
    genvar i, j;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_in
            for (j = 0; j < $clog2(WIDTH); j = j + 1) begin : gen_out
                if (i[j]) assign out[j] = in[i];
            end
        end
    endgenerate
endmodule
