`include "../macros.vh"

module adder #(
    parameter ADDEND1_WIDTH = 32,
    parameter ADDEND2_WIDTH = 32,
    parameter CARRY         = 0
) (
    input  wire [                                                  ADDEND1_WIDTH-1:0] addend1,
    input  wire [                                                  ADDEND2_WIDTH-1:0] addend2,
    input  wire                                                                       cin,
    output wire [ADDEND1_WIDTH > ADDEND2_WIDTH ? ADDEND1_WIDTH-1 : ADDEND2_WIDTH-1:0] sum,
    output wire                                                                       cout
);
    generate
        if (CARRY == 0) begin : gen_no_carry
            assign sum = addend1 + addend2;
        end else begin : gen_carry
            assign {cout, sum} = addend1 + addend2 + cin;
        end
    endgenerate
endmodule

