`ifndef MACROS_VH
`define MACROS_VH

`default_nettype none

`define PC_INIT 32'h1c000000

`define RD_MSB 4
`define RD_LSB 0
`define RJ_MSB 9
`define RJ_LSB 5
`define RK_MSB 14
`define RK_LSB 10

`define I12_MSB 21
`define I12_LSB 10
`define I14_MSB 23
`define I14_LSB 10
`define I20_MSB 24
`define I20_LSB 5

`define O16_MSB 25
`define O16_LSB 10
`define O21_HIGH_MSB 4
`define O21_HIGH_LSB 0
`define O21_LOW_MSB 25
`define O21_LOW_LSB 10
`define O26_HIGH_MSB 9
`define O26_HIGH_LSB 0
`define O26_LOW_MSB 25
`define O26_LOW_LSB 10

// ui5 = ui12[4:0]
`define IMM_SRC_WIDTH 5
`define IMM_SRC_4 0
`define IMM_SRC_UI12 1
`define IMM_SRC_SI12 2
`define IMM_SRC_SI14 3
`define IMM_SRC_SI20 4

`define OFFS_SRC_WIDTH 3
`define OFFS_SRC_16 0
`define OFFS_SRC_21 1
`define OFFS_SRC_26 2

`define BRANCH_WIDTH 4
`define BRANCH_UNCOND 0
`define BRANCH_EQ 1
`define BRANCH_LT 2
`define BRANCH_LTU 3

`define ALU_OP_WIDTH 19
`define ALU_OP_ADD 0
`define ALU_OP_SUB 1
`define ALU_OP_SLT 2
`define ALU_OP_SLTU 3
`define ALU_OP_AND 4
`define ALU_OP_NOR 5
`define ALU_OP_OR 6
`define ALU_OP_XOR 7
`define ALU_OP_SLL 8
`define ALU_OP_SRL 9
`define ALU_OP_SRA 10
`define ALU_OP_LUI 11
`define ALU_OP_MUL_LO 12
`define ALU_OP_MUL_HI 13
`define ALU_OP_MULU_HI 14
`define ALU_OP_DIV 15
`define ALU_OP_MOD 16
`define ALU_OP_DIVU 17
`define ALU_OP_MODU 18

`define MEM_READ_WIDTH 5
`define MEM_READ_BYTE 0
`define MEM_READ_HALF 1
`define MEM_READ_WORD 2
`define MEM_READ_BYTEU 3
`define MEM_READ_HALFU 4

`define MEM_WRITE_WIDTH 3
`define MEM_WRITE_BYTE 0
`define MEM_WRITE_HALF 1
`define MEM_WRITE_WORD 2

`define GPR_WRITE_WIDTH 3
`define GPR_WRITE_ALU 0
`define GPR_WRITE_MEM 1
`define GPR_WRITE_CSR 2

`define GPR_NEW_WIDTH 4
`define GPR_NEW_ID 0
`define GPR_NEW_EXE 1
`define GPR_NEW_MEM 2
`define GPR_NEW_WB 3

`define EXCEPTION_WIDTH 16
`define EXCEPTION_INT 0
`define EXCEPTION_PIL 1
`define EXCEPTION_PIS 2
`define EXCEPTION_PIF 3
`define EXCEPTION_PME 4
`define EXCEPTION_PPI 5
`define EXCEPTION_ADEF 6
`define EXCEPTION_ADEM 7
`define EXCEPTION_ALE 8
`define EXCEPTION_SYS 9
`define EXCEPTION_BRK 10
`define EXCEPTION_INE 11
`define EXCEPTION_IPE 12
`define EXCEPTION_FPD 13
`define EXCEPTION_FPE 14
`define EXCEPTION_TRBL 15

`define CSR_NUMBER_WIDTH 14

`define CSR_CRMD 14'h0000
`define CSR_CRMD_PLV 1:0
`define CSR_CRMD_IE 2
`define CSR_CRMD_DA 3
`define CSR_CRMD_PG 4
`define CSR_CRMD_DATF 6:5
`define CSR_CRMD_DATM 8:7
`define CSR_CRMD_0 31:9
`define CSR_CRMD_0_WIDTH 23

`define CSR_PRMD 14'h0001
`define CSR_PRMD_PPLV 1:0
`define CSR_PRMD_PIE 2
`define CSR_PRMD_0 31:3
`define CSR_PRMD_0_WIDTH 29

`define CSR_ECFG 14'h0004
`define CSR_ECFG_LIE_9_0 9:0
`define CSR_ECFG_0_LOW 10
`define CSR_ECFG_LIE_12_11 12:11
`define CSR_ECFG_0_HIGH 31:13
`define CSR_ECFG_0_LOW_WIDTH 1
`define CSR_ECFG_0_HIGH_WIDTH 19

`define CSR_ESTAT 14'h0005
`define CSR_ESTAT_IS_1_0 1:0
`define CSR_ESTAT_IS_9_2 9:2
`define CSR_ESTAT_0_LOW 10
`define CSR_ESTAT_IS_11 11
`define CSR_ESTAT_IS_12 12
`define CSR_ESTAT_0_MID 15:13
`define CSR_ESTAT_ECODE 21:16
`define CSR_ESTAT_ESUBCODE 30:22
`define CSR_ESTAT_0_HIGH 31
`define CSR_ESTAT_0_LOW_WIDTH 1
`define CSR_ESTAT_0_MID_WIDTH 3
`define CSR_ESTAT_0_HIGH_WIDTH 1

`define ECODE_WIDTH 6
`define ECODE_INT 6'h00
`define ECODE_ADEF 6'h08
`define ECODE_ALE 6'h09
`define ECODE_SYS 6'h0b
`define ECODE_BRK 6'h0c
`define ECODE_INE 6'h0d

`define ESUBCODE_WIDTH 9
`define ESUBCODE_INT 9'h000
`define ESUBCODE_ADEF 9'h000
`define ESUBCODE_ALE 9'h000
`define ESUBCODE_SYS 9'h000
`define ESUBCODE_BRK 9'h000
`define ESUBCODE_INE 9'h000

`define CSR_ERA 14'h0006
`define CSR_ERA_PC 31:0

`define CSR_BADV 14'h0007
`define CSR_BADV_VADDR 31:0

`define CSR_EENTRY 14'h000c
`define CSR_EENTRY_0 5:0
`define CSR_EENTRY_VA 31:6
`define CSR_EENTRY_0_WIDTH 6

`define CSR_CPUID 14'h0020
`define CSR_CPUID_COREID 8:0
`define CSR_CPUID_0 31:9
`define CSR_CPUID_0_WIDTH 23

`define COREID_WIDTH 9
`define COREID 9'b0

`define CSR_SAVE0 14'h0030
`define CSR_SAVE1 14'h0031
`define CSR_SAVE2 14'h0032
`define CSR_SAVE3 14'h0033
`define CSR_SAVE_DATA 31:0

`define CSR_TID 14'h0040
`define CSR_TID_TID 31:0

`define CSR_TCFG 14'h0041
`define CSR_TCFG_EN 0
`define CSR_TCFG_PERIODIC 1
`define CSR_TCFG_INITVAL 31:2

`define CSR_TVAL 14'h0042
`define CSR_TVAL_TVAL 31:0
`define CSR_TVAL_TVAL_WIDTH 32
`define CSR_TVAL_TVAL_INIT 32'hffffffff

`define CSR_TICLR 14'h0044
`define CSR_TICLR_CLR 0
`define CSR_TICLR_0 31:1
`define CSR_TICLR_0_WIDTH 31

`define ADD_W_31_26 6'b000000
`define ADD_W_25_24 2'b00
`define ADD_W_23_22 2'b00
`define ADD_W_21_20 2'b01
`define ADD_W_19_15 5'b00000

`define SUB_W_31_26 6'b000000
`define SUB_W_25_24 2'b00
`define SUB_W_23_22 2'b00
`define SUB_W_21_20 2'b01
`define SUB_W_19_15 5'b00010

`define SLT_31_26 6'b000000
`define SLT_25_24 2'b00
`define SLT_23_22 2'b00
`define SLT_21_20 2'b01
`define SLT_19_15 5'b00100

`define SLTU_31_26 6'b000000
`define SLTU_25_24 2'b00
`define SLTU_23_22 2'b00
`define SLTU_21_20 2'b01
`define SLTU_19_15 5'b00101

`define NOR_31_26 6'b000000
`define NOR_25_24 2'b00
`define NOR_23_22 2'b00
`define NOR_21_20 2'b01
`define NOR_19_15 5'b01000

`define AND_31_26 6'b000000
`define AND_25_24 2'b00
`define AND_23_22 2'b00
`define AND_21_20 2'b01
`define AND_19_15 5'b01001

`define OR_31_26 6'b000000
`define OR_25_24 2'b00
`define OR_23_22 2'b00
`define OR_21_20 2'b01
`define OR_19_15 5'b01010

`define XOR_31_26 6'b000000
`define XOR_25_24 2'b00
`define XOR_23_22 2'b00
`define XOR_21_20 2'b01
`define XOR_19_15 5'b01011

`define SLL_W_31_26 6'b000000
`define SLL_W_25_24 2'b00
`define SLL_W_23_22 2'b00
`define SLL_W_21_20 2'b01
`define SLL_W_19_15 5'b01110

`define SRL_W_31_26 6'b000000
`define SRL_W_25_24 2'b00
`define SRL_W_23_22 2'b00
`define SRL_W_21_20 2'b01
`define SRL_W_19_15 5'b01111

`define SRA_W_31_26 6'b000000
`define SRA_W_25_24 2'b00
`define SRA_W_23_22 2'b00
`define SRA_W_21_20 2'b01
`define SRA_W_19_15 5'b10000

`define MUL_W_31_26 6'b000000
`define MUL_W_25_24 2'b00
`define MUL_W_23_22 2'b00
`define MUL_W_21_20 2'b01
`define MUL_W_19_15 5'b11000

`define MULH_W_31_26 6'b000000
`define MULH_W_25_24 2'b00
`define MULH_W_23_22 2'b00
`define MULH_W_21_20 2'b01
`define MULH_W_19_15 5'b11001

`define MULHU_WU_31_26 6'b000000
`define MULHU_WU_25_24 2'b00
`define MULHU_WU_23_22 2'b00
`define MULHU_WU_21_20 2'b01
`define MULHU_WU_19_15 5'b11010

`define DIV_W_31_26 6'b000000
`define DIV_W_25_24 2'b00
`define DIV_W_23_22 2'b00
`define DIV_W_21_20 2'b10
`define DIV_W_19_15 5'b00000

`define MOD_W_31_26 6'b000000
`define MOD_W_25_24 2'b00
`define MOD_W_23_22 2'b00
`define MOD_W_21_20 2'b10
`define MOD_W_19_15 5'b00001

`define DIV_WU_31_26 6'b000000
`define DIV_WU_25_24 2'b00
`define DIV_WU_23_22 2'b00
`define DIV_WU_21_20 2'b10
`define DIV_WU_19_15 5'b00010

`define MOD_WU_31_26 6'b000000
`define MOD_WU_25_24 2'b00
`define MOD_WU_23_22 2'b00
`define MOD_WU_21_20 2'b10
`define MOD_WU_19_15 5'b00011

`define BREAK_31_26 6'b000000
`define BREAK_25_24 2'b00
`define BREAK_23_22 2'b00
`define BREAK_21_20 2'b10
`define BREAK_19_15 5'b10100

`define SYSCALL_31_26 6'b000000
`define SYSCALL_25_24 2'b00
`define SYSCALL_23_22 2'b00
`define SYSCALL_21_20 2'b10
`define SYSCALL_19_15 5'b10110

`define SLLI_W_31_26 6'b000000
`define SLLI_W_25_24 2'b00
`define SLLI_W_23_22 2'b01
`define SLLI_W_21_20 2'b00
`define SLLI_W_19_15 5'b00001

`define SRLI_W_31_26 6'b000000
`define SRLI_W_25_24 2'b00
`define SRLI_W_23_22 2'b01
`define SRLI_W_21_20 2'b00
`define SRLI_W_19_15 5'b01001

`define SRAI_W_31_26 6'b000000
`define SRAI_W_25_24 2'b00
`define SRAI_W_23_22 2'b01
`define SRAI_W_21_20 2'b00
`define SRAI_W_19_15 5'b10001

`define SLTI_31_26 6'b000000
`define SLTI_25_24 2'b10
`define SLTI_23_22 2'b00

`define SLTUI_31_26 6'b000000
`define SLTUI_25_24 2'b10
`define SLTUI_23_22 2'b01

`define ADDI_W_31_26 6'b000000
`define ADDI_W_25_24 2'b10
`define ADDI_W_23_22 2'b10

`define ANDI_31_26 6'b000000
`define ANDI_25_24 2'b11
`define ANDI_23_22 2'b01

`define ORI_31_26 6'b000000
`define ORI_25_24 2'b11
`define ORI_23_22 2'b10

`define XORI_31_26 6'b000000
`define XORI_25_24 2'b11
`define XORI_23_22 2'b11

`define CSRRD_31_26 6'b000001
`define CSRRD_25_24 2'b00
`define CSRRD_9_5 5'b00000

`define CSRWR_31_26 6'b000001
`define CSRWR_25_24 2'b00
`define CSRWR_9_5 5'b00001

`define CSRXCHG_31_26 6'b000001
`define CSRXCHG_25_24 2'b00
`define CSRXCHG_9_5

`define ERTN_31_26 6'b000001
`define ERTN_25_24 2'b10
`define ERTN_23_22 2'b01
`define ERTN_21_20 2'b00
`define ERTN_19_15 5'b10000
`define ERTN_14_10 5'b01110
`define ERTN_9_5 5'b00000
`define ERTN_4_0 5'b00000

`define LU12I_W_31_26 6'b000101
`define LU12I_W_25 1'b0

`define PCADDU12I_31_26 6'b000111
`define PCADDU12I_25 1'b0

`define LD_B_31_26 6'b001010
`define LD_B_25_24 2'b00
`define LD_B_23_22 2'b00

`define LD_H_31_26 6'b001010
`define LD_H_25_24 2'b00
`define LD_H_23_22 2'b01

`define LD_W_31_26 6'b001010
`define LD_W_25_24 2'b00
`define LD_W_23_22 2'b10

`define ST_B_31_26 6'b001010
`define ST_B_25_24 2'b01
`define ST_B_23_22 2'b00

`define ST_H_31_26 6'b001010
`define ST_H_25_24 2'b01
`define ST_H_23_22 2'b01

`define ST_W_31_26 6'b001010
`define ST_W_25_24 2'b01
`define ST_W_23_22 2'b10

`define LD_BU_31_26 6'b001010
`define LD_BU_25_24 2'b10
`define LD_BU_23_22 2'b00

`define LD_HU_31_26 6'b001010
`define LD_HU_25_24 2'b10
`define LD_HU_23_22 2'b01

`define JIRL_31_26 6'b010011

`define B_31_26 6'b010100

`define BL_31_26 6'b010101

`define BEQ_31_26 6'b010110

`define BNE_31_26 6'b010111

`define BLT_31_26 6'b011000

`define BGE_31_26 6'b011001

`define BLTU_31_26 6'b011010

`define BGEU_31_26 6'b011011

`endif
