`include "../../macros.vh"

module IF_stage (
    output wire        done,
    input  wire [31:0] PC,
    output wire [31:0] seq_PC
);
    assign done = 1'b1;

    adder #(
        .WIDTH(32)
    ) seq_PC_adder (
        .addend1(PC),
        .addend2(32'h4),
        .cin    (1'b0),
        .sum    (seq_PC),
        .cout   ()
    );
endmodule
