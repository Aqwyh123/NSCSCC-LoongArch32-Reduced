`include "pipelines/regs/IF_reg.v"
`include "pipelines/regs/ID_reg.v"
`include "pipelines/regs/EXE_reg.v"
`include "pipelines/regs/MEM_reg.v"
`include "pipelines/regs/WB_reg.v"
`include "pipelines/stages/IF_stage.v"
`include "pipelines/stages/ID_stage.v"
`include "pipelines/stages/EXE_stage.v"
`include "pipelines/stages/MEM_stage.v"
`include "pipelines/stages/WB_stage.v"
`include "components/regfile.v"

module mycpu_top (
    input  wire        clk,
    input  wire        resetn,
    // inst sram interface
    output wire        inst_sram_en,
    output wire [ 3:0] inst_sram_we,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    output wire        data_sram_en,
    output wire [ 3:0] data_sram_we,
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
    always @(posedge clk) begin
        reset <= ~resetn;
    end

    wire                            IF_busy;
    wire                            IF_valid;
    wire                            IF_ready;
    wire                            IF_to_ID_valid;

    wire [                    31:0] IF_PC;
    wire [                    31:0] IF_next_PC;
    wire [                    31:0] IF_seq_PC;
    wire [                    31:0] IF_inst;

    wire                            ID_busy;
    wire                            ID_valid;
    wire                            ID_ready;
    wire                            ID_to_EXE_valid;

    wire [                    31:0] ID_PC;
    wire [      `GPR_NEW_WIDTH-1:0] ID_GPR_new;
    wire [      `GPR_USE_WIDTH-1:0] ID_GPR1_use;
    wire [      `GPR_USE_WIDTH-1:0] ID_GPR2_use;
    wire [                     4:0] ID_GPR_read_num1;
    wire [                     4:0] ID_GPR_read_num2;
    wire [                    31:0] ID_GPR_read_data1;
    wire [                    31:0] ID_GPR_read_data2;
    wire [                    31:0] ID_rj_data;
    wire [                    31:0] ID_rkd_data;
    wire                            ID_GPR_write;
    wire [                     4:0] ID_GPR_write_num;
    wire                            ID_GPR_write_src_is_MEM;
    wire [                    31:0] ID_link;

    wire                            ID_MEM_GPR1_A;
    wire                            ID_MEM_GPR2_A;
    wire                            ID_MEM_GPR1_Ts;
    wire                            ID_MEM_GPR2_Ts;
    wire                            ID_EXE_GPR1_A;
    wire                            ID_EXE_GPR2_A;
    wire                            ID_EXE_GPR1_Ts;
    wire                            ID_EXE_GPR2_Ts;
    wire                            ID_MEM_Tf;
    wire                            ID_EXE_Tf;

    wire [                    31:0] ID_inst;
    wire                            ID_bj_taken;
    wire                            ID_bj_enable;
    wire [                    31:0] ID_target_PC;
    wire                            ID_ALU_src1_is_PC;
    wire                            ID_ALU_src2_is_imm;
    wire [       `ALU_OP_WIDTH-1:0] ID_ALU_operation;
    wire                            ID_MEM_read;
    wire [ `MEM_READ_EXT_WIDTH-1:0] ID_MEM_read_ext;
    wire                            ID_MEM_write;
    wire [`MEM_WRITE_EXT_WIDTH-1:0] ID_MEM_write_ext;
    wire [                    31:0] ID_imm;

    wire                            EXE_busy;
    wire                            EXE_valid;
    wire                            EXE_ready;
    wire                            EXE_to_MEM_valid;

    wire [                    31:0] EXE_PC;
    wire [      `GPR_NEW_WIDTH-1:0] EXE_GPR_new;
    wire [                     4:0] EXE_GPR_read_num1;
    wire [                     4:0] EXE_GPR_read_num2;
    wire [                    31:0] EXE_GPR_read_data1;
    wire [                    31:0] EXE_GPR_read_data2;
    wire [                    31:0] EXE_rj_data;
    wire [                    31:0] EXE_rkd_data;
    wire                            EXE_GPR_write;
    wire                            EXE_GPR_write_enable;
    wire [                     4:0] EXE_GPR_write_num;
    wire                            EXE_GPR_write_src_is_MEM;
    wire [                    31:0] EXE_link;
    wire [                    31:0] EXE_imm;
    wire [                    31:0] EXE_forward_data;

    wire                            EXE_MEM_GPR1_A;
    wire                            EXE_MEM_GPR2_A;
    wire                            EXE_WB_GPR1_A;
    wire                            EXE_WB_GPR2_A;
    wire                            EXE_MEM_Tf;
    wire                            EXE_WB_Tf;

    wire                            EXE_ALU_src1_is_PC;
    wire                            EXE_ALU_src2_is_imm;
    wire [       `ALU_OP_WIDTH-1:0] EXE_ALU_operation;
    wire                            EXE_MEM_read;
    wire [ `MEM_READ_EXT_WIDTH-1:0] EXE_MEM_read_ext;
    wire                            EXE_MEM_write;
    wire [`MEM_WRITE_EXT_WIDTH-1:0] EXE_MEM_write_ext;
    wire [                     3:0] EXE_MEM_write_enable;
    wire [                    31:0] EXE_MEM_addr;
    wire [                    31:0] EXE_MEM_write_data;
    wire [                    31:0] EXE_ALU_result;

    wire                            MEM_busy;
    wire                            MEM_valid;
    wire                            MEM_ready;
    wire                            MEM_to_WB_valid;

    wire [                    31:0] MEM_PC;
    wire [      `GPR_NEW_WIDTH-1:0] MEM_GPR_new;
    wire                            MEM_GPR_write;
    wire                            MEM_GPR_write_enable;
    wire [                     4:0] MEM_GPR_write_num;
    wire                            MEM_GPR_write_src_is_MEM;
    wire [                    31:0] MEM_ALU_result;
    wire [                    31:0] MEM_forward_data;

    wire [ `MEM_READ_EXT_WIDTH-1:0] MEM_MEM_read_ext;
    wire [                     1:0] MEM_MEM_addr_low;
    wire [                    31:0] MEM_MEM_read_data;
    wire [                    31:0] MEM_GPR_write_data;

    wire                            WB_busy;
    wire                            WB_valid;
    wire                            WB_ready;

    wire [                    31:0] WB_PC;
    wire [      `GPR_NEW_WIDTH-1:0] WB_GPR_new;
    wire                            WB_GPR_write;
    wire                            WB_GPR_write_enable;
    wire [                     4:0] WB_GPR_write_num;
    wire [                    31:0] WB_GPR_write_data;
    wire [                    31:0] WB_forward_data;

    IF_reg if_reg (
        .clk           (clk),
        .reset         (reset),
        .IF_busy       (IF_busy),
        .ID_ready      (ID_ready),
        .IF_valid      (IF_valid),
        .IF_ready      (IF_ready),
        .IF_to_ID_valid(IF_to_ID_valid),
        .ID_bj_enable  (ID_bj_enable),
        .IF_next_PC    (IF_next_PC),
        .IF_PC         (IF_PC)
    );

    IF_stage if_stage (
        .busy  (IF_busy),
        .PC    (IF_PC),
        .seq_PC(IF_seq_PC)
    );

    assign IF_next_PC      = ID_bj_enable ? ID_target_PC : IF_seq_PC;

    assign inst_sram_en    = ~reset & IF_ready;
    assign inst_sram_we    = 4'b0;
    assign inst_sram_addr  = IF_next_PC;
    assign inst_sram_wdata = 32'b0;
    assign IF_inst         = inst_sram_rdata;

    ID_reg id_reg (
        .clk            (clk),
        .reset          (reset),
        .ID_busy        (ID_busy),
        .EXE_ready      (EXE_ready),
        .IF_to_ID_valid (IF_to_ID_valid),
        .ID_valid       (ID_valid),
        .ID_ready       (ID_ready),
        .ID_to_EXE_valid(ID_to_EXE_valid),
        .ID_bj_enable   (ID_bj_enable),
        .IF_PC          (IF_PC),
        .IF_link        (IF_seq_PC),
        .IF_inst        (IF_inst),
        .ID_PC          (ID_PC),
        .ID_link        (ID_link),
        .ID_inst        (ID_inst)
    );

    assign ID_EXE_GPR1_A = |ID_GPR_read_num1 & EXE_GPR_write_enable &
                            ID_GPR_read_num1 == EXE_GPR_write_num;
    assign ID_EXE_GPR2_A = |ID_GPR_read_num2 & EXE_GPR_write_enable &
                            ID_GPR_read_num2 == EXE_GPR_write_num;
    assign ID_MEM_GPR1_A = |ID_GPR_read_num1 & MEM_GPR_write_enable &
                            ID_GPR_read_num1 == MEM_GPR_write_num;
    assign ID_MEM_GPR2_A = |ID_GPR_read_num2 & MEM_GPR_write_enable &
                            ID_GPR_read_num2 == MEM_GPR_write_num;

    assign ID_EXE_GPR1_Ts = ID_GPR1_use[`GPR_USE_ID] & |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM] |
                            ID_GPR1_use[`GPR_USE_EXE] & EXE_GPR_new[`GPR_NEW_WB];
    assign ID_EXE_GPR2_Ts = ID_GPR2_use[`GPR_USE_ID] & |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM] |
                            ID_GPR2_use[`GPR_USE_EXE] & EXE_GPR_new[`GPR_NEW_WB];
    assign ID_MEM_GPR1_Ts = ID_GPR1_use[`GPR_USE_ID] & MEM_GPR_new[`GPR_NEW_WB];
    assign ID_MEM_GPR2_Ts = ID_GPR2_use[`GPR_USE_ID] & MEM_GPR_new[`GPR_NEW_WB];

    assign ID_busy = ID_EXE_GPR1_A & ID_EXE_GPR1_Ts | ID_EXE_GPR2_A & ID_EXE_GPR2_Ts |
                     ID_MEM_GPR1_A & ID_MEM_GPR1_Ts | ID_MEM_GPR2_A & ID_MEM_GPR2_Ts;

    assign ID_EXE_Tf = |EXE_GPR_new[`GPR_NEW_EXE:`GPR_NEW_ID];
    assign ID_MEM_Tf = |MEM_GPR_new[`GPR_NEW_MEM:`GPR_NEW_ID];

    assign ID_rj_data = ID_EXE_GPR1_A & ID_EXE_Tf ? EXE_forward_data :
                        ID_MEM_GPR1_A & ID_MEM_Tf ? MEM_forward_data :
                        ID_GPR_read_data1;
    assign ID_rkd_data = ID_EXE_GPR2_A & ID_EXE_Tf ? EXE_forward_data :
                         ID_MEM_GPR2_A & ID_MEM_Tf ? MEM_forward_data :
                         ID_GPR_read_data2;

    ID_stage id_stage (
        .PC                  (ID_PC),
        .inst                (ID_inst),
        .ALU_src1_is_PC      (ID_ALU_src1_is_PC),
        .ALU_src2_is_imm     (ID_ALU_src2_is_imm),
        .ALU_operation       (ID_ALU_operation),
        .MEM_read            (ID_MEM_read),
        .MEM_read_ext        (ID_MEM_read_ext),
        .MEM_write           (ID_MEM_write),
        .MEM_write_ext       (ID_MEM_write_ext),
        .GPR_read_num1       (ID_GPR_read_num1),
        .rj_data             (ID_rj_data),
        .GPR_read_num2       (ID_GPR_read_num2),
        .rkd_data            (ID_rkd_data),
        .GPR_write           (ID_GPR_write),
        .GPR_write_num       (ID_GPR_write_num),
        .GPR_write_src_is_MEM(ID_GPR_write_src_is_MEM),
        .bj_taken            (ID_bj_taken),
        .target_PC           (ID_target_PC),
        .imm                 (ID_imm),
        .GPR1_use            (ID_GPR1_use),
        .GPR2_use            (ID_GPR2_use),
        .GPR_new             (ID_GPR_new)
    );

    assign ID_bj_enable = ID_valid & ~ID_busy & ID_bj_taken;

    regfile gpr_file (
        .clk         (clk),
        .read_num1   (ID_GPR_read_num1),
        .read_data1  (ID_GPR_read_data1),
        .read_num2   (ID_GPR_read_num2),
        .read_data2  (ID_GPR_read_data2),
        .write_enable(WB_GPR_write_enable),
        .write_num   (WB_GPR_write_num),
        .write_data  (WB_GPR_write_data)
    );

    EXE_reg exe_reg (
        .clk                     (clk),
        .reset                   (reset),
        .EXE_busy                (EXE_busy),
        .MEM_ready               (MEM_ready),
        .ID_to_EXE_valid         (ID_to_EXE_valid),
        .EXE_valid               (EXE_valid),
        .EXE_ready               (EXE_ready),
        .EXE_to_MEM_valid        (EXE_to_MEM_valid),
        .ID_PC                   (ID_PC),
        .ID_link                 (ID_link),
        .ID_imm                  (ID_imm),
        .ID_GPR_read_num1        (ID_GPR_read_num1),
        .ID_GPR_read_num2        (ID_GPR_read_num2),
        .ID_GPR_read_data1       (ID_rj_data),
        .ID_GPR_read_data2       (ID_rkd_data),
        .ID_ALU_src1_is_PC       (ID_ALU_src1_is_PC),
        .ID_ALU_src2_is_imm      (ID_ALU_src2_is_imm),
        .ID_ALU_operation        (ID_ALU_operation),
        .ID_MEM_read             (ID_MEM_read),
        .ID_MEM_read_ext         (ID_MEM_read_ext),
        .ID_MEM_write            (ID_MEM_write),
        .ID_MEM_write_ext        (ID_MEM_write_ext),
        .ID_GPR_write            (ID_GPR_write),
        .ID_GPR_write_num        (ID_GPR_write_num),
        .ID_GPR_write_src_is_MEM (ID_GPR_write_src_is_MEM),
        .ID_GPR_new              (ID_GPR_new),
        .EXE_PC                  (EXE_PC),
        .EXE_link                (EXE_link),
        .EXE_imm                 (EXE_imm),
        .EXE_GPR_read_num1       (EXE_GPR_read_num1),
        .EXE_GPR_read_num2       (EXE_GPR_read_num2),
        .EXE_GPR_read_data1      (EXE_GPR_read_data1),
        .EXE_GPR_read_data2      (EXE_GPR_read_data2),
        .EXE_ALU_src1_is_PC      (EXE_ALU_src1_is_PC),
        .EXE_ALU_src2_is_imm     (EXE_ALU_src2_is_imm),
        .EXE_ALU_operation       (EXE_ALU_operation),
        .EXE_MEM_read            (EXE_MEM_read),
        .EXE_MEM_read_ext        (EXE_MEM_read_ext),
        .EXE_MEM_write           (EXE_MEM_write),
        .EXE_MEM_write_ext       (EXE_MEM_write_ext),
        .EXE_GPR_write           (EXE_GPR_write),
        .EXE_GPR_write_num       (EXE_GPR_write_num),
        .EXE_GPR_write_src_is_MEM(EXE_GPR_write_src_is_MEM),
        .EXE_GPR_new             (EXE_GPR_new)
    );

    assign EXE_GPR_write_enable = EXE_valid & EXE_GPR_write;

    assign EXE_forward_data = {32{EXE_GPR_new[`GPR_NEW_ID]}} & EXE_link |
                              {32{EXE_GPR_new[`GPR_NEW_EXE]}} & EXE_imm;

    assign EXE_MEM_GPR1_A = |EXE_GPR_read_num1 & MEM_GPR_write_enable &
                             EXE_GPR_read_num1 == MEM_GPR_write_num;
    assign EXE_MEM_GPR2_A = |EXE_GPR_read_num2 & MEM_GPR_write_enable &
                             EXE_GPR_read_num2 == MEM_GPR_write_num;
    assign EXE_WB_GPR1_A = |EXE_GPR_read_num1 & WB_GPR_write_enable &
                            EXE_GPR_read_num1 == WB_GPR_write_num;
    assign EXE_WB_GPR2_A = |EXE_GPR_read_num2 & WB_GPR_write_enable &
                            EXE_GPR_read_num2 == WB_GPR_write_num;

    assign EXE_MEM_Tf = |MEM_GPR_new[`GPR_NEW_MEM:`GPR_NEW_ID];
    assign EXE_WB_Tf = |WB_GPR_new;

    assign EXE_rj_data = EXE_MEM_GPR1_A & EXE_MEM_Tf ? MEM_forward_data :
                         EXE_WB_GPR1_A & EXE_WB_Tf ? WB_forward_data :
                         EXE_GPR_read_data1;
    assign EXE_rkd_data = EXE_MEM_GPR2_A & EXE_MEM_Tf ? MEM_forward_data :
                          EXE_WB_GPR2_A & EXE_WB_Tf ? WB_forward_data :
                          EXE_GPR_read_data2;

    EXE_stage exe_stage (
        .busy            (EXE_busy),
        .PC              (EXE_PC),
        .imm             (EXE_imm),
        .rj_data         (EXE_rj_data),
        .rkd_data        (EXE_rkd_data),
        .ALU_src1_is_PC  (EXE_ALU_src1_is_PC),
        .ALU_src2_is_imm (EXE_ALU_src2_is_imm),
        .ALU_operation   (EXE_ALU_operation),
        .MEM_write       (EXE_MEM_write),
        .MEM_write_ext   (EXE_MEM_write_ext),
        .ALU_result      (EXE_ALU_result),
        .MEM_write_enable(EXE_MEM_write_enable),
        .MEM_addr        (EXE_MEM_addr),
        .MEM_write_data  (EXE_MEM_write_data)
    );

    assign data_sram_en    = EXE_valid & (EXE_MEM_read | EXE_MEM_write);
    assign data_sram_we    = {4{EXE_valid}} & EXE_MEM_write_enable;
    assign data_sram_addr  = EXE_MEM_addr;
    assign data_sram_wdata = EXE_MEM_write_data;

    MEM_reg mem_reg (
        .clk                     (clk),
        .reset                   (reset),
        .MEM_busy                (MEM_busy),
        .WB_ready                (WB_ready),
        .EXE_to_MEM_valid        (EXE_to_MEM_valid),
        .MEM_valid               (MEM_valid),
        .MEM_ready               (MEM_ready),
        .MEM_to_WB_valid         (MEM_to_WB_valid),
        .EXE_PC                  (EXE_PC),
        .EXE_ALU_result          (EXE_ALU_result),
        .EXE_MEM_read_ext        (EXE_MEM_read_ext),
        .EXE_MEM_addr_low        (EXE_MEM_addr[1:0]),
        .EXE_GPR_write           (EXE_GPR_write),
        .EXE_GPR_write_num       (EXE_GPR_write_num),
        .EXE_GPR_write_src_is_MEM(EXE_GPR_write_src_is_MEM),
        .EXE_GPR_new             (EXE_GPR_new),
        .MEM_PC                  (MEM_PC),
        .MEM_ALU_result          (MEM_ALU_result),
        .MEM_MEM_read_ext        (MEM_MEM_read_ext),
        .MEM_MEM_addr_low        (MEM_MEM_addr_low),
        .MEM_GPR_write           (MEM_GPR_write),
        .MEM_GPR_write_num       (MEM_GPR_write_num),
        .MEM_GPR_write_src_is_MEM(MEM_GPR_write_src_is_MEM),
        .MEM_GPR_new             (MEM_GPR_new)
    );

    assign MEM_GPR_write_enable = MEM_valid & MEM_GPR_write;

    assign MEM_forward_data     = MEM_ALU_result;

    assign MEM_MEM_read_data    = data_sram_rdata;

    MEM_stage mem_stage (
        .busy                (MEM_busy),
        .ALU_result          (MEM_ALU_result),
        .MEM_read_ext        (MEM_MEM_read_ext),
        .MEM_addr_low        (MEM_MEM_addr_low),
        .MEM_read_data       (MEM_MEM_read_data),
        .GPR_write_src_is_MEM(MEM_GPR_write_src_is_MEM),
        .GPR_write_data      (MEM_GPR_write_data)
    );

    WB_reg wb_reg (
        .clk               (clk),
        .reset             (reset),
        .WB_busy           (WB_busy),
        .MEM_to_WB_valid   (MEM_to_WB_valid),
        .WB_valid          (WB_valid),
        .WB_ready          (WB_ready),
        .MEM_PC            (MEM_PC),
        .MEM_GPR_write     (MEM_GPR_write),
        .MEM_GPR_write_num (MEM_GPR_write_num),
        .MEM_GPR_write_data(MEM_GPR_write_data),
        .MEM_GPR_new       (MEM_GPR_new),
        .WB_PC             (WB_PC),
        .WB_GPR_write      (WB_GPR_write),
        .WB_GPR_write_num  (WB_GPR_write_num),
        .WB_GPR_write_data (WB_GPR_write_data),
        .WB_GPR_new        (WB_GPR_new)
    );

    WB_stage wb_stage (.busy(WB_busy));

    assign WB_GPR_write_enable = WB_valid & WB_GPR_write;

    assign WB_forward_data     = WB_GPR_write_data;

    assign debug_wb_pc         = WB_PC;
    assign debug_wb_rf_we      = {4{WB_GPR_write_enable}};
    assign debug_wb_rf_wnum    = WB_GPR_write_num;
    assign debug_wb_rf_wdata   = WB_GPR_write_data;
endmodule
