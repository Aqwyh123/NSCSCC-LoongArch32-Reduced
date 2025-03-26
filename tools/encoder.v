`include "../macros.vh"

module encoder #(
    parameter WIDTH = 32
) (
    input  wire [        WIDTH-1:0] in,
`ifdef CHIPLAB
    output reg  [$clog2(WIDTH)-1:0] out
`else
    output wor  [$clog2(WIDTH)-1:0] out
`endif
);
`ifdef CHIPLAB
    integer i, j;
    always @(*) begin
        out = {$clog2(WIDTH) {1'b0}};
        for (i = 0; i < WIDTH; i = i + 1) begin
            for (j = 0; j < $clog2(WIDTH); j = j + 1) begin
                if (i[j]) begin
                    out[j] = out[j] | in[i];
                end else begin
                    out[j] = out[j];
                end
            end
        end
    end
`else
    genvar i, j;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_in
            for (j = 0; j < $clog2(WIDTH); j = j + 1) begin : gen_out
                if (i[j]) assign out[j] = in[i];
            end
        end
    endgenerate
`endif
endmodule
