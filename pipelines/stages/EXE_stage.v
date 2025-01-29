`include "../../components/ALU.v"

module EXE_stage (
    output wire                        busy,
    input  wire                        valid,
    input  wire [                31:0] ALU_operand1,
    input  wire [                31:0] ALU_operand2,
    input  wire [   `ALU_OP_WIDTH-1:0] ALU_operation,
    input  wire [                31:0] rkd_data,
    input  wire [ `MEM_READ_WIDTH-1:0] MEM_read,
    input  wire [`MEM_WRITE_WIDTH-1:0] MEM_write,
    output wire [                31:0] ALU_result,
    output wire                        MEM_enable,
    output wire [                 3:0] MEM_write_enable,
    output wire [                31:0] MEM_addr,
    output wire [                31:0] MEM_write_data
);
    assign busy = 1'b0;

    ALU alu (
        .operation(ALU_operation),
        .operand1 (ALU_operand1),
        .operand2 (ALU_operand2),
        .result   (ALU_result),
        .MEM_addr (MEM_addr)
    );

    assign MEM_enable       = valid & (|MEM_read | |MEM_write);
    assign MEM_write_enable = {4{valid & |MEM_write}};
    assign MEM_write_data   = rkd_data;
endmodule
