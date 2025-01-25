`ifndef MACROS_VH
`define MACROS_VH

`default_nettype none

//trick: to make next PC be 0x1c000000 during reset
`define PC_INIT (32'h1c000000 - 32'h4)

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

// default : ui12
// ui5 = ui12[4:0]
// si20 is used to lui12iw
`define IMM_SRC_WIDTH 4
`define IMM_SRC_4 0
`define IMM_SRC_SI12 1
`define IMM_SRC_SI14 2
`define IMM_SRC_SI20 3

// default : offs21
`define OFFS_SRC_WIDTH 2
`define OFFS_SRC_16 0
`define OFFS_SRC_26 1

`define BRANCH_WIDTH 4
`define BRANCH_UNCOND 0
`define BRANCH_EQ 1
`define BRANCH_LT 2
`define BRANCH_LTU 3

`define ALU_OP_WIDTH 12
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
/*
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
*/
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

`define ADDI_W_31_26 6'b000000
`define ADDI_W_25_24 2'b10
`define ADDI_W_23_22 2'b10

`define LU12I_W_31_26 6'b000101
`define LU12I_W_25 1'b0

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
