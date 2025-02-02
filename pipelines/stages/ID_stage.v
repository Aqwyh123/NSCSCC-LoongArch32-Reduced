`include "../../macros.vh"

module ID_stage (
    input  wire [                    31:0] PC,
    input  wire [                    31:0] inst,
    output wire                            ALU_src1_is_PC,
    output wire                            ALU_src2_is_imm,
    output wire [       `ALU_OP_WIDTH-1:0] ALU_operation,
    output wire                            MEM_read,
    output wire [ `MEM_READ_EXT_WIDTH-1:0] MEM_read_ext,
    output wire                            MEM_write,
    output wire [`MEM_WRITE_EXT_WIDTH-1:0] MEM_write_ext,
    output wire [                     4:0] GPR_read_num1,
    input  wire [                    31:0] rj_data,
    output wire [                     4:0] GPR_read_num2,
    input  wire [                    31:0] rkd_data,
    output wire                            GPR_write,
    output wire [                     4:0] GPR_write_num,
    output wire                            GPR_write_src_is_MEM,
    output wire                            bj_taken,
    output wire [                    31:0] target_PC,
    output wire [                    31:0] imm,
    output wire [      `GPR_USE_WIDTH-1:0] GPR1_use,
    output wire [      `GPR_USE_WIDTH-1:0] GPR2_use,
    output wire [      `GPR_NEW_WIDTH-1:0] GPR_new
);
    wire jump;
    wire [`BRANCH_WIDTH-1:0] branch;
    wire branch_reverse;
    wire [`OFFS_SRC_WIDTH-1:0] offs_src;
    wire [`IMM_SRC_WIDTH-1:0] imm_src;
    wire GPR_read_src2_is_rd;
    wire GPR_write_dst_is_r1;

    wire [4:0] rd = inst[`RD_MSB:`RD_LSB];
    wire [4:0] rj = inst[`RJ_MSB:`RJ_LSB];
    wire [4:0] rk = inst[`RK_MSB:`RK_LSB];

    wire [11:0] i12 = inst[`I12_MSB:`I12_LSB];
    wire [13:0] i14 = inst[`I14_MSB:`I14_LSB];
    wire [19:0] i20 = inst[`I20_MSB:`I20_LSB];

    wire [15:0] o16 = inst[`O16_MSB:`O16_LSB];
    wire [20:0] o21 = {inst[`O21_HIGH_MSB:`O21_HIGH_LSB], inst[`O21_LOW_MSB:`O21_LOW_LSB]};
    wire [25:0] o26 = {inst[`O26_HIGH_MSB:`O26_HIGH_LSB], inst[`O26_LOW_MSB:`O26_LOW_LSB]};
    wire [31:0] offs;

    wire rj_eq_rd;
    // wire rj_lt_rd;
    // wire rj_ltu_rd;

    ID id (
        .instruction         (inst),
        .branch              (branch),
        .branch_reverse      (branch_reverse),
        .jump                (jump),
        .imm_src             (imm_src),
        .offs_src            (offs_src),
        .GPR_read_src2_is_rd (GPR_read_src2_is_rd),
        .ALU_src1_is_PC      (ALU_src1_is_PC),
        .ALU_src2_is_imm     (ALU_src2_is_imm),
        .ALU_operation       (ALU_operation),
        .MEM_read            (MEM_read),
        .MEM_read_ext        (MEM_read_ext),
        .MEM_write           (MEM_write),
        .MEM_write_ext       (MEM_write_ext),
        .GPR_write           (GPR_write),
        .GPR_write_dst_is_r1 (GPR_write_dst_is_r1),
        .GPR_write_src_is_MEM(GPR_write_src_is_MEM),
        .GPR1_use            (GPR1_use),
        .GPR2_use            (GPR2_use),
        .GPR_new             (GPR_new)
    );

    assign GPR_read_num1 = rj;
    assign GPR_read_num2 = GPR_read_src2_is_rd ? rd : rk;

    assign rj_eq_rd = rj_data == rkd_data;
    // assign rj_lt_rd = $signed(rj_data) < $signed(rkd_data);
    // assign rj_ltu_rd = rj_data < rkd_data;

    assign offs = {32{offs_src[`OFFS_SRC_16]}} & {{14{o16[15]}}, o16, 2'b0} |
                  {32{offs_src[`OFFS_SRC_21]}} & {{9{o21[20]}},o21,2'b0} |
                  {32{offs_src[`OFFS_SRC_26]}} & {{4{o26[25]}}, o26, 2'b0};

    assign bj_taken = jump | branch[`BRANCH_UNCOND] | branch[`BRANCH_EQ] & (branch_reverse ^ rj_eq_rd);

    adder #(
        .WIDTH(32)
    ) target_PC_adder (
        .addend1(jump ? rj_data : PC),
        .addend2(offs),
        .cin    (1'b0),
        .sum    (target_PC),
        .cout   ()
    );

    // si20 is used to lu12i_w
    assign imm = {32{imm_src[`IMM_SRC_4]}} & 32'h4 |
                 {32{imm_src[`IMM_SRC_UI12]}} & {20'b0, i12} |
                 {32{imm_src[`IMM_SRC_SI12]}} & {{20{i12[11]}}, i12} |
                 {32{imm_src[`IMM_SRC_SI14]}} & {{18{i14[13]}}, i14} |
                 {32{imm_src[`IMM_SRC_SI20]}} & {i20, 12'b0};

    assign GPR_write_num = GPR_write_dst_is_r1 ? 5'd1 : rd;
endmodule
