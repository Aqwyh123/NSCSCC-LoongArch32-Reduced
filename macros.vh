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

`define MEM_READ_EXT_WIDTH 4
`define MEM_READ_EXT_BYTE 0
`define MEM_READ_EXT_HALF 1
`define MEM_READ_EXT_BYTEU 2
`define MEM_READ_EXT_HALFU 3

`define MEM_WRITE_EXT_WIDTH 2
`define MEM_WRITE_EXT_BYTE 0
`define MEM_WRITE_EXT_HALF 1

`define GPR_USE_WIDTH 2
`define GPR_USE_ID 0
`define GPR_USE_EXE 1

`define GPR_NEW_WIDTH 4
`define GPR_NEW_ID 0
`define GPR_NEW_EXE 1
`define GPR_NEW_MEM 2
`define GPR_NEW_WB 3

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

`define LU12I_W_31_26 6'b000101
`define LU12I_W_25 1'b0

`define PCADDU12I_31_26 6'b000111
`define PCADDU12I_25 1'b0

`define LD_W_31_26 6'b001010
`define LD_W_25_24 2'b00
`define LD_W_23_22 2'b10

`define ST_W_31_26 6'b001010
`define ST_W_25_24 2'b01
`define ST_W_23_22 2'b10

`define JIRL_31_26 6'b010011

`define B_31_26 6'b010100

`define BL_31_26 6'b010101

`define BEQ_31_26 6'b010110

`define BNE_31_26 6'b010111

`endif
