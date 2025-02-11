`include "../macros.vh"

module ID (
    input  wire [                    31:0] instruction,
    output wire                            jump,
    output wire [       `BRANCH_WIDTH-1:0] branch,
    output wire                            branch_reverse,
    output wire [      `IMM_SRC_WIDTH-1:0] imm_src,
    output wire [     `OFFS_SRC_WIDTH-1:0] offs_src,
    output wire                            GPR_read_src2_is_rd,  // default : rk
    output wire                            CNT_is_high,          // default : low
    output wire                            ALU_src1_is_PC,       // default : rj
    output wire                            ALU_src2_is_imm,      // default : rk/rd
    output wire [       `ALU_OP_WIDTH-1:0] ALU_operation,
    output wire [     `MEM_READ_WIDTH-1:0] MEM_read,
    output wire [    `MEM_WRITE_WIDTH-1:0] MEM_write,
    output wire                            GPR_write,
    output wire [`GPR_WRITE_DST_WIDTH-1:0] GPR_write_dst,        // default : rd
    output wire [`GPR_WRITE_SRC_WIDTH-1:0] GPR_write_src,
    output wire                            CSR_number_is_TID,    // default : csr
    output wire                            CSR_write,
    output wire                            CSR_mask,
    output wire                            __return,
    output wire                            syscall,
    output wire                            __break,
    output wire                            not_existed,
    output wire                            GPR1_use,
    output wire                            GPR2_use,
    output wire [      `GPR_NEW_WIDTH-1:0] GPR_new
);
    wire [ 5:0] instr_31_26 = instruction[31:26];
    wire [ 1:0] instr_25_24 = instruction[25:24];
    wire [ 1:0] instr_23_22 = instruction[23:22];
    wire [ 1:0] instr_21_20 = instruction[21:20];
    wire [ 4:0] instr_19_15 = instruction[19:15];
    wire [ 4:0] instr_14_10 = instruction[14:10];
    wire [ 4:0] instr_9_5 = instruction[9:5];
    wire [ 4:0] instr_4_0 = instruction[4:0];

    wire [63:0] instr_31_26_d;
    wire [ 3:0] instr_25_24_d;
    wire [ 3:0] instr_23_22_d;
    wire [ 3:0] instr_21_20_d;
    wire [31:0] instr_19_15_d;
    wire [31:0] instr_14_10_d;
    wire [31:0] instr_9_5_d;
    wire [31:0] instr_4_0_d;

    decoder #(
        .IN_WIDTH (6),
        .OUT_WIDTH(64)
    ) decoder_6_64 (
        .in (instr_31_26),
        .out(instr_31_26_d)
    );
    decoder #(
        .IN_WIDTH (2),
        .OUT_WIDTH(4)
    ) decoder_2_4_0 (
        .in (instr_25_24),
        .out(instr_25_24_d)
    );
    decoder #(
        .IN_WIDTH (2),
        .OUT_WIDTH(4)
    ) decoder_2_4_1 (
        .in (instr_23_22),
        .out(instr_23_22_d)
    );
    decoder #(
        .IN_WIDTH (2),
        .OUT_WIDTH(4)
    ) decoder_2_4_2 (
        .in (instr_21_20),
        .out(instr_21_20_d)
    );
    decoder #(
        .IN_WIDTH (5),
        .OUT_WIDTH(32)
    ) decoder_5_32_0 (
        .in (instr_19_15),
        .out(instr_19_15_d)
    );
    decoder #(
        .IN_WIDTH (5),
        .OUT_WIDTH(32)
    ) decoder_5_32_1 (
        .in (instr_14_10),
        .out(instr_14_10_d)
    );
    decoder #(
        .IN_WIDTH (5),
        .OUT_WIDTH(32)
    ) decoder_5_32_2 (
        .in (instr_9_5),
        .out(instr_9_5_d)
    );
    decoder #(
        .IN_WIDTH (5),
        .OUT_WIDTH(32)
    ) decoder_5_32_3 (
        .in (instr_4_0),
        .out(instr_4_0_d)
    );

    wire rdcntid_w = instr_31_26_d[`RDCNTID_W_31_26] & instr_25_24_d[`RDCNTID_W_25_24] &
                     instr_23_22_d[`RDCNTID_W_23_22] & instr_21_20_d[`RDCNTID_W_21_20] &
                     instr_19_15_d[`RDCNTID_W_19_15] & instr_14_10_d[`RDCNTID_W_14_10] &
                     instr_4_0_d[`RDCNTID_W_4_0];
    wire rdcntvl_w = instr_31_26_d[`RDCNTVL_W_31_26] & instr_25_24_d[`RDCNTVL_W_25_24] &
                     instr_23_22_d[`RDCNTVL_W_23_22] & instr_21_20_d[`RDCNTVL_W_21_20] &
                     instr_19_15_d[`RDCNTVL_W_19_15] & instr_14_10_d[`RDCNTVL_W_14_10] &
                     instr_9_5_d[`RDCNTVL_W_9_5];
    wire rdcntvh_w = instr_31_26_d[`RDCNTVH_W_31_26] & instr_25_24_d[`RDCNTVH_W_25_24] &
                     instr_23_22_d[`RDCNTVH_W_23_22] & instr_21_20_d[`RDCNTVH_W_21_20] &
                     instr_19_15_d[`RDCNTVH_W_19_15] & instr_14_10_d[`RDCNTVH_W_14_10] &
                     instr_9_5_d[`RDCNTVH_W_9_5];
    wire add_w  = instr_31_26_d[`ADD_W_31_26] & instr_25_24_d[`ADD_W_25_24] &
                  instr_23_22_d[`ADD_W_23_22] & instr_21_20_d[`ADD_W_21_20] &
                  instr_19_15_d[`ADD_W_19_15];
    wire sub_w  = instr_31_26_d[`SUB_W_31_26] & instr_25_24_d[`SUB_W_25_24] &
                  instr_23_22_d[`SUB_W_23_22] & instr_21_20_d[`SUB_W_21_20] &
                  instr_19_15_d[`SUB_W_19_15];
    wire slt    = instr_31_26_d[`SLT_31_26] & instr_25_24_d[`SLT_25_24] &
                  instr_23_22_d[`SLT_23_22] & instr_21_20_d[`SLT_21_20] &
                  instr_19_15_d[`SLT_19_15];
    wire sltu   = instr_31_26_d[`SLTU_31_26] & instr_25_24_d[`SLTU_25_24] &
                  instr_23_22_d[`SLTU_23_22] & instr_21_20_d[`SLTU_21_20] &
                  instr_19_15_d[`SLTU_19_15];
    wire __nor  = instr_31_26_d[`NOR_31_26] & instr_25_24_d[`NOR_25_24] &
                  instr_23_22_d[`NOR_23_22] & instr_21_20_d[`NOR_21_20] &
                  instr_19_15_d[`NOR_19_15];
    wire __and  = instr_31_26_d[`AND_31_26] & instr_25_24_d[`AND_25_24] &
                  instr_23_22_d[`AND_23_22] & instr_21_20_d[`AND_21_20] &
                  instr_19_15_d[`AND_19_15];
    wire __or   = instr_31_26_d[`OR_31_26] & instr_25_24_d[`OR_25_24] &
                  instr_23_22_d[`OR_23_22] & instr_21_20_d[`OR_21_20] &
                  instr_19_15_d[`OR_19_15];
    wire __xor  = instr_31_26_d[`XOR_31_26] & instr_25_24_d[`XOR_25_24] &
                  instr_23_22_d[`XOR_23_22] & instr_21_20_d[`XOR_21_20] &
                  instr_19_15_d[`XOR_19_15];
    wire sll_w  = instr_31_26_d[`SLL_W_31_26] & instr_25_24_d[`SLL_W_25_24] &
                  instr_23_22_d[`SLL_W_23_22] & instr_21_20_d[`SLL_W_21_20] &
                  instr_19_15_d[`SLL_W_19_15];
    wire srl_w  = instr_31_26_d[`SRL_W_31_26] & instr_25_24_d[`SRL_W_25_24] &
                  instr_23_22_d[`SRL_W_23_22] & instr_21_20_d[`SRL_W_21_20] &
                  instr_19_15_d[`SRL_W_19_15];
    wire sra_w  = instr_31_26_d[`SRA_W_31_26] & instr_25_24_d[`SRA_W_25_24] &
                  instr_23_22_d[`SRA_W_23_22] & instr_21_20_d[`SRA_W_21_20] &
                  instr_19_15_d[`SRA_W_19_15];
    wire mul_w  = instr_31_26_d[`MUL_W_31_26] & instr_25_24_d[`MUL_W_25_24] &
                  instr_23_22_d[`MUL_W_23_22] & instr_21_20_d[`MUL_W_21_20] &
                  instr_19_15_d[`MUL_W_19_15];
    wire mulh_w = instr_31_26_d[`MULH_W_31_26] & instr_25_24_d[`MULH_W_25_24] &
                  instr_23_22_d[`MULH_W_23_22] & instr_21_20_d[`MULH_W_21_20] &
                  instr_19_15_d[`MULH_W_19_15];
    wire mulhu_wu = instr_31_26_d[`MULHU_WU_31_26] & instr_25_24_d[`MULHU_WU_25_24] &
                    instr_23_22_d[`MULHU_WU_23_22] & instr_21_20_d[`MULHU_WU_21_20] &
                    instr_19_15_d[`MULHU_WU_19_15];
    wire div_w  = instr_31_26_d[`DIV_W_31_26] & instr_25_24_d[`DIV_W_25_24] &
                  instr_23_22_d[`DIV_W_23_22] & instr_21_20_d[`DIV_W_21_20] &
                  instr_19_15_d[`DIV_W_19_15];
    wire mod_w  = instr_31_26_d[`MOD_W_31_26] & instr_25_24_d[`MOD_W_25_24] &
                  instr_23_22_d[`MOD_W_23_22] & instr_21_20_d[`MOD_W_21_20] &
                  instr_19_15_d[`MOD_W_19_15];
    wire div_wu = instr_31_26_d[`DIV_WU_31_26] & instr_25_24_d[`DIV_WU_25_24] &
                  instr_23_22_d[`DIV_WU_23_22] & instr_21_20_d[`DIV_WU_21_20] &
                  instr_19_15_d[`DIV_WU_19_15];
    wire mod_wu = instr_31_26_d[`MOD_WU_31_26] & instr_25_24_d[`MOD_WU_25_24] &
                  instr_23_22_d[`MOD_WU_23_22] & instr_21_20_d[`MOD_WU_21_20] &
                  instr_19_15_d[`MOD_WU_19_15];
    assign __break = instr_31_26_d[`BREAK_31_26] & instr_25_24_d[`BREAK_25_24] &
                     instr_23_22_d[`BREAK_23_22] & instr_21_20_d[`BREAK_21_20] &
                     instr_19_15_d[`BREAK_19_15];
    assign syscall = instr_31_26_d[`SYSCALL_31_26] & instr_25_24_d[`SYSCALL_25_24] &
                     instr_23_22_d[`SYSCALL_23_22] & instr_21_20_d[`SYSCALL_21_20] &
                     instr_19_15_d[`SYSCALL_19_15];
    wire slli_w = instr_31_26_d[`SLLI_W_31_26] & instr_25_24_d[`SLLI_W_25_24] &
                  instr_23_22_d[`SLLI_W_23_22] & instr_21_20_d[`SLLI_W_21_20] &
                  instr_19_15_d[`SLLI_W_19_15];
    wire srli_w = instr_31_26_d[`SRLI_W_31_26] & instr_25_24_d[`SRLI_W_25_24] &
                  instr_23_22_d[`SRLI_W_23_22] & instr_21_20_d[`SRLI_W_21_20] &
                  instr_19_15_d[`SRLI_W_19_15];
    wire srai_w = instr_31_26_d[`SRAI_W_31_26] & instr_25_24_d[`SRAI_W_25_24] &
                  instr_23_22_d[`SRAI_W_23_22] & instr_21_20_d[`SRAI_W_21_20] &
                  instr_19_15_d[`SRAI_W_19_15];
    wire slti   = instr_31_26_d[`SLTI_31_26] & instr_25_24_d[`SLTI_25_24] &
                  instr_23_22_d[`SLTI_23_22];
    wire sltui  = instr_31_26_d[`SLTUI_31_26] & instr_25_24_d[`SLTUI_25_24] &
                  instr_23_22_d[`SLTUI_23_22];
    wire addi_w = instr_31_26_d[`ADDI_W_31_26] & instr_25_24_d[`ADDI_W_25_24] &
                  instr_23_22_d[`ADDI_W_23_22];
    wire andi   = instr_31_26_d[`ANDI_31_26] & instr_25_24_d[`ANDI_25_24] &
                  instr_23_22_d[`ANDI_23_22];
    wire ori = instr_31_26_d[`ORI_31_26] & instr_25_24_d[`ORI_25_24] & instr_23_22_d[`ORI_23_22];
    wire xori = instr_31_26_d[`XORI_31_26] & instr_25_24_d[`XORI_25_24] &
                instr_23_22_d[`XORI_23_22];
    wire csrrd = instr_31_26_d[`CSRRD_31_26] & instr_25_24_d[`CSRRD_25_24] &
                 instr_9_5_d[`CSRRD_9_5];
    wire csrwr = instr_31_26_d[`CSRWR_31_26] & instr_25_24_d[`CSRWR_25_24] &
                 instr_9_5_d[`CSRWR_9_5];
    wire csrxchg = instr_31_26_d[`CSRXCHG_31_26] & instr_25_24_d[`CSRXCHG_25_24] &
                   ~instr_9_5_d[`CSRRD_9_5] & ~instr_9_5_d[`CSRWR_9_5];
    wire ertn = instr_31_26_d[`ERTN_31_26] & instr_25_24_d[`ERTN_25_24] &
                instr_23_22_d[`ERTN_23_22] & instr_21_20_d[`ERTN_21_20] &
                instr_19_15_d[`ERTN_19_15] & instr_14_10_d[`ERTN_14_10] &
                instr_9_5_d[`ERTN_9_5] & instr_4_0_d[`ERTN_4_0];
    wire lu12i_w = instr_31_26_d[`LU12I_W_31_26] & ~instruction[25];
    wire pcaddu12i = instr_31_26_d[`PCADDU12I_31_26] & ~instruction[25];
    wire ld_b = instr_31_26_d[`LD_B_31_26] & instr_25_24_d[`LD_B_25_24] &
                instr_23_22_d[`LD_B_23_22];
    wire ld_h = instr_31_26_d[`LD_H_31_26] & instr_25_24_d[`LD_H_25_24] &
                instr_23_22_d[`LD_H_23_22];
    wire ld_w = instr_31_26_d[`LD_W_31_26] & instr_25_24_d[`LD_W_25_24] &
                instr_23_22_d[`LD_W_23_22];
    wire st_b = instr_31_26_d[`ST_B_31_26] & instr_25_24_d[`ST_B_25_24] &
                instr_23_22_d[`ST_B_23_22];
    wire st_h = instr_31_26_d[`ST_H_31_26] & instr_25_24_d[`ST_H_25_24] &
                instr_23_22_d[`ST_H_23_22];
    wire st_w = instr_31_26_d[`ST_W_31_26] & instr_25_24_d[`ST_W_25_24] &
                instr_23_22_d[`ST_W_23_22];
    wire ld_bu = instr_31_26_d[`LD_BU_31_26] & instr_25_24_d[`LD_BU_25_24] &
                 instr_23_22_d[`LD_BU_23_22];
    wire ld_hu = instr_31_26_d[`LD_HU_31_26] & instr_25_24_d[`LD_HU_25_24] &
                 instr_23_22_d[`LD_HU_23_22];
    wire jirl = instr_31_26_d[`JIRL_31_26];
    wire b = instr_31_26_d[`B_31_26];
    wire bl = instr_31_26_d[`BL_31_26];
    wire beq = instr_31_26_d[`BEQ_31_26];
    wire bne = instr_31_26_d[`BNE_31_26];
    wire blt = instr_31_26_d[`BLT_31_26];
    wire bge = instr_31_26_d[`BGE_31_26];
    wire bltu = instr_31_26_d[`BLTU_31_26];
    wire bgeu = instr_31_26_d[`BGEU_31_26];

    assign jump = jirl;

    assign branch[`BRANCH_UNCOND] = b | bl;
    assign branch[`BRANCH_EQ] = beq | bne;
    assign branch[`BRANCH_LT] = blt | bge;
    assign branch[`BRANCH_LTU] = bltu | bgeu;

    assign branch_reverse = bne | bge | bgeu;

    // ui5 = ui12[4:0]
    assign imm_src[`IMM_SRC_4] = jirl | bl;
    assign imm_src[`IMM_SRC_UI12] = slli_w | srli_w | srai_w | andi | ori | xori;
    assign imm_src[`IMM_SRC_SI12] = slti | sltui | addi_w |
                                    ld_b | ld_h | ld_w | st_b | st_h | st_w | ld_bu | ld_hu;
    assign imm_src[`IMM_SRC_SI14] = 1'b0;
    assign imm_src[`IMM_SRC_SI20] = lu12i_w | pcaddu12i;

    assign offs_src[`OFFS_SRC_16] = jirl | beq | bne | blt | bge | bltu | bgeu;
    assign offs_src[`OFFS_SRC_21] = 1'b0;
    assign offs_src[`OFFS_SRC_26] = b | bl;

    assign GPR_read_src2_is_rd = st_b | st_h | st_w | beq | bne | blt | bge | bltu | bgeu |
                                 csrwr | csrxchg;

    assign CNT_is_high = rdcntvh_w;

    assign ALU_src1_is_PC = jirl | bl | pcaddu12i;
    assign ALU_src2_is_imm = slli_w | srli_w | srai_w | slti | sltui | addi_w | andi | ori | xori |
                             lu12i_w | pcaddu12i | ld_b | ld_h | ld_w | ld_bu | ld_hu |
                             st_b | st_h | st_w | jirl | bl;

    assign ALU_operation[`ALU_OP_ADD] = add_w | addi_w | jirl | bl | pcaddu12i |
                                        ld_b | ld_h | ld_w | st_b | st_h | st_w | ld_bu | ld_hu;
    assign ALU_operation[`ALU_OP_SUB] = sub_w;
    assign ALU_operation[`ALU_OP_SLT] = slt | slti;
    assign ALU_operation[`ALU_OP_SLTU] = sltu | sltui;
    assign ALU_operation[`ALU_OP_AND] = __and | andi;
    assign ALU_operation[`ALU_OP_NOR] = __nor;
    assign ALU_operation[`ALU_OP_OR] = __or | ori;
    assign ALU_operation[`ALU_OP_XOR] = __xor | xori;
    assign ALU_operation[`ALU_OP_SLL] = slli_w | sll_w;
    assign ALU_operation[`ALU_OP_SRL] = srli_w | srl_w;
    assign ALU_operation[`ALU_OP_SRA] = srai_w | sra_w;
    assign ALU_operation[`ALU_OP_LUI] = lu12i_w;
    assign ALU_operation[`ALU_OP_MUL_LO] = mul_w;
    assign ALU_operation[`ALU_OP_MUL_HI] = mulh_w;
    assign ALU_operation[`ALU_OP_MULU_HI] = mulhu_wu;
    assign ALU_operation[`ALU_OP_DIV] = div_w;
    assign ALU_operation[`ALU_OP_MOD] = mod_w;
    assign ALU_operation[`ALU_OP_DIVU] = div_wu;
    assign ALU_operation[`ALU_OP_MODU] = mod_wu;

    assign MEM_read[`MEM_READ_BYTE] = ld_b;
    assign MEM_read[`MEM_READ_HALF] = ld_h;
    assign MEM_read[`MEM_READ_WORD] = ld_w;
    assign MEM_read[`MEM_READ_BYTEU] = ld_bu;
    assign MEM_read[`MEM_READ_HALFU] = ld_hu;

    assign MEM_write[`MEM_WRITE_BYTE] = st_b;
    assign MEM_write[`MEM_WRITE_HALF] = st_h;
    assign MEM_write[`MEM_WRITE_WORD] = st_w;

    assign GPR_write = jirl | bl | lu12i_w | pcaddu12i | rdcntvl_w | rdcntvh_w | rdcntid_w |
                       add_w | sub_w | slt | sltu | __and | __nor | __or | __xor |
                       andi | ori | xori | sll_w | srl_w | sra_w |
                       mul_w | mulh_w | mulhu_wu | div_w | mod_w | div_wu | mod_wu |
                       slli_w | srli_w | srai_w | slti | sltui | addi_w |
                       ld_b | ld_h | ld_w | ld_bu | ld_hu | csrrd | csrwr | csrxchg;

    assign GPR_write_dst[`GPR_WRITE_DST_R1] = bl;
    assign GPR_write_dst[`GPR_WRITE_DST_RJ] = rdcntid_w;

    assign GPR_write_src[`GPR_WRITE_SRC_LINK] = jirl | bl;
    assign GPR_write_src[`GPR_WRITE_SRC_LUI] = lu12i_w;
    assign GPR_write_src[`GPR_WRITE_SRC_CNT] = rdcntvl_w | rdcntvh_w;
    assign GPR_write_src[`GPR_WRITE_SRC_ALU] = add_w | sub_w | slt | sltu | jirl | bl | lu12i_w |
                                               __and | __nor | __or | __xor | andi | ori | xori |
                                               sll_w | srl_w | sra_w | mul_w | mulh_w | mulhu_wu |
                                               div_w | mod_w | div_wu | mod_wu | pcaddu12i |
                                               slli_w | srli_w | srai_w | slti | sltui | addi_w;
    assign GPR_write_src[`GPR_WRITE_SRC_MEM] = ld_b | ld_h | ld_w | ld_bu | ld_hu;
    assign GPR_write_src[`GPR_WRITE_SRC_CSR] = csrrd | csrwr | csrxchg | rdcntid_w;

    assign CSR_number_is_TID = rdcntid_w;

    assign CSR_write = csrwr | csrxchg;

    assign CSR_mask = csrxchg;

    assign __return = ertn;

    assign not_existed = ~rdcntid_w & ~rdcntvl_w & ~rdcntvh_w &
                         ~add_w & ~sub_w & ~slt & ~sltu & ~__nor & ~__and & ~__or & ~__xor &
                         ~sll_w & ~srl_w & ~sra_w & ~mul_w & ~mulh_w & ~mulhu_wu & ~div_w & ~mod_w &
                         ~div_wu & ~mod_wu & ~__break & ~syscall & ~slli_w & ~srli_w & ~srai_w &
                         ~slti & ~sltui & ~addi_w & ~andi & ~ori & ~xori & ~csrrd & ~csrwr &
                         ~csrxchg & ~ertn & ~lu12i_w & ~pcaddu12i &
                         ~ld_b & ~ld_h & ~ld_w & ~st_b & ~st_h & ~st_w & ~ld_bu & ~ld_hu & ~jirl &
                         ~b & ~bl & ~beq & ~bne & ~blt & ~bge & ~bltu & ~bgeu;

    assign GPR1_use = add_w | sub_w | slt | sltu | __and | __nor | __or | __xor |
                      sll_w | srl_w | sra_w | mul_w | mulh_w | mulhu_wu |
                      div_w | mod_w | div_wu | mod_wu | slli_w | srli_w | srai_w |
                      slti | sltui | addi_w | andi | ori | xori |
                      ld_b | ld_h | ld_w | ld_bu | ld_hu | st_b | st_h | st_w |
                      beq | bne | blt | bge | bltu | bgeu | jirl | csrxchg;
    assign GPR2_use = beq | bne | blt | bge | bltu | bgeu |
                      add_w | sub_w | slt | sltu | __and | __nor | __or | __xor |
                      sll_w | srl_w | sra_w | st_b | st_h | st_w |
                      mul_w | mulh_w | mulhu_wu | div_w | mod_w | div_wu | mod_wu |
                      csrwr | csrxchg;

    assign GPR_new[`GPR_NEW_EXE] = jirl | bl | lu12i_w | rdcntvl_w | rdcntvh_w;
    assign GPR_new[`GPR_NEW_MEM] = add_w | sub_w | slt | sltu | __and | __nor | __or | __xor |
                                   sll_w | srl_w | sra_w | mul_w | mulh_w | mulhu_wu |
                                   div_w | mod_w | div_wu | mod_wu | slli_w | srli_w | srai_w |
                                   slti | sltui | addi_w | andi | ori | xori | pcaddu12i;
    assign GPR_new[`GPR_NEW_WB] = ld_b | ld_h | ld_w | ld_bu | ld_hu |
                                  csrrd | csrwr | csrxchg | rdcntid_w;
endmodule

