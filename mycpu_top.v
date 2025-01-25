`include "macros.vh"
`include "tools/adder.vh"
`include "tools/decoder.vh"

module mycpu_top (
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_we,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    reg reset;
    always @(posedge clk) reset <= ~resetn;

    reg valid;
    always @(posedge clk) begin
        if (reset) begin
            valid <= 1'b0;
        end else begin
            valid <= 1'b1;
        end
    end

    reg [31:0] PC;
    wire [31:0] seq_PC;
    wire [31:0] target_PC;
    wire [31:0] next_PC;
    wire taken;

    wire [31:0] inst;
    wire [`BRANCH_WIDTH-1:0] branch;
    wire branch_reverse;
    wire jump;
    wire [`IMM_SRC_WIDTH-1:0] imm_src;
    wire [`OFFS_SRC_WIDTH-1:0] offs_src;
    wire ALU_src1_is_PC;
    wire ALU_src2_is_imm;
    wire [`ALU_OP_WIDTH-1:0] ALU_operation;
    wire GPR_read_src2_is_rd;
    wire GPR_write_src_is_MEM;
    wire GPR_write_dst_is_r1;
    wire GPR_write;
    wire MEM_write;

    wire [11:0] i12 = inst[`I12_MSB:`I12_LSB];
    wire [13:0] i14 = inst[`I14_MSB:`I14_LSB];
    wire [19:0] i20 = inst[`I20_MSB:`I20_LSB];
    wire [31:0] imm;

    wire [15:0] o16 = inst[`O16_MSB:`O16_LSB];
    wire [20:0] o21 = {inst[`O21_HIGH_MSB:`O21_HIGH_LSB], inst[`O21_LOW_MSB:`O21_LOW_LSB]};
    wire [25:0] o26 = {inst[`O26_HIGH_MSB:`O26_HIGH_LSB], inst[`O26_LOW_MSB:`O26_LOW_LSB]};
    wire [31:0] offs;

    wire [4:0] rd = inst[`RD_MSB:`RD_LSB];
    wire [4:0] rj = inst[`RJ_MSB:`RJ_LSB];
    wire [4:0] rk = inst[`RK_MSB:`RK_LSB];

    wire [4:0] GPR_read_num1;
    wire [31:0] GPR_read_data1;
    wire [4:0] GPR_read_num2;
    wire [31:0] GPR_read_data2;
    wire GPR_write_enable;
    wire [4:0] GPR_write_num;
    wire [31:0] GPR_write_data;

    wire [31:0] rj_data;
    wire [31:0] rkd_data;

    wire rj_eq_rd;
    // wire                   rj_lt_rd;
    // wire                   rj_ltu_rd;

    wire [31:0] ALU_operand1;
    wire [31:0] ALU_operand2;
    wire [31:0] ALU_result;
    wire [31:0] MEM_addr;

    wire [31:0] MEM_result;

    always @(posedge clk) begin
        if (reset) begin
            PC <= `PC_INIT;
        end else begin
            PC <= next_PC;
        end
    end

    assign inst_sram_we    = 1'b0;
    assign inst_sram_addr  = PC;
    assign inst_sram_wdata = 32'b0;
    assign inst            = inst_sram_rdata;

    ID id (
        .instruction         (inst),
        .branch              (branch),
        .branch_reverse      (branch_reverse),
        .jump                (jump),
        .imm_src             (imm_src),
        .offs_src            (offs_src),
        .ALU_src1_is_PC      (ALU_src1_is_PC),
        .ALU_src2_is_imm     (ALU_src2_is_imm),
        .ALU_operation       (ALU_operation),
        .GPR_read_src2_is_rd (GPR_read_src2_is_rd),
        .GPR_write_src_is_MEM(GPR_write_src_is_MEM),
        .GPR_write_dst_is_r1 (GPR_write_dst_is_r1),
        .MEM_write           (MEM_write),
        .GPR_write           (GPR_write)
    );

    // default : ui12 / ui5
    assign imm = imm_src[`IMM_SRC_4] ? 32'h4 :
                 imm_src[`IMM_SRC_SI12] ? {{20{i12[11]}}, i12} :
                 imm_src[`IMM_SRC_SI14] ? {{18{i14[13]}}, i14} :
                 imm_src[`IMM_SRC_SI20] ? {i20, 12'b0} :
                 {20'b0, i12};

    // default : offs21
    assign offs = offs_src[`OFFS_SRC_16] ? {{14{o16[15]}}, o16, 2'b0} :
                  offs_src[`OFFS_SRC_26] ? {{4{o26[25]}}, o26, 2'b0} :
                  {{9{o21[20]}},o21,2'b0};

    assign GPR_read_num1 = rj;
    assign GPR_read_num2 = GPR_read_src2_is_rd ? rd : rk;
    assign GPR_write_enable = GPR_write & valid;
    assign GPR_write_num = GPR_write_dst_is_r1 ? 5'd1 : rd;
    assign GPR_write_data = GPR_write_src_is_MEM ? MEM_result : ALU_result;

    regfile gpr_regfile (
        .clk         (clk),
        .read_num1   (GPR_read_num1),
        .read_data1  (GPR_read_data1),
        .read_num2   (GPR_read_num2),
        .read_data2  (GPR_read_data2),
        .write_enable(GPR_write_enable),
        .write_num   (GPR_write_num),
        .write_data  (GPR_write_data)
    );

    assign rj_data = GPR_read_data1;
    assign rkd_data = GPR_read_data2;

    assign rj_eq_rd = rj_data == rkd_data;
    // assign rj_lt_rd = $signed(rj_data) < $signed(rkd_data);
    // assign rj_ltu_rd = rj_data < rkd_data;
    assign taken = ( branch[`BRANCH_EQ] & ~branch_reverse & rj_eq_rd
                   | branch[`BRANCH_EQ] & branch_reverse & ~rj_eq_rd
                   | jump | branch[`BRANCH_UNCOND]
                   ) & valid;

    adder #(
        .WIDTH(32)
    ) seq_adder (
        .addend1(PC),
        .addend2(32'h4),
        .cin    (1'b0),
        .sum    (seq_PC),
        .cout   ()
    );

    adder #(
        .WIDTH(32)
    ) target_adder (
        .addend1(jump ? rj_data : PC),
        .addend2(offs),
        .cin    (1'b0),
        .sum    (target_PC),
        .cout   ()
    );

    assign next_PC      = taken ? target_PC : seq_PC;

    assign ALU_operand1 = ALU_src1_is_PC ? PC : rj_data;
    assign ALU_operand2 = ALU_src2_is_imm ? imm : rkd_data;

    ALU alu (
        .operation(ALU_operation),
        .operand1 (ALU_operand1),
        .operand2 (ALU_operand2),
        .result   (ALU_result),
        .MEM_addr (MEM_addr)
    );

    assign data_sram_we      = MEM_write & valid;
    assign data_sram_addr    = MEM_addr;
    assign data_sram_wdata   = rkd_data;
    assign MEM_result        = data_sram_rdata;

    assign debug_wb_pc       = PC;
    assign debug_wb_rf_we    = {4{GPR_write_enable}};
    assign debug_wb_rf_wnum  = GPR_write_num;
    assign debug_wb_rf_wdata = GPR_write_data;

endmodule
