`include "../../macros.vh"

module IF_stage (
    // handshaking signals
    output wire        done,
    // data signals
    input  wire [31:0] PC,
    input  wire        branch_jump,
    input  wire [31:0] target_PC,
    output wire [31:0] next_PC,
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

    assign next_PC = branch_jump ? target_PC : seq_PC;
endmodule
