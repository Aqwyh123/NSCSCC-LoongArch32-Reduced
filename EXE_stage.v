`include "macros.h"

module EXE_stage (
    input  wire                           clk,
    input  wire                           reset,
    // handshaking signals
    input  wire                           valid,
    input  wire                           MEM_ready,
    output wire                           done,
    // control signals
    input  wire [   `EXCEPTION_WIDTH-1:0] exception,
    // ICache Bus
    output wire                           inst_req,
    output wire [                    4:0] inst_op,
    output wire [                   31:0] inst_vaddr,
    input  wire                           inst_addr_ok,
    // DCache Bus
    output wire                           data_req,
    output wire [                    4:0] data_op,
    output wire [                    2:0] data_access_size,
    output wire [                   31:0] data_vaddr,
    output wire [                    3:0] data_wstrb,
    output wire [                   31:0] data_wdata,
    input  wire                           data_addr_ok,
    // data signals
    input  wire [                   31:0] PC,
    input  wire [                   31:0] imm,
    input  wire [                   31:0] rj_data,
    input  wire [                   31:0] rkd_data,
    input  wire                           ALU_src1_is_PC,
    input  wire                           ALU_src2_is_imm,
    input  wire [      `ALU_OP_WIDTH-1:0] ALU_operation,
    input  wire                           div_unsigned,
    input  wire [    `MEM_READ_WIDTH-1:0] MEM_read,
    input  wire [   `MEM_WRITE_WIDTH-1:0] MEM_write,
    input  wire [                   31:0] CSR_read_data,
    input  wire                           CSR_write_mask,
    input  wire [`CACHE_TARGET_WIDTH-1:0] cache_target,
    input  wire [    `CACHE_OP_WIDTH-1:0] cache_operation,
    output wire [                   31:0] ALU_result,
    output wire [                   31:0] CSR_write_data,
    output wire                           ALE
);
    wire [31:0] ALU_operand1 = ALU_src1_is_PC ? PC : rj_data;
    wire [31:0] ALU_operand2 = ALU_src2_is_imm ? imm : rkd_data;
    wire        ALU_done;
    wire        DATA_done;
    wire        INST_done;

    assign done = |exception ? 1'b1 :
                  |MEM_read | |MEM_write | cache_target[`CACHE_TARGET_DCACHE] ? DATA_done :
                   cache_target[`CACHE_TARGET_ICACHE] ? INST_done : ALU_done;

    ALU alu (
        .clk         (clk),
        .reset       (reset),
        .valid       (valid),
        .ready       (MEM_ready),
        .operation   (ALU_operation),
        .div_unsigned(div_unsigned),
        .operand1    (ALU_operand1),
        .operand2    (ALU_operand2),
        .result      (ALU_result),
        .done        (ALU_done)
    );

    wire [3:0] MEM_byte_enable;
    decoder #(
        .WIDTH(2)
    ) decoder_2_4 (
        .in (ALU_result[1:0]),
        .out(MEM_byte_enable)
    );

    wire access_byte = MEM_read[`MEM_READ_BYTE] | MEM_read[`MEM_READ_BYTEU] |
                       MEM_write[`MEM_WRITE_BYTE];
    wire access_half = MEM_read[`MEM_READ_HALF] | MEM_read[`MEM_READ_HALFU] |
                       MEM_write[`MEM_WRITE_HALF];
    wire access_word = MEM_read[`MEM_READ_WORD] | MEM_write[`MEM_WRITE_WORD];

    assign data_req = valid & (|MEM_read | |MEM_write | cache_target[`CACHE_TARGET_DCACHE]) &
                    ~|exception & MEM_ready;
    assign data_op[0] = |MEM_read;
    assign data_op[1] = |MEM_write;
    assign data_op[4:2] = cache_operation;
    assign data_access_size = {3{access_byte}} & 3'b000 |
                              {3{access_half}} & 3'b001 |
                              {3{access_word}} & 3'b010;
    assign data_vaddr = ALU_result;
    assign data_wstrb = {4{MEM_write[`MEM_WRITE_BYTE]}} & MEM_byte_enable |
                        {4{MEM_write[`MEM_WRITE_HALF]}} &
                        {{2{ALU_result[1]}},{2{~ALU_result[1]}}} |
                        {4{MEM_write[`MEM_WRITE_WORD]}};
    assign data_wdata = {32{MEM_write[`MEM_WRITE_BYTE]}} & {4{rkd_data[7:0]}} |
                        {32{MEM_write[`MEM_WRITE_HALF]}} & {2{rkd_data[15:0]}} |
                        {32{MEM_write[`MEM_WRITE_WORD]}} & rkd_data;
    assign DATA_done = data_req & data_addr_ok;

    assign inst_req = valid & cache_target[`CACHE_TARGET_ICACHE] & ~|exception & MEM_ready;
    assign inst_op[1:0] = 2'b00;
    assign inst_op[4:2] = cache_operation;
    assign inst_vaddr = ALU_result;
    assign INST_done = inst_req & inst_addr_ok;

    assign CSR_write_data = CSR_write_mask ?
                            rj_data & rkd_data | ~rj_data & CSR_read_data :
                            rkd_data;

    assign ALE = (access_half & data_vaddr[0] | access_word & |data_vaddr[1:0]) &
                 ~cache_operation[`CACHE_OP_HIT_OP];
endmodule
