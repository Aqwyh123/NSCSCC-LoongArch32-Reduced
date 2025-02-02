`include "../macros.vh"

module right_shifter #(
    parameter integer WIDTH       = 32,
    parameter integer SHAMT_WIDTH = 5
) (
    input  wire [      WIDTH-1:0] operand,
    input  wire [SHAMT_WIDTH-1:0] shamt,
    input  wire                   arithmetic,
    output wire [      WIDTH-1:0] result
);
    wire [WIDTH+(2<<SHAMT_WIDTH)-1:0] temp;
    assign temp   = {{(2 << SHAMT_WIDTH) {operand[WIDTH-1] & arithmetic}}, operand} >> shamt;
    assign result = temp[WIDTH-1:0];
endmodule

