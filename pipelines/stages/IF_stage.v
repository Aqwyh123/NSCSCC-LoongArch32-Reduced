`include "../../tools/adder.v"

module IF_stage (
    output wire        busy,
    input  wire [31:0] PC,
    output wire [31:0] seq_PC
);
    assign busy = 1'b0;

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
