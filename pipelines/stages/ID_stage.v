`include "../../macros.vh"

module ID_stage (
    // control signals
    input  wire                            valid,
    // data signals
    input  wire [                    31:0] inst,
    input  wire [                    31:0] PC,
    output wire                            jump,
    output wire [       `BRANCH_WIDTH-1:0] branch,
    output wire [                     4:0] GPR_read_num1,
    input  wire [                    31:0] rj_data,
    output wire [                     4:0] GPR_read_num2,
    input  wire [                    31:0] rkd_data,
    output wire [   `CSR_NUMBER_WIDTH-1:0] CSR_number,
    input  wire [                    31:0] CSR_read_data,
    input  wire [                    63:0] CSR_counter,
    output wire [                    31:0] CSR_result,
    output wire                            ALU_src1_is_PC,
    output wire                            ALU_src2_is_imm,
    output wire [       `ALU_OP_WIDTH-1:0] ALU_operation,
    output wire                            mul_div_unsigned,
    output wire [     `MEM_READ_WIDTH-1:0] MEM_read,
    output wire [    `MEM_WRITE_WIDTH-1:0] MEM_write,
    output wire                            GPR_write,
    output wire [                     4:0] GPR_write_num,
    output wire [`GPR_WRITE_SRC_WIDTH-1:0] GPR_write_src,
    output wire                            CSR_write,
    output wire                            CSR_write_mask,
    output wire [       `TLB_OP_WIDTH-1:0] TLB_operation,
    output wire [                     4:0] invtlb_op,
    output wire                            GPR1_use,
    output wire                            GPR2_use,
    output wire [      `GPR_NEW_WIDTH-1:0] GPR_new,
    output wire                            CSR_use,
    output wire                            bj_taken,
    output wire [                    31:0] target_PC,
    output wire [                    31:0] imm,
    output wire                            ereturn,
    output wire                            refetch,
    output wire                            SYS,
    output wire                            BRK,
    output wire                            INE
);
    wire branch_reverse;
    wire [`OFFS_SRC_WIDTH-1:0] offs_src;
    wire [`IMM_SRC_WIDTH-1:0] imm_src;
    wire GPR_read_src2_is_rd;
    wire [`GPR_WRITE_DST_WIDTH-1:0] GPR_write_dst;
    wire [`CSR_SRC_WIDTH-1:0] CSR_read_src;

    wire [4:0] rd = inst[`RD_MSB:`RD_LSB];
    wire [4:0] rj = inst[`RJ_MSB:`RJ_LSB];
    wire [4:0] rk = inst[`RK_MSB:`RK_LSB];

    wire [11:0] i12 = inst[`I12_MSB:`I12_LSB];
    wire [13:0] i14 = inst[`I14_MSB:`I14_LSB];
    wire [19:0] i20 = inst[`I20_MSB:`I20_LSB];

    wire [15:0] o16 = inst[`O16_MSB:`O16_LSB];
    wire [20:0] o21 = {inst[`O21_HI_MSB:`O21_HI_LSB], inst[`O21_LO_MSB:`O21_LO_LSB]};
    wire [25:0] o26 = {inst[`O26_HI_MSB:`O26_HI_LSB], inst[`O26_LO_MSB:`O26_LO_LSB]};
    wire [31:0] offs;

    wire rj_eq_rd;
    wire rj_lt_rd;
    wire rj_ltu_rd;

    ID id (
        .instruction        (inst),
        .jump               (jump),
        .branch             (branch),
        .branch_reverse     (branch_reverse),
        .imm_src            (imm_src),
        .offs_src           (offs_src),
        .GPR_read_src2_is_rd(GPR_read_src2_is_rd),
        .ALU_src1_is_PC     (ALU_src1_is_PC),
        .ALU_src2_is_imm    (ALU_src2_is_imm),
        .ALU_operation      (ALU_operation),
        .mul_div_unsigned   (mul_div_unsigned),
        .MEM_read           (MEM_read),
        .MEM_write          (MEM_write),
        .GPR_write          (GPR_write),
        .GPR_write_dst      (GPR_write_dst),
        .GPR_write_src      (GPR_write_src),
        .CSR_read_src       (CSR_read_src),
        .CSR_write          (CSR_write),
        .CSR_write_mask     (CSR_write_mask),
        .TLB_operation      (TLB_operation),
        .ereturn            (ereturn),
        .syscall            (SYS),
        .__break            (BRK),
        .not_existed        (INE),
        .GPR1_use           (GPR1_use),
        .GPR2_use           (GPR2_use),
        .GPR_new            (GPR_new),
        .CSR_use            (CSR_use)
    );

    assign GPR_read_num1 = rj;
    assign GPR_read_num2 = GPR_read_src2_is_rd ? rd : rk;

    assign rj_eq_rd = rj_data == rkd_data;
    assign rj_lt_rd = rj_data[31] & ~rkd_data[31] |
                      rj_data[31] & rj_ltu_rd |
                     ~rkd_data[31] & rj_ltu_rd;
    assign rj_ltu_rd = rj_data < rkd_data;

    assign offs = {32{offs_src[`OFFS_SRC_16]}} & {{14{o16[15]}}, o16, 2'b0} |
                  {32{offs_src[`OFFS_SRC_21]}} & {{9{o21[20]}},o21,2'b0} |
                  {32{offs_src[`OFFS_SRC_26]}} & {{4{o26[25]}}, o26, 2'b0};

    assign bj_taken = valid & (jump | branch[`BRANCH_UNCOND] |
                      branch[`BRANCH_EQ] & (branch_reverse ^ rj_eq_rd) |
                      branch[`BRANCH_LT] & (branch_reverse ^ rj_lt_rd) |
                      branch[`BRANCH_LTU] & (branch_reverse ^ rj_ltu_rd));

    assign target_PC = (jump ? rj_data : PC) + offs;

    // si20 is used to lu12i_w
    assign imm = {32{imm_src[`IMM_SRC_4]}} & 32'h4 |
                 {32{imm_src[`IMM_SRC_UI12]}} & {20'b0, i12} |
                 {32{imm_src[`IMM_SRC_SI12]}} & {{20{i12[11]}}, i12} |
                 {32{imm_src[`IMM_SRC_SI14]}} & {{18{i14[13]}}, i14} |
                 {32{imm_src[`IMM_SRC_SI20]}} & {i20, 12'b0};

    assign GPR_write_num = GPR_write_dst[`GPR_WRITE_DST_R1] ? 5'd1 :
                           GPR_write_dst[`GPR_WRITE_DST_RJ] ? rj : rd;

    assign CSR_number = CSR_read_src[`CSR_SRC_TID] ? `CSR_TID : i14;

    assign CSR_result = {32{|CSR_read_src[`CSR_SRC_TID:`CSR_SRC_CSR]}} & CSR_read_data |
                        {32{CSR_read_src[`CSR_SRC_CNTLO]}} & CSR_counter[31:0] |
                        {32{CSR_read_src[`CSR_SRC_CNTHI]}} & CSR_counter[63:32];

    assign invtlb_op = rd;

    assign refetch = |TLB_operation[`TLB_OP_INVALID:`TLB_OP_READ] |
                      CSR_write & (CSR_number == `CSR_CRMD | CSR_number == `CSR_ASID |
                                   CSR_number == `CSR_DMW0 | CSR_number == `CSR_DMW1);
endmodule
