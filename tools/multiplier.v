`include "../macros.vh"

module multiplier (
    input  wire        mul_signed,
    input  wire [31:0] operand1,
    input  wire [31:0] operand2,
    output wire [63:0] result
);
    wire [65:0] temp;
    assign temp = $signed(
        {mul_signed & operand1[31], operand1}
    ) * $signed(
        {mul_signed & operand2[31], operand2}
    );
    assign result = temp[63:0];
endmodule

