`include "macros.vh"

module mycpu_top (
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_req,
    output wire        inst_sram_wr,
    output wire [ 1:0] inst_sram_size,
    output wire [31:0] inst_sram_addr,
    output wire [ 3:0] inst_sram_wstrb,
    output wire [31:0] inst_sram_wdata,
    input  wire        inst_sram_addr_ok,
    input  wire        inst_sram_data_ok,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_req,
    output wire        data_sram_wr,
    output wire [ 1:0] data_sram_size,
    output wire [31:0] data_sram_addr,
    output wire [ 3:0] data_sram_wstrb,
    output wire [31:0] data_sram_wdata,
    input  wire        data_sram_addr_ok,
    input  wire        data_sram_data_ok,
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    reg reset;
    always @(posedge clk) begin
        reset <= ~resetn;
    end

    wire [                    31:0] PC;
    wire [    `EXCEPTION_WIDTH-1:0] exception;
    wire                            __return;
    wire [                    31:0] entry;
    wire [                    31:0] raddr;

    wire [                    31:0] pre_IF_PC;
    wire                            pre_IF_to_IF_valid;

    wire                            IF_done;
    wire                            IF_valid;
    wire                            IF_ready;
    wire                            IF_to_ID_valid;

    wire [                    31:0] IF_PC;
    wire [                    31:0] IF_inst;
    // wire [    `EXCEPTION_WIDTH-1:0] IF_exception;
    wire                            IF_ADEF;

    wire                            ID_done;
    wire                            ID_valid;
    wire                            ID_ready;
    wire                            ID_to_EXE_valid;

    wire [                    31:0] ID_PC;
    wire [                    31:0] ID_inst;
    // wire [    `EXCEPTION_WIDTH-1:0] ID_exception;
    wire                            ID_return;
    wire                            ID_irq;
    wire                            ID_INT;
    wire                            ID_ADEF;
    wire                            ID_SYS;
    wire                            ID_BRK;
    wire                            ID_INE;

    wire                            ID_stall;
    wire                            ID_bj_stall;
    wire                            ID_MEM_GPR1_A;
    wire                            ID_MEM_GPR2_A;
    wire                            ID_MEM_GPR1_T;
    wire                            ID_MEM_GPR2_T;
    wire                            ID_EXE_GPR1_A;
    wire                            ID_EXE_GPR2_A;
    wire                            ID_EXE_GPR1_T;
    wire                            ID_EXE_GPR2_T;
    wire                            ID_EXE_CSR_1;
    wire                            ID_MEM_CSR_1;
    wire                            ID_WB_CSR_1;
    wire                            ID_EXE_CSR_2;
    wire                            ID_MEM_CSR_2;
    wire                            ID_WB_CSR_2;
    wire                            ID_EXE_CSR_3;
    wire                            ID_MEM_CSR_3;
    wire                            ID_WB_CSR_3;

    wire                            ID_GPR1_use;
    wire                            ID_GPR2_use;
    wire [                     4:0] ID_GPR_read_num1;
    wire [                     4:0] ID_GPR_read_num2;
    wire [                    31:0] ID_GPR_read_data1;
    wire [                    31:0] ID_GPR_read_data2;
    wire [                    31:0] ID_rj_data;
    wire [                    31:0] ID_rkd_data;
    wire [      `GPR_NEW_WIDTH-1:0] ID_GPR_new;
    wire                            ID_GPR_write;
    wire [                     4:0] ID_GPR_write_num;
    wire [`GPR_WRITE_SRC_WIDTH-1:0] ID_GPR_write_src;
    wire [                    31:0] ID_link;
    wire [                    31:0] ID_imm;
    wire [                    31:0] ID_CNT_data;

    wire [   `CSR_NUMBER_WIDTH-1:0] ID_CSR_number;
    wire                            ID_CSR_write;
    wire [                    31:0] ID_CSR_write_mask;

    wire                            ID_jump;
    wire [       `BRANCH_WIDTH-1:0] ID_branch;
    wire                            ID_bj_taken;
    wire [                    31:0] ID_target_PC;
    wire                            ID_ALU_src1_is_PC;
    wire                            ID_ALU_src2_is_imm;
    wire [       `ALU_OP_WIDTH-1:0] ID_ALU_operation;
    wire [     `MEM_READ_WIDTH-1:0] ID_MEM_read;
    wire [    `MEM_WRITE_WIDTH-1:0] ID_MEM_write;

    wire                            EXE_done;
    wire                            EXE_valid;
    wire                            EXE_ready;
    wire                            EXE_to_MEM_valid;

    wire [                    31:0] EXE_PC;
    wire [    `EXCEPTION_WIDTH-1:0] EXE_exception;
    wire                            EXE_return;
    wire                            EXE_INT;
    wire                            EXE_ADEF;
    wire                            EXE_ALE;
    wire                            EXE_SYS;
    wire                            EXE_BRK;
    wire                            EXE_INE;

    wire [                    31:0] EXE_rj_data;
    wire [                    31:0] EXE_rkd_data;
    wire [      `GPR_NEW_WIDTH-1:0] EXE_GPR_new;
    wire                            EXE_GPR_write;
    wire [                     4:0] EXE_GPR_write_num;
    wire [`GPR_WRITE_SRC_WIDTH-1:0] EXE_GPR_write_src;
    wire [                    31:0] EXE_link;
    wire [                    31:0] EXE_imm;
    wire [                    31:0] EXE_CNT_data;
    wire [                    31:0] EXE_ALU_result;
    wire [                    31:0] EXE_forward_data;

    wire [   `CSR_NUMBER_WIDTH-1:0] EXE_CSR_number;
    wire                            EXE_CSR_write;
    wire [                    31:0] EXE_CSR_write_mask;

    wire                            EXE_ALU_src1_is_PC;
    wire                            EXE_ALU_src2_is_imm;
    wire [       `ALU_OP_WIDTH-1:0] EXE_ALU_operation;
    wire [     `MEM_READ_WIDTH-1:0] EXE_MEM_read;
    wire [    `MEM_WRITE_WIDTH-1:0] EXE_MEM_write;
    wire [                    31:0] EXE_MEM_addr;

    wire                            MEM_done;
    wire                            MEM_valid;
    wire                            MEM_ready;
    wire                            MEM_to_WB_valid;

    wire [                    31:0] MEM_PC;
    wire [    `EXCEPTION_WIDTH-1:0] MEM_exception;
    wire                            MEM_return;
    wire                            MEM_INT;
    wire                            MEM_ADEF;
    wire                            MEM_ALE;
    wire                            MEM_SYS;
    wire                            MEM_BRK;
    wire                            MEM_INE;

    wire [                    31:0] MEM_rd_data;
    wire [      `GPR_NEW_WIDTH-1:0] MEM_GPR_new;
    wire                            MEM_GPR_write;
    wire [                     4:0] MEM_GPR_write_num;
    wire [`GPR_WRITE_SRC_WIDTH-1:0] MEM_GPR_write_src;
    wire [                    31:0] MEM_CNT_data;
    wire [                    31:0] MEM_ALU_result;
    wire [                    31:0] MEM_MEM_result;
    wire [                    31:0] MEM_forward_data;

    wire [   `CSR_NUMBER_WIDTH-1:0] MEM_CSR_number;
    wire                            MEM_CSR_write;
    wire [                    31:0] MEM_CSR_write_mask;

    wire [     `MEM_READ_WIDTH-1:0] MEM_MEM_read;
    wire [    `MEM_WRITE_WIDTH-1:0] MEM_MEM_write;
    wire [                    31:0] MEM_MEM_addr;

    wire                            WB_done;
    wire                            WB_valid;
    wire                            WB_ready;

    wire [                    31:0] WB_PC;
    wire [    `EXCEPTION_WIDTH-1:0] WB_exception;
    wire                            WB_return;
    wire                            WB_INT;
    wire                            WB_ADEF;
    wire                            WB_ALE;
    wire                            WB_SYS;
    wire                            WB_BRK;
    wire                            WB_INE;

    wire [                    31:0] WB_rd_data;
    wire                            WB_GPR_write;
    wire                            WB_GPR_write_enable;
    wire [                     4:0] WB_GPR_write_num;
    wire [`GPR_WRITE_SRC_WIDTH-1:0] WB_GPR_write_src;
    wire [                    31:0] WB_GPR_write_data;
    wire [                    31:0] WB_CNT_data;
    wire [                    31:0] WB_ALU_result;
    wire [                    31:0] WB_MEM_result;
    // wire [                31:0] WB_forward_data;

    wire [   `CSR_NUMBER_WIDTH-1:0] WB_CSR_number;
    wire [                    31:0] WB_CSR_read_data;
    wire [                    31:0] WB_CSR_write_mask;
    wire                            WB_CSR_write;
    wire                            WB_CSR_write_enable;
    wire [                    31:0] WB_CSR_write_data;

    wire [                    31:0] WB_MEM_addr;

    IF_reg if_reg (
        .clk               (clk),
        .reset             (reset),
        .exception         (|exception),
        .__return          (__return),
        .bj_taken          (ID_bj_taken),
        .entry             (entry),
        .raddr             (raddr),
        .target            (ID_target_PC),
        .IF_done           (IF_done),
        .ID_ready          (ID_ready),
        .pre_IF_to_IF_valid(pre_IF_to_IF_valid),
        .IF_valid          (IF_valid),
        .IF_ready          (IF_ready),
        .IF_to_ID_valid    (IF_to_ID_valid),
        .pre_IF_PC         (pre_IF_PC),
        .IF_PC             (IF_PC)
    );

    IF_stage if_stage (
        .clk               (clk),
        .reset             (reset),
        .flush             (|exception | __returnn | ID_bj_taken),
        .IF_valid          (IF_valid),
        .IF_ready          (IF_ready),
        .ID_ready          (ID_ready),
        .pre_IF_to_IF_valid(pre_IF_to_IF_valid),
        .IF_done           (IF_done),
        .inst_sram_req     (inst_sram_req),
        .inst_sram_wr      (inst_sram_wr),
        .inst_sram_size    (inst_sram_size),
        .inst_sram_addr    (inst_sram_addr),
        .inst_sram_wstrb   (inst_sram_wstrb),
        .inst_sram_wdata   (inst_sram_wdata),
        .inst_sram_addr_ok (inst_sram_addr_ok),
        .inst_sram_data_ok (inst_sram_data_ok),
        .inst_sram_rdata   (inst_sram_rdata),
        .PC                (IF_PC),
        .pre_IF_PC         (pre_IF_PC),
        .inst              (IF_inst),
        .ADEF              (IF_ADEF)
    );

    // assign IF_exception = {9'b0, IF_ADEF, 6'b0};

    ID_reg id_reg (
        .clk            (clk),
        .reset          (reset),
        .flush          (|exception | __return),
        .ID_done        (ID_done),
        .EXE_ready      (EXE_ready),
        .IF_to_ID_valid (IF_to_ID_valid),
        .ID_valid       (ID_valid),
        .ID_ready       (ID_ready),
        .ID_to_EXE_valid(ID_to_EXE_valid),
        .IF_PC          (IF_PC),
        .IF_inst        (IF_inst),
        .IF_ADEF        (IF_ADEF),
        .ID_PC          (ID_PC),
        .ID_inst        (ID_inst),
        .ID_ADEF        (ID_ADEF)
    );

    ID_stage id_stage (
        .clk            (clk),
        .reset          (reset),
        .valid          (ID_valid),
        .bj_stall       (ID_bj_stall),
        .inst           (ID_inst),
        .jump           (ID_jump),
        .branch         (ID_branch),
        .PC             (ID_PC),
        .GPR_read_num1  (ID_GPR_read_num1),
        .rj_data        (ID_rj_data),
        .GPR_read_num2  (ID_GPR_read_num2),
        .rkd_data       (ID_rkd_data),
        .CNT_data       (ID_CNT_data),
        .ALU_src1_is_PC (ID_ALU_src1_is_PC),
        .ALU_src2_is_imm(ID_ALU_src2_is_imm),
        .ALU_operation  (ID_ALU_operation),
        .MEM_read       (ID_MEM_read),
        .MEM_write      (ID_MEM_write),
        .GPR_write      (ID_GPR_write),
        .GPR_write_num  (ID_GPR_write_num),
        .GPR_write_src  (ID_GPR_write_src),
        .CSR_number     (ID_CSR_number),
        .CSR_write      (ID_CSR_write),
        .CSR_write_mask (ID_CSR_write_mask),
        .GPR1_use       (ID_GPR1_use),
        .GPR2_use       (ID_GPR2_use),
        .GPR_new        (ID_GPR_new),
        .bj_taken       (ID_bj_taken),
        .target_PC      (ID_target_PC),
        .imm            (ID_imm),
        .link           (ID_link),
        .__return       (ID_return),
        .SYS            (ID_SYS),
        .BRK            (ID_BRK),
        .INE            (ID_INE)
    );

    GPRF gpr_file (
        .clk         (clk),
        .read_num1   (ID_GPR_read_num1),
        .read_data1  (ID_GPR_read_data1),
        .read_num2   (ID_GPR_read_num2),
        .read_data2  (ID_GPR_read_data2),
        .write_enable(WB_GPR_write_enable),
        .write_num   (WB_GPR_write_num),
        .write_data  (WB_GPR_write_data)
    );

    assign ID_rj_data = EXE_valid & ID_EXE_GPR1_A & EXE_GPR_new[`GPR_NEW_EXE] ? EXE_forward_data :
                        MEM_valid & ID_MEM_GPR1_A & |MEM_GPR_new[`GPR_NEW_MEM:`GPR_NEW_EXE] ?
                        MEM_forward_data : ID_GPR_read_data1;
    assign ID_rkd_data = EXE_valid & ID_EXE_GPR2_A & EXE_GPR_new[`GPR_NEW_EXE] ? EXE_forward_data :
                         MEM_valid & ID_MEM_GPR2_A & |MEM_GPR_new[`GPR_NEW_MEM:`GPR_NEW_EXE] ?
                         MEM_forward_data : ID_GPR_read_data2;

    assign ID_INT = ID_irq & ~(EXE_valid & (ID_EXE_CSR_1 | ID_EXE_CSR_2 | ID_EXE_CSR_3) |
                               MEM_valid & (ID_MEM_CSR_1 | ID_MEM_CSR_2 | ID_MEM_CSR_3) |
                               WB_valid & (ID_WB_CSR_1 | ID_WB_CSR_2 | ID_WB_CSR_3));

    // assign ID_exception = {4'b0, ID_INE, ID_BRK, ID_SYS, 2'b0, ID_ADEF, 5'b0, ID_INT};

    assign ID_EXE_GPR1_A = |EXE_GPR_write_num & EXE_GPR_write &
                            ID_GPR_read_num1 == EXE_GPR_write_num;
    assign ID_EXE_GPR2_A = |EXE_GPR_write_num & EXE_GPR_write &
                            ID_GPR_read_num2 == EXE_GPR_write_num;
    assign ID_MEM_GPR1_A = |MEM_GPR_write_num & MEM_GPR_write &
                            ID_GPR_read_num1 == MEM_GPR_write_num;
    assign ID_MEM_GPR2_A = |MEM_GPR_write_num & MEM_GPR_write &
                            ID_GPR_read_num2 == MEM_GPR_write_num;

    assign ID_EXE_GPR1_T = ID_GPR1_use & |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM];
    assign ID_EXE_GPR2_T = ID_GPR2_use & |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM];
    assign ID_MEM_GPR1_T = ID_GPR1_use & MEM_GPR_new[`GPR_NEW_WB];
    assign ID_MEM_GPR2_T = ID_GPR2_use & MEM_GPR_new[`GPR_NEW_WB];

    assign ID_EXE_CSR_1 = EXE_CSR_write &
                         (EXE_CSR_number == `CSR_CRMD & |EXE_CSR_write_mask[`CSR_CRMD_IE] |
                          EXE_CSR_number == `CSR_ECFG & |EXE_CSR_write_mask[`CSR_ECFG_LIE_9_0] |
                          EXE_CSR_number == `CSR_ECFG & |EXE_CSR_write_mask[`CSR_ECFG_LIE_12_11] |
                          EXE_CSR_number == `CSR_ESTAT & |EXE_CSR_write_mask[`CSR_ESTAT_IS_1_0] |
                          EXE_CSR_number == `CSR_TCFG & |EXE_CSR_write_mask[`CSR_TCFG_EN] |
                          EXE_CSR_number == `CSR_TICLR & |EXE_CSR_write_mask[`CSR_TICLR_CLR]);
    assign ID_MEM_CSR_1 = MEM_CSR_write &
                         (MEM_CSR_number == `CSR_CRMD & |MEM_CSR_write_mask[`CSR_CRMD_IE] |
                          MEM_CSR_number == `CSR_ECFG & |MEM_CSR_write_mask[`CSR_ECFG_LIE_9_0] |
                          MEM_CSR_number == `CSR_ECFG & |MEM_CSR_write_mask[`CSR_ECFG_LIE_12_11] |
                          MEM_CSR_number == `CSR_ESTAT & |MEM_CSR_write_mask[`CSR_ESTAT_IS_1_0] |
                          MEM_CSR_number == `CSR_TCFG & |MEM_CSR_write_mask[`CSR_TCFG_EN] |
                          MEM_CSR_number == `CSR_TICLR & |MEM_CSR_write_mask[`CSR_TICLR_CLR]);
    assign ID_WB_CSR_1  = WB_CSR_write &
                         (WB_CSR_number == `CSR_CRMD & |WB_CSR_write_mask[`CSR_CRMD_IE] |
                          WB_CSR_number == `CSR_ECFG & |WB_CSR_write_mask[`CSR_ECFG_LIE_9_0] |
                          WB_CSR_number == `CSR_ECFG & |WB_CSR_write_mask[`CSR_ECFG_LIE_12_11] |
                          WB_CSR_number == `CSR_ESTAT & |WB_CSR_write_mask[`CSR_ESTAT_IS_1_0] |
                          WB_CSR_number == `CSR_TCFG & |WB_CSR_write_mask[`CSR_TCFG_EN] |
                          WB_CSR_number == `CSR_TICLR & |WB_CSR_write_mask[`CSR_TICLR_CLR]);
    assign ID_EXE_CSR_2 = ID_return & EXE_CSR_write &
                         (EXE_CSR_number == `CSR_ERA & |EXE_CSR_write_mask[`CSR_ERA_PC] |
                          EXE_CSR_number == `CSR_PRMD & |EXE_CSR_write_mask[`CSR_PRMD_PPLV] |
                          EXE_CSR_number == `CSR_PRMD & |EXE_CSR_write_mask[`CSR_PRMD_PIE]);
    assign ID_MEM_CSR_2 = ID_return & MEM_CSR_write &
                         (MEM_CSR_number == `CSR_ERA & |MEM_CSR_write_mask[`CSR_ERA_PC] |
                          MEM_CSR_number == `CSR_PRMD & |MEM_CSR_write_mask[`CSR_PRMD_PPLV] |
                          MEM_CSR_number == `CSR_PRMD & |MEM_CSR_write_mask[`CSR_PRMD_PIE]);
    assign ID_WB_CSR_2  = ID_return & WB_CSR_write &
                         (WB_CSR_number == `CSR_ERA & |WB_CSR_write_mask[`CSR_ERA_PC] |
                          WB_CSR_number == `CSR_PRMD & |WB_CSR_write_mask[`CSR_PRMD_PPLV] |
                          WB_CSR_number == `CSR_PRMD & |WB_CSR_write_mask[`CSR_PRMD_PIE]);
    assign ID_EXE_CSR_3 = EXE_return;
    assign ID_MEM_CSR_3 = MEM_return;
    assign ID_WB_CSR_3 = WB_return;

    assign ID_bj_stall = ID_jump & (EXE_valid & ID_EXE_GPR1_A &
                        |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM] |
                         MEM_valid & ID_MEM_GPR1_A & MEM_GPR_new[`GPR_NEW_WB]) |
                        |ID_branch[`BRANCH_LTU:`BRANCH_EQ] &
                        (EXE_valid & (ID_EXE_GPR1_A | ID_EXE_GPR2_A) &
                        |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM] |
                         MEM_valid & (ID_MEM_GPR1_A | ID_MEM_GPR2_A) & MEM_GPR_new[`GPR_NEW_WB]);

    assign ID_stall = EXE_valid & (ID_EXE_GPR1_A & ID_EXE_GPR1_T | ID_EXE_GPR2_A & ID_EXE_GPR2_T |
                                   ID_EXE_CSR_1 | ID_EXE_CSR_2 | ID_EXE_CSR_3) |
                      MEM_valid & (ID_MEM_GPR1_A & ID_MEM_GPR1_T | ID_MEM_GPR2_A & ID_MEM_GPR2_T |
                                   ID_MEM_CSR_1 | ID_MEM_CSR_2 | ID_MEM_CSR_3) |
                      WB_valid & (ID_WB_CSR_1 | ID_WB_CSR_2 | ID_WB_CSR_3);

    assign ID_done = ~ID_stall;

    EXE_reg exe_reg (
        .clk                (clk),
        .reset              (reset),
        .flush              (|exception | __return),
        .EXE_done           (EXE_done),
        .MEM_ready          (MEM_ready),
        .ID_to_EXE_valid    (ID_to_EXE_valid),
        .EXE_valid          (EXE_valid),
        .EXE_ready          (EXE_ready),
        .EXE_to_MEM_valid   (EXE_to_MEM_valid),
        .ID_PC              (ID_PC),
        .ID_link            (ID_link),
        .ID_imm             (ID_imm),
        .ID_rj_data         (ID_rj_data),
        .ID_rkd_data        (ID_rkd_data),
        .ID_CNT_data        (ID_CNT_data),
        .ID_ALU_src1_is_PC  (ID_ALU_src1_is_PC),
        .ID_ALU_src2_is_imm (ID_ALU_src2_is_imm),
        .ID_ALU_operation   (ID_ALU_operation),
        .ID_MEM_read        (ID_MEM_read),
        .ID_MEM_write       (ID_MEM_write),
        .ID_GPR_write       (ID_GPR_write),
        .ID_GPR_write_num   (ID_GPR_write_num),
        .ID_GPR_write_src   (ID_GPR_write_src),
        .ID_CSR_number      (ID_CSR_number),
        .ID_CSR_write       (ID_CSR_write),
        .ID_CSR_write_mask  (ID_CSR_write_mask),
        .ID_return          (ID_return),
        .ID_GPR_new         (ID_GPR_new),
        .ID_INT             (ID_INT),
        .ID_ADEF            (ID_ADEF),
        .ID_SYS             (ID_SYS),
        .ID_BRK             (ID_BRK),
        .ID_INE             (ID_INE),
        .EXE_PC             (EXE_PC),
        .EXE_link           (EXE_link),
        .EXE_imm            (EXE_imm),
        .EXE_rj_data        (EXE_rj_data),
        .EXE_rkd_data       (EXE_rkd_data),
        .EXE_CNT_data       (EXE_CNT_data),
        .EXE_ALU_src1_is_PC (EXE_ALU_src1_is_PC),
        .EXE_ALU_src2_is_imm(EXE_ALU_src2_is_imm),
        .EXE_ALU_operation  (EXE_ALU_operation),
        .EXE_MEM_read       (EXE_MEM_read),
        .EXE_MEM_write      (EXE_MEM_write),
        .EXE_GPR_write      (EXE_GPR_write),
        .EXE_GPR_write_num  (EXE_GPR_write_num),
        .EXE_GPR_write_src  (EXE_GPR_write_src),
        .EXE_CSR_number     (EXE_CSR_number),
        .EXE_CSR_write      (EXE_CSR_write),
        .EXE_CSR_write_mask (EXE_CSR_write_mask),
        .EXE_return         (EXE_return),
        .EXE_GPR_new        (EXE_GPR_new),
        .EXE_INT            (EXE_INT),
        .EXE_ADEF           (EXE_ADEF),
        .EXE_SYS            (EXE_SYS),
        .EXE_BRK            (EXE_BRK),
        .EXE_INE            (EXE_INE)
    );

    EXE_stage exe_stage (
        .clk              (clk),
        .reset            (reset),
        .valid            (EXE_valid),
        .MEM_ready        (MEM_ready),
        .done             (EXE_done),
        .MEM_valid        (MEM_valid),
        .WB_valid         (WB_valid),
        .exception        (EXE_exception),
        .MEM_exception    (MEM_exception),
        .WB_exception     (WB_exception),
        .data_sram_req    (data_sram_req),
        .data_sram_wr     (data_sram_wr),
        .data_sram_size   (data_sram_size),
        .data_sram_addr   (data_sram_addr),
        .data_sram_wstrb  (data_sram_wstrb),
        .data_sram_wdata  (data_sram_wdata),
        .data_sram_addr_ok(data_sram_addr_ok),
        .PC               (EXE_PC),
        .imm              (EXE_imm),
        .rj_data          (EXE_rj_data),
        .rkd_data         (EXE_rkd_data),
        .ALU_src1_is_PC   (EXE_ALU_src1_is_PC),
        .ALU_src2_is_imm  (EXE_ALU_src2_is_imm),
        .ALU_operation    (EXE_ALU_operation),
        .MEM_read         (EXE_MEM_read),
        .MEM_write        (EXE_MEM_write),
        .ALU_result       (EXE_ALU_result),
        .MEM_addr         (EXE_MEM_addr),
        .ALE              (EXE_ALE)
    );

    assign EXE_exception = {
        4'b0, EXE_INE, EXE_BRK, EXE_SYS, EXE_ALE, 1'b0, EXE_ADEF, 5'b0, EXE_INT
    };

    assign EXE_forward_data = {32{EXE_GPR_write_src[`GPR_WRITE_SRC_LINK]}} & EXE_link |
                              {32{EXE_GPR_write_src[`GPR_WRITE_SRC_LUI]}} & EXE_imm |
                              {32{EXE_GPR_write_src[`GPR_WRITE_SRC_CNT]}} & EXE_CNT_data;

    MEM_reg mem_reg (
        .clk               (clk),
        .reset             (reset),
        .flush             (|exception | __return),
        .MEM_done          (MEM_done),
        .WB_ready          (WB_ready),
        .EXE_to_MEM_valid  (EXE_to_MEM_valid),
        .MEM_valid         (MEM_valid),
        .MEM_ready         (MEM_ready),
        .MEM_to_WB_valid   (MEM_to_WB_valid),
        .EXE_PC            (EXE_PC),
        .EXE_rd_data       (EXE_rkd_data),
        .EXE_CNT_data      (EXE_CNT_data),
        .EXE_ALU_result    (EXE_ALU_result),
        .EXE_MEM_read      (EXE_MEM_read),
        .EXE_MEM_write     (EXE_MEM_write),
        .EXE_MEM_addr      (EXE_MEM_addr),
        .EXE_GPR_write     (EXE_GPR_write),
        .EXE_GPR_write_num (EXE_GPR_write_num),
        .EXE_GPR_write_src (EXE_GPR_write_src),
        .EXE_CSR_number    (EXE_CSR_number),
        .EXE_CSR_write     (EXE_CSR_write),
        .EXE_CSR_write_mask(EXE_CSR_write_mask),
        .EXE_return        (EXE_return),
        .EXE_GPR_new       (EXE_GPR_new),
        .EXE_INT           (EXE_INT),
        .EXE_ADEF          (EXE_ADEF),
        .EXE_ALE           (EXE_ALE),
        .EXE_SYS           (EXE_SYS),
        .EXE_BRK           (EXE_BRK),
        .EXE_INE           (EXE_INE),
        .MEM_PC            (MEM_PC),
        .MEM_rd_data       (MEM_rd_data),
        .MEM_CNT_data      (MEM_CNT_data),
        .MEM_ALU_result    (MEM_ALU_result),
        .MEM_MEM_read      (MEM_MEM_read),
        .MEM_MEM_write     (MEM_MEM_write),
        .MEM_MEM_addr      (MEM_MEM_addr),
        .MEM_GPR_write     (MEM_GPR_write),
        .MEM_GPR_write_num (MEM_GPR_write_num),
        .MEM_GPR_write_src (MEM_GPR_write_src),
        .MEM_CSR_number    (MEM_CSR_number),
        .MEM_CSR_write     (MEM_CSR_write),
        .MEM_CSR_write_mask(MEM_CSR_write_mask),
        .MEM_return        (MEM_return),
        .MEM_GPR_new       (MEM_GPR_new),
        .MEM_INT           (MEM_INT),
        .MEM_ADEF          (MEM_ADEF),
        .MEM_ALE           (MEM_ALE),
        .MEM_SYS           (MEM_SYS),
        .MEM_BRK           (MEM_BRK),
        .MEM_INE           (MEM_INE)
    );

    MEM_stage mem_stage (
        .done             (MEM_done),
        .exception        (MEM_exception),
        .data_sram_data_ok(data_sram_data_ok),
        .data_sram_rdata  (data_sram_rdata),
        .MEM_read         (MEM_MEM_read),
        .MEM_write        (MEM_MEM_write),
        .MEM_addr_1_0     (MEM_MEM_addr[1:0]),
        .MEM_result       (MEM_MEM_result)
    );

    assign MEM_exception = {
        4'b0, MEM_INE, MEM_BRK, MEM_SYS, MEM_ALE, 1'b0, MEM_ADEF, 5'b0, MEM_INT
    };

    assign MEM_forward_data = {32{MEM_GPR_write_src[`GPR_WRITE_SRC_CNT]}} & MEM_CNT_data |
                              {32{MEM_GPR_write_src[`GPR_WRITE_SRC_ALU]}} & MEM_ALU_result;

    WB_reg wb_reg (
        .clk               (clk),
        .reset             (reset),
        .flush             (|exception | __return),
        .WB_done           (WB_done),
        .MEM_to_WB_valid   (MEM_to_WB_valid),
        .WB_valid          (WB_valid),
        .WB_ready          (WB_ready),
        .MEM_PC            (MEM_PC),
        .MEM_rd_data       (MEM_rd_data),
        .MEM_CNT_data      (MEM_CNT_data),
        .MEM_ALU_result    (MEM_ALU_result),
        .MEM_MEM_result    (MEM_MEM_result),
        .MEM_MEM_addr      (MEM_MEM_addr),
        .MEM_GPR_write     (MEM_GPR_write),
        .MEM_GPR_write_num (MEM_GPR_write_num),
        .MEM_GPR_write_src (MEM_GPR_write_src),
        .MEM_CSR_number    (MEM_CSR_number),
        .MEM_CSR_write     (MEM_CSR_write),
        .MEM_CSR_write_mask(MEM_CSR_write_mask),
        .MEM_return        (MEM_return),
        .MEM_INT           (MEM_INT),
        .MEM_ADEF          (MEM_ADEF),
        .MEM_ALE           (MEM_ALE),
        .MEM_SYS           (MEM_SYS),
        .MEM_BRK           (MEM_BRK),
        .MEM_INE           (MEM_INE),
        .WB_PC             (WB_PC),
        .WB_rd_data        (WB_rd_data),
        .WB_CNT_data       (WB_CNT_data),
        .WB_ALU_result     (WB_ALU_result),
        .WB_MEM_result     (WB_MEM_result),
        .WB_MEM_addr       (WB_MEM_addr),
        .WB_GPR_write      (WB_GPR_write),
        .WB_GPR_write_num  (WB_GPR_write_num),
        .WB_GPR_write_src  (WB_GPR_write_src),
        .WB_CSR_number     (WB_CSR_number),
        .WB_CSR_write      (WB_CSR_write),
        .WB_CSR_write_mask (WB_CSR_write_mask),
        .WB_return         (WB_return),
        .WB_INT            (WB_INT),
        .WB_ADEF           (WB_ADEF),
        .WB_ALE            (WB_ALE),
        .WB_SYS            (WB_SYS),
        .WB_BRK            (WB_BRK),
        .WB_INE            (WB_INE)
    );

    WB_stage wb_stage (
        .valid           (WB_valid),
        .done            (WB_done),
        .exception       (WB_exception),
        .CNT_data        (WB_CNT_data),
        .ALU_result      (WB_ALU_result),
        .MEM_result      (WB_MEM_result),
        .CSR_read_data   (WB_CSR_read_data),
        .GPR_write       (WB_GPR_write),
        .GPR_write_src   (WB_GPR_write_src),
        .CSR_write       (WB_CSR_write),
        .GPR_write_enable(WB_GPR_write_enable),
        .GPR_write_data  (WB_GPR_write_data),
        .CSR_write_enable(WB_CSR_write_enable)
    );

    assign WB_CSR_write_data = WB_rd_data;
    assign WB_exception      = {4'b0, WB_INE, WB_BRK, WB_SYS, WB_ALE, 1'b0, WB_ADEF, 5'b0, WB_INT};

    // assign WB_forward_data   = WB_GPR_write_data;

    assign debug_wb_pc       = WB_PC;
    assign debug_wb_rf_we    = {4{WB_GPR_write_enable}};
    assign debug_wb_rf_wnum  = WB_GPR_write_num;
    assign debug_wb_rf_wdata = WB_GPR_write_data;

    CSRF csr_file (
        .clk         (clk),
        .reset       (reset),
        .number      (WB_CSR_number),
        .write_enable(WB_CSR_write_enable),
        .write_mask  (WB_CSR_write_mask),
        .write_data  (WB_CSR_write_data),
        .read_data   (WB_CSR_read_data),
        .hw_int      (8'b0),
        .ip_int      (1'b0),
        .exception   (exception),
        .__return    (__return),
        .PC          (PC),
        .vaddr       (WB_MEM_addr),          // TODO: delay memory write
        .interupt    (ID_irq),
        .entry       (entry),
        .raddr       (raddr)
    );

    assign PC        = WB_PC;
    assign exception = {16{WB_valid}} & WB_exception;
    assign __return  = WB_valid & WB_return;
endmodule
