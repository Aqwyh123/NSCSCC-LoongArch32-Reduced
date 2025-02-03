`include "../../macros.vh"

module EXE_stage (
    input  wire                            clk,
    input  wire                            reset,
    input  wire                            valid,
    output wire                            done,
    input  wire [                    31:0] PC,
    input  wire [                    31:0] imm,
    input  wire [                    31:0] rj_data,
    input  wire [                    31:0] rkd_data,
    input  wire                            ALU_src1_is_PC,
    input  wire                            ALU_src2_is_imm,
    input  wire [       `ALU_OP_WIDTH-1:0] ALU_operation,
    input  wire [`MEM_WRITE_EXT_WIDTH-1:0] MEM_write_ext,
    output wire [                    31:0] ALU_result,
    output wire [                     3:0] MEM_write_enable,
    output wire [                    31:0] MEM_addr,
    output wire [                    31:0] MEM_write_data
);
    wire [31:0] ALU_operand1 = ALU_src1_is_PC ? PC : rj_data;
    wire [31:0] ALU_operand2 = ALU_src2_is_imm ? imm : rkd_data;

    ALU alu (
        .clk      (clk),
        .reset    (reset),
        .valid    (valid),
        .operation(ALU_operation),
        .operand1 (ALU_operand1),
        .operand2 (ALU_operand2),
        .result   (ALU_result),
        .done     (done),
        .MEM_addr (MEM_addr)
    );

    wire [3:0] MEM_byte_enable;
    decoder #(
        .IN_WIDTH (2),
        .OUT_WIDTH(4)
    ) decoder_2_4 (
        .in (MEM_addr[1:0]),
        .out(MEM_byte_enable)
    );

    assign MEM_write_enable = {4{MEM_write_ext[`MEM_WRITE_EXT_BYTE]}} & MEM_byte_enable |
                              {4{MEM_write_ext[`MEM_WRITE_EXT_HALF]}} &
                              {{2{MEM_addr[1]}},{2{~MEM_addr[1]}}} |
                              {4{MEM_write_ext[`MEM_WRITE_EXT_WORD]}};
    assign MEM_write_data   = {32{MEM_write_ext[`MEM_WRITE_EXT_BYTE]}} & {4{rkd_data[7:0]}} |
                              {32{MEM_write_ext[`MEM_WRITE_EXT_HALF]}} & {2{rkd_data[15:0]}} |
                              {32{MEM_write_ext[`MEM_WRITE_EXT_WORD]}} & rkd_data;
endmodule
