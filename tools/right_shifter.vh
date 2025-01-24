`ifndef RIGHT_SHIFTER_V
`define RIGHT_SHIFTER_V
`include "../macros.vh"

module right_shifter #(
    parameter integer WIDTH       = 32,
    parameter integer SHAMT_WIDTH = 5
) (
    input  wire [      WIDTH-1:0] operand,
    input  wire [SHAMT_WIDTH-1:0] shamt,
    input  wire                   arith,
    output wire [      WIDTH-1:0] result
);
    wire [WIDTH+(2<<SHAMT_WIDTH)-1:0] temp;
    assign temp   = {{(2 << SHAMT_WIDTH) {operand[WIDTH-1] & arith}}, operand} >> shamt;
    assign result = temp[WIDTH-1:0];
endmodule

`endif
