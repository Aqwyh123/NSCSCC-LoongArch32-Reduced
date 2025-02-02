`include "../macros.vh"

module ID (
    input  wire [                    31:0] instruction,
    output wire [       `BRANCH_WIDTH-1:0] branch,
    output wire                            branch_reverse,
    output wire                            jump,
    output wire [      `IMM_SRC_WIDTH-1:0] imm_src,
    output wire [     `OFFS_SRC_WIDTH-1:0] offs_src,
    output wire                            GPR_read_src2_is_rd,   // default : rk
    output wire                            ALU_src1_is_PC,        // default : rj
    output wire                            ALU_src2_is_imm,       // default : rk/rd
    output wire [       `ALU_OP_WIDTH-1:0] ALU_operation,
    output wire                            MEM_read,
    output wire [ `MEM_READ_EXT_WIDTH-1:0] MEM_read_ext,
    output wire                            MEM_write,
    output wire [`MEM_WRITE_EXT_WIDTH-1:0] MEM_write_ext,
    output wire                            GPR_write,
    output wire                            GPR_write_dst_is_r1,   // default : rd
    output wire                            GPR_write_src_is_MEM,  // default : ALU
    output wire [      `GPR_USE_WIDTH-1:0] GPR1_use,
    output wire [      `GPR_USE_WIDTH-1:0] GPR2_use,
    output wire [      `GPR_NEW_WIDTH-1:0] GPR_new
);
    wire [ 5:0] instr_31_26 = instruction[31:26];
    wire [ 1:0] instr_25_24 = instruction[25:24];
    wire [ 1:0] instr_23_22 = instruction[23:22];
    wire [ 1:0] instr_21_20 = instruction[21:20];
    wire [ 4:0] instr_19_15 = instruction[19:15];
    // wire [ 4:0] instr_14_10 = instruction[14:10];

    wire [63:0] instr_31_26_d;
    wire [ 3:0] instr_25_24_d;
    wire [ 3:0] instr_23_22_d;
    wire [ 3:0] instr_21_20_d;
    wire [31:0] instr_19_15_d;
    // wire [31:0] instr_14_10_d;

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
    // decoder #(
    //     .IN_WIDTH (5),
    //     .OUT_WIDTH(32)
    // ) decoder_5_32_1 (
    //     .in (instr_14_10),
    //     .out(instr_14_10_d)
    // );

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
    wire lu12i_w = instr_31_26_d[`LU12I_W_31_26] & ~instruction[25];
    wire pcaddu12i = instr_31_26_d[`PCADDU12I_31_26] & ~instruction[25];
    wire ld_w = instr_31_26_d[`LD_W_31_26] & instr_25_24_d[`LD_W_25_24] &
                instr_23_22_d[`LD_W_23_22];
    wire st_w = instr_31_26_d[`ST_W_31_26] & instr_25_24_d[`ST_W_25_24] &
                instr_23_22_d[`ST_W_23_22];
    wire jirl = instr_31_26_d[`JIRL_31_26];
    wire b = instr_31_26_d[`B_31_26];
    wire bl = instr_31_26_d[`BL_31_26];
    wire beq = instr_31_26_d[`BEQ_31_26];
    wire bne = instr_31_26_d[`BNE_31_26];

    assign branch[`BRANCH_UNCOND] = b | bl;
    assign branch[`BRANCH_EQ] = beq | bne;
    assign branch[`BRANCH_LT] = 1'b0;
    assign branch[`BRANCH_LTU] = 1'b0;

    assign branch_reverse = bne;

    assign jump = jirl;

    // ui5 = ui12[4:0]
    assign imm_src[`IMM_SRC_4] = jirl | bl;
    assign imm_src[`IMM_SRC_UI12] = slli_w | srli_w | srai_w | andi | ori | xori;
    assign imm_src[`IMM_SRC_SI12] = slti | sltui | addi_w | ld_w | st_w;
    assign imm_src[`IMM_SRC_SI14] = 1'b0;
    assign imm_src[`IMM_SRC_SI20] = lu12i_w | pcaddu12i;

    assign offs_src[`OFFS_SRC_16] = jirl | beq | bne;
    assign offs_src[`OFFS_SRC_21] = 1'b0;
    assign offs_src[`OFFS_SRC_26] = b | bl;

    assign ALU_src1_is_PC = jirl | bl | pcaddu12i;
    assign ALU_src2_is_imm = slli_w | srli_w | srai_w | slti | sltui | addi_w | andi | ori | xori |
                             lu12i_w | pcaddu12i |
                             ld_w |
                             st_w |
                             jirl | bl;

    assign ALU_operation[`ALU_OP_ADD] = add_w | addi_w | ld_w | st_w | jirl | bl | pcaddu12i;
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

    assign GPR_read_src2_is_rd = beq | bne | st_w;

    assign MEM_read_ext[`MEM_READ_EXT_BYTE] = 1'b0;
    assign MEM_read_ext[`MEM_READ_EXT_HALF] = 1'b0;
    assign MEM_read_ext[`MEM_READ_EXT_BYTEU] = 1'b0;
    assign MEM_read_ext[`MEM_READ_EXT_HALFU] = 1'b0;

    assign MEM_read = ld_w;

    assign MEM_write_ext[`MEM_WRITE_EXT_BYTE] = 1'b0;
    assign MEM_write_ext[`MEM_WRITE_EXT_HALF] = 1'b0;

    assign MEM_write = st_w;

    assign GPR_write = ~st_w & ~b & ~beq & ~bne;

    assign GPR_write_dst_is_r1 = bl;

    assign GPR_write_src_is_MEM = ld_w;

    assign GPR1_use[`GPR_USE_ID] = jirl | beq | bne;
    assign GPR1_use[`GPR_USE_EXE] = ~jirl & ~beq & ~bne & ~st_w & ~b & ~bl & ~lu12i_w & ~pcaddu12i;
    assign GPR2_use[`GPR_USE_ID] = beq | bne;
    assign GPR2_use[`GPR_USE_EXE] = ~jirl & ~beq & ~bne & ~b & ~bl &
                                    ~slli_w & ~srli_w & ~srai_w &
                                    ~slti & ~sltui & ~addi_w & ~andi & ~ori & ~xori &
                                    ~ld_w &
                                    ~lu12i_w & ~pcaddu12i;

    assign GPR_new[`GPR_NEW_ID] = jirl | bl;
    assign GPR_new[`GPR_NEW_EXE] = lu12i_w;
    assign GPR_new[`GPR_NEW_MEM] = ~st_w & ~b & ~beq & ~bne & ~jirl & ~bl & ~lu12i_w;
    assign GPR_new[`GPR_NEW_WB] = ld_w;
endmodule

