`include "../macros.vh"

module ALU (
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     valid,
    input  wire [`ALU_OP_WIDTH-1:0] operation,
    input  wire [             31:0] operand1,
    input  wire [             31:0] operand2,
    output wire [             31:0] result,
    output wire                     done,
    output wire [             31:0] MEM_addr
);
    wire        op_add = operation[`ALU_OP_ADD];  //add operation
    wire        op_sub = operation[`ALU_OP_SUB];  //sub operation
    wire        op_slt = operation[`ALU_OP_SLT];  //signed compared and set less than
    wire        op_sltu = operation[`ALU_OP_SLTU];  //unsigned compared and set less than
    wire        op_and = operation[`ALU_OP_AND];  //bitwise and
    wire        op_nor = operation[`ALU_OP_NOR];  //bitwise nor
    wire        op_or = operation[`ALU_OP_OR];  //bitwise or
    wire        op_xor = operation[`ALU_OP_XOR];  //bitwise xor
    wire        op_sll = operation[`ALU_OP_SLL];  //logic left shift
    wire        op_srl = operation[`ALU_OP_SRL];  //logic right shift
    wire        op_sra = operation[`ALU_OP_SRA];  //arithmetic right shift
    wire        op_lui = operation[`ALU_OP_LUI];  //load upper immediate
    wire        op_mul_lo = operation[`ALU_OP_MUL_LO];  //multiply operation
    wire        op_mul_hi = operation[`ALU_OP_MUL_HI];  //multiply operation
    wire        op_mulu_hi = operation[`ALU_OP_MULU_HI];  //unsigned multiply operation
    wire        op_div = operation[`ALU_OP_DIV];  //divide operation
    wire        op_mod = operation[`ALU_OP_MOD];  //mod operation
    wire        op_divu = operation[`ALU_OP_DIVU];  //unsigned divide operation
    wire        op_modu = operation[`ALU_OP_MODU];  //unsigned mod operation

    wire [31:0] add_sub_result;
    wire [31:0] slt_result;
    wire [31:0] sltu_result;
    wire [31:0] and_result;
    wire [31:0] nor_result;
    wire [31:0] or_result;
    wire [31:0] xor_result;
    wire [31:0] sll_result;
    wire [31:0] sr_result;
    wire [31:0] lui_result;
    wire [31:0] mul_lo_result;
    wire [31:0] mul_hi_result;
    wire [31:0] div_result;
    wire [31:0] mod_result;

    // ADD, SUB
    // a - b == a + ~b + 1
    // slt/sltu -> sub
    wire [31:0] adder_operand1 = operand1;
    wire [31:0] adder_operand2 = (op_sub | op_slt | op_sltu) ? ~operand2 : operand2;
    wire        adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1 : 1'b0;
    wire [31:0] adder_result;
    wire        adder_cout;
    adder #(
        .WIDTH(32)
    ) adder_32 (
        .addend1(adder_operand1),
        .addend2(adder_operand2),
        .cin    (adder_cin),
        .sum    (adder_result),
        .cout   (adder_cout)
    );
    assign add_sub_result = adder_result;

    // SLT
    // operand1 < 0, operand2 >= 0 -> result = 1
    // sgn(operand1) = sgn(operand2), operand1 - operand2 < 0 -> result = 1
    assign slt_result[31:1] = 31'b0;
    assign slt_result[0]    = (operand1[31] & ~operand2[31])
                            | ((operand1[31] ~^ operand2[31]) & adder_result[31]);

    // SLTU
    // operand1 - operand2 overflow -> result = 0
    assign sltu_result[31:1] = 31'b0;
    assign sltu_result[0] = ~adder_cout;

    // bitwise operation
    assign and_result = operand1 & operand2;
    assign or_result = operand1 | operand2;
    assign nor_result = ~or_result;
    assign xor_result = operand1 ^ operand2;
    assign lui_result = operand2;

    // SLL
    assign sll_result = operand1 << operand2[4:0];

    // SRL, SRA
    right_shifter #(
        .WIDTH      (32),
        .SHAMT_WIDTH(5)
    ) right_shifter_32 (
        .operand   (operand1),
        .shamt     (operand2[4:0]),
        .arithmetic(op_sra),
        .result    (sr_result)
    );

    // MUL, MULH, MULHU
    multiplier mul (
        .mul_signed(op_mul_lo | op_mul_hi),
        .operand1  (operand1),
        .operand2  (operand2),
        .result    ({mul_hi_result, mul_lo_result})
    );

    // DIV, MOD, DIVU, MODU
    wire div_done;
    divider div (
        .clk       (clk),
        .reset     (reset),
        .start     (valid & (op_div | op_mod | op_divu | op_modu)),
        .div_signed(op_div | op_mod),
        .dividend  (operand1),
        .divisor   (operand2),
        .quotient  (div_result),
        .remainder (mod_result),
        .done      (div_done)
    );

    assign done = op_div | op_mod | op_divu | op_modu ? div_done : 1'b1;

    assign result = ({32{op_add|op_sub       }} & add_sub_result)
                  | ({32{op_slt              }} & slt_result)
                  | ({32{op_sltu             }} & sltu_result)
                  | ({32{op_and              }} & and_result)
                  | ({32{op_nor              }} & nor_result)
                  | ({32{op_or               }} & or_result)
                  | ({32{op_xor              }} & xor_result)
                  | ({32{op_sll              }} & sll_result)
                  | ({32{op_srl|op_sra       }} & sr_result)
                  | ({32{op_lui              }} & lui_result)
                  | ({32{op_mul_lo           }} & mul_lo_result)
                  | ({32{op_mul_hi|op_mulu_hi}} & mul_hi_result)
                  | ({32{op_div|op_divu      }} & div_result)
                  | ({32{op_mod|op_modu      }} & mod_result);

    assign MEM_addr = add_sub_result;
endmodule

