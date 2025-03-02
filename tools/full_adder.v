`include "../macros.vh"

module full_adder #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] addend1,
    input  wire [WIDTH-1:0] addend2,
    input  wire             cin,
    output wire [WIDTH-1:0] sum,
    output wire             cout
);
    assign {cout, sum} = addend1 + addend2 + cin;
endmodule

