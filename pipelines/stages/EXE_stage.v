`include "../../components/ALU.v"

module EXE_stage (
    output wire                            busy,
    input  wire [                    31:0] PC,
    input  wire [                    31:0] imm,
    input  wire [                    31:0] rj_data,
    input  wire [                    31:0] rkd_data,
    input  wire                            ALU_src1_is_PC,
    input  wire                            ALU_src2_is_imm,
    input  wire [       `ALU_OP_WIDTH-1:0] ALU_operation,
    input  wire                            MEM_write,
    input  wire [`MEM_WRITE_EXT_WIDTH-1:0] MEM_write_ext,
    output wire [                    31:0] ALU_result,
    output wire [                     3:0] MEM_write_enable,
    output wire [                    31:0] MEM_addr,
    output wire [                    31:0] MEM_write_data
);
    assign busy = 1'b0;

    wire [31:0] ALU_operand1 = ALU_src1_is_PC ? PC : rj_data;
    wire [31:0] ALU_operand2 = ALU_src2_is_imm ? imm : rkd_data;

    ALU alu (
        .operation(ALU_operation),
        .operand1 (ALU_operand1),
        .operand2 (ALU_operand2),
        .result   (ALU_result),
        .MEM_addr (MEM_addr)
    );

    assign MEM_write_enable = {4{MEM_write}};
    assign MEM_write_data   = rkd_data;
endmodule
