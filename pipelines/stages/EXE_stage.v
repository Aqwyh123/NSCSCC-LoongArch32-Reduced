`include "../../macros.vh"

module EXE_stage (
    input  wire                        clk,
    input  wire                        reset,
    // handshaking signals
    input  wire                        valid,
    input  wire                        MEM_ready,
    output wire                        done,
    // control signals
    input  wire                        MEM_valid,
    input  wire                        WB_valid,
    input  wire [`EXCEPTION_WIDTH-1:0] exception,
    input  wire [`EXCEPTION_WIDTH-1:0] MEM_exception,
    input  wire [`EXCEPTION_WIDTH-1:0] WB_exception,
    // SRAM-like Bus
    output wire                        data_sram_req,
    output wire                        data_sram_wr,
    output wire [                 1:0] data_sram_size,
    output wire [                31:0] data_sram_addr,
    output wire [                 3:0] data_sram_wstrb,
    output wire [                31:0] data_sram_wdata,
    input  wire                        data_sram_addr_ok,
    // data signals
    input  wire [                31:0] PC,
    input  wire [                31:0] imm,
    input  wire [                31:0] rj_data,
    input  wire [                31:0] rkd_data,
    input  wire                        ALU_src1_is_PC,
    input  wire                        ALU_src2_is_imm,
    input  wire [   `ALU_OP_WIDTH-1:0] ALU_operation,
    input  wire [ `MEM_READ_WIDTH-1:0] MEM_read,
    input  wire [`MEM_WRITE_WIDTH-1:0] MEM_write,
    output wire [                31:0] ALU_result,
    output wire [                31:0] MEM_addr,
    output wire                        ALE
);
    wire [31:0] ALU_operand1 = ALU_src1_is_PC ? PC : rj_data;
    wire [31:0] ALU_operand2 = ALU_src2_is_imm ? imm : rkd_data;
    wire        ALU_done;
    wire        MEM_done;

    assign done = |exception ? 1'b1 : |MEM_read | |MEM_write ? MEM_done : ALU_done;

    ALU alu (
        .clk      (clk),
        .reset    (reset),
        .valid    (valid),
        .operation(ALU_operation),
        .operand1 (ALU_operand1),
        .operand2 (ALU_operand2),
        .result   (ALU_result),
        .done     (ALU_done),
        .MEM_addr (MEM_addr)
    );

    wire [3:0] MEM_addr_d;
    decoder #(
        .IN_WIDTH (2),
        .OUT_WIDTH(4)
    ) decoder_2_4 (
        .in (MEM_addr[1:0]),
        .out(MEM_addr_d)
    );

    assign data_sram_req = valid & MEM_ready & ~|exception & ~(MEM_valid & |MEM_exception) &
                           ~(WB_valid & |WB_exception) & (|MEM_read | |MEM_write);
    assign data_sram_wr = |MEM_write;

    assign data_sram_size = {2{MEM_read[`MEM_READ_BYTE] | MEM_read[`MEM_READ_BYTEU] |
                            MEM_write[`MEM_WRITE_BYTE]}} & 2'b00 |
                            {2{MEM_read[`MEM_READ_HALF] | MEM_read[`MEM_READ_HALFU] |
                            MEM_write[`MEM_WRITE_HALF]}} & 2'b01 |
                            {2{MEM_read[`MEM_READ_WORD] | MEM_write[`MEM_WRITE_WORD]}} & 2'b10;

    assign data_sram_addr = MEM_addr;

    assign data_sram_wstrb = {4{MEM_write[`MEM_WRITE_BYTE]}} & MEM_addr_d |
                             {4{MEM_write[`MEM_WRITE_HALF]}} &
                             {{2{MEM_addr[1]}},{2{~MEM_addr[1]}}} |
                             {4{MEM_write[`MEM_WRITE_WORD]}};

    assign data_sram_wdata   = {32{MEM_write[`MEM_WRITE_BYTE]}} & {4{rkd_data[7:0]}} |
                               {32{MEM_write[`MEM_WRITE_HALF]}} & {2{rkd_data[15:0]}} |
                               {32{MEM_write[`MEM_WRITE_WORD]}} & rkd_data;

    assign MEM_done = data_sram_req & data_sram_addr_ok;

    assign ALE = (MEM_read[`MEM_READ_HALF] | MEM_read[`MEM_READ_HALFU] |
                  MEM_write[`MEM_WRITE_HALF]) & MEM_addr[0] |
                 (MEM_read[`MEM_READ_WORD] | MEM_write[`MEM_WRITE_WORD]) & |MEM_addr[1:0];
endmodule
