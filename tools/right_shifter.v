`include "../macros.h"

module right_shifter #(
    parameter WIDTH = 32
) (
    input  wire [        WIDTH-1:0] operand,
    input  wire [$clog2(WIDTH)-1:0] shamt,
    input  wire                     arithmetic,
    output wire [        WIDTH-1:0] result
);
    wire [WIDTH+(2<<$clog2(WIDTH))-1:0] temp;
    assign temp   = {{(2 << $clog2(WIDTH)) {operand[WIDTH-1] & arithmetic}}, operand} >> shamt;
    assign result = temp[WIDTH-1:0];
endmodule

