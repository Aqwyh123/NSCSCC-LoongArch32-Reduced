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

    wire                        IF_busy;
    reg                         IF_valid;
    wire                        IF_ready;
    wire                        IF_to_ID_valid;

    reg  [                31:0] IF_PC;
    wire [                31:0] IF_next_PC;
    wire [                31:0] IF_seq_PC;
    wire [                31:0] IF_inst;

    wire                        ID_busy;
    wire                        ID_valid;
    wire                        ID_ready;
    wire                        ID_to_EXE_valid;

    wire [                31:0] ID_PC;
    wire [                31:0] ID_inst;
    wire                        ID_ALU_src1_is_PC;
    wire                        ID_ALU_src2_is_imm;
    wire [   `ALU_OP_WIDTH-1:0] ID_ALU_operation;
    wire [                 4:0] ID_GPR_read_num1;
    wire [                31:0] ID_GPR_read_data1;
    wire [                 4:0] ID_GPR_read_num2;
    wire [                31:0] ID_GPR_read_data2;
    wire [ `MEM_READ_WIDTH-1:0] ID_MEM_read;
    wire [`MEM_WRITE_WIDTH-1:0] ID_MEM_write;
    wire                        ID_GPR_write;
    wire                        ID_GPR_write_src_is_MEM;
    wire [                 4:0] ID_GPR_write_num;
    wire                        ID_taken;
    wire [                31:0] ID_target_PC;
    wire [                31:0] ID_imm;
    wire [                31:0] ID_rj_data;
    wire [                31:0] ID_rkd_data;

    wire                        EXE_busy;
    wire                        EXE_valid;
    wire                        EXE_ready;
    wire                        EXE_to_MEM_valid;

    wire [                31:0] EXE_PC;
    wire                        EXE_ALU_src1_is_PC;
    wire                        EXE_ALU_src2_is_imm;
    wire [   `ALU_OP_WIDTH-1:0] EXE_ALU_operation;
    wire [                31:0] EXE_imm;
    wire [                31:0] EXE_rj_data;
    wire [                31:0] EXE_rkd_data;
    wire [ `MEM_READ_WIDTH-1:0] EXE_MEM_read;
    wire [`MEM_WRITE_WIDTH-1:0] EXE_MEM_write;
    wire                        EXE_MEM_enable;
    wire [                 3:0] EXE_MEM_write_enable;
    wire [                31:0] EXE_MEM_addr;
    wire [                31:0] EXE_MEM_write_data;

    wire [                31:0] EXE_ALU_result;
    wire                        EXE_GPR_write;
    wire [                 4:0] EXE_GPR_write_num;
    wire                        EXE_GPR_write_src_is_MEM;

    wire                        MEM_busy;
    wire                        MEM_valid;
    wire                        MEM_ready;
    wire                        MEM_to_WB_valid;

    wire [                31:0] MEM_PC;
    wire [ `MEM_READ_WIDTH-1:0] MEM_MEM_read;
    wire [                31:0] MEM_MEM_addr;
    wire                        MEM_GPR_write;
    wire [                 4:0] MEM_GPR_write_num;
    wire                        MEM_GPR_write_src_is_MEM;
    wire [                31:0] MEM_ALU_result;
    wire [                31:0] MEM_MEM_read_data;


    wire                        WB_busy;
    wire                        WB_valid;
    wire                        WB_ready;

    wire [                31:0] WB_PC;
    wire                        WB_GPR_write;
    wire                        WB_GPR_write_src_is_MEM;
    wire [                31:0] WB_ALU_result;
    wire [                31:0] WB_MEM_read_data;
    wire                        WB_GPR_write_enable;
    wire [                 4:0] WB_GPR_write_num;
    wire [                31:0] WB_GPR_write_data;

    always @(posedge clk) begin
        if (reset) begin
            IF_valid <= 1'b0;
        end else begin
            IF_valid <= 1'b1;
        end
    end

    assign IF_ready       = ~IF_valid | (~IF_busy & ID_ready);
    assign IF_to_ID_valid = IF_valid & ~IF_busy;

    IF_stage if_stage (
        .busy  (IF_busy),
        .PC    (IF_PC),
        .seq_PC(IF_seq_PC)
    );

    assign IF_next_PC = ID_taken ? ID_target_PC : IF_seq_PC;

    always @(posedge clk) begin
        if (reset) begin
            IF_PC <= `PC_INIT - 32'h4;  // trick: to make next PC be 0x1c000000 during reset
        end else begin
            IF_PC <= IF_next_PC;
        end
    end

    assign inst_sram_en    = ~reset;
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
        .IF_PC          (IF_PC),
        .IF_inst        (IF_inst),
        .ID_PC          (ID_PC),
        .ID_inst        (ID_inst)
    );

    ID_stage id_stage (
        .busy                (ID_busy),
        .valid               (ID_valid),
        .PC                  (ID_PC),
        .inst                (ID_inst),
        .ALU_src1_is_PC      (ID_ALU_src1_is_PC),
        .ALU_src2_is_imm     (ID_ALU_src2_is_imm),
        .ALU_operation       (ID_ALU_operation),
        .GPR_write_src_is_MEM(ID_GPR_write_src_is_MEM),
        .MEM_read            (ID_MEM_read),
        .MEM_write           (ID_MEM_write),
        .GPR_write           (ID_GPR_write),
        .GPR_read_num1       (ID_GPR_read_num1),
        .GPR_read_data1      (ID_GPR_read_data1),
        .GPR_read_num2       (ID_GPR_read_num2),
        .GPR_read_data2      (ID_GPR_read_data2),
        .GPR_write_num       (ID_GPR_write_num),
        .taken               (ID_taken),
        .target_PC           (ID_target_PC),
        .imm                 (ID_imm),
        .rj_data             (ID_rj_data),
        .rkd_data            (ID_rkd_data)
    );

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
        .ID_ALU_src1_is_PC       (ID_ALU_src1_is_PC),
        .ID_ALU_src2_is_imm      (ID_ALU_src2_is_imm),
        .ID_ALU_operation        (ID_ALU_operation),
        .ID_imm                  (ID_imm),
        .ID_rj_data              (ID_rj_data),
        .ID_rkd_data             (ID_rkd_data),
        .ID_MEM_read             (ID_MEM_read),
        .ID_MEM_write            (ID_MEM_write),
        .ID_GPR_write            (ID_GPR_write),
        .ID_GPR_write_num        (ID_GPR_write_num),
        .ID_GPR_write_src_is_MEM (ID_GPR_write_src_is_MEM),
        .EXE_PC                  (EXE_PC),
        .EXE_ALU_src1_is_PC      (EXE_ALU_src1_is_PC),
        .EXE_ALU_src2_is_imm     (EXE_ALU_src2_is_imm),
        .EXE_ALU_operation       (EXE_ALU_operation),
        .EXE_imm                 (EXE_imm),
        .EXE_rj_data             (EXE_rj_data),
        .EXE_rkd_data            (EXE_rkd_data),
        .EXE_MEM_read            (EXE_MEM_read),
        .EXE_MEM_write           (EXE_MEM_write),
        .EXE_GPR_write           (EXE_GPR_write),
        .EXE_GPR_write_num       (EXE_GPR_write_num),
        .EXE_GPR_write_src_is_MEM(EXE_GPR_write_src_is_MEM)
    );

    EXE_stage exe_stage (
        .busy            (EXE_busy),
        .valid           (EXE_valid),
        .ALU_src1_is_PC  (EXE_ALU_src1_is_PC),
        .ALU_src2_is_imm (EXE_ALU_src2_is_imm),
        .ALU_operation   (EXE_ALU_operation),
        .PC              (EXE_PC),
        .imm             (EXE_imm),
        .rj_data         (EXE_rj_data),
        .rkd_data        (EXE_rkd_data),
        .MEM_read        (EXE_MEM_read),
        .MEM_write       (EXE_MEM_write),
        .ALU_result      (EXE_ALU_result),
        .MEM_enable      (EXE_MEM_enable),
        .MEM_write_enable(EXE_MEM_write_enable),
        .MEM_addr        (EXE_MEM_addr),
        .MEM_write_data  (EXE_MEM_write_data)
    );

    assign data_sram_en    = EXE_MEM_enable;
    assign data_sram_we    = EXE_MEM_write_enable;
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
        .EXE_MEM_read            (EXE_MEM_read),
        .EXE_MEM_addr            (EXE_MEM_addr),
        .EXE_GPR_write           (EXE_GPR_write),
        .EXE_GPR_write_num       (EXE_GPR_write_num),
        .EXE_GPR_write_src_is_MEM(EXE_GPR_write_src_is_MEM),
        .EXE_ALU_result          (EXE_ALU_result),
        .MEM_PC                  (MEM_PC),
        .MEM_MEM_read            (MEM_MEM_read),
        .MEM_MEM_addr            (MEM_MEM_addr),
        .MEM_GPR_write           (MEM_GPR_write),
        .MEM_GPR_write_num       (MEM_GPR_write_num),
        .MEM_GPR_write_src_is_MEM(MEM_GPR_write_src_is_MEM),
        .MEM_ALU_result          (MEM_ALU_result)
    );

    MEM_stage mem_stage (
        .busy           (MEM_busy),
        .MEM_read       (MEM_MEM_read),
        .MEM_addr       (MEM_MEM_addr),
        .data_sram_rdata(data_sram_rdata),
        .MEM_read_data  (MEM_MEM_read_data)
    );

    WB_reg wb_reg (
        .clk                     (clk),
        .reset                   (reset),
        .WB_busy                 (WB_busy),
        .MEM_to_WB_valid         (MEM_to_WB_valid),
        .WB_valid                (WB_valid),
        .WB_ready                (WB_ready),
        .MEM_PC                  (MEM_PC),
        .MEM_GPR_write           (MEM_GPR_write),
        .MEM_GPR_write_num       (MEM_GPR_write_num),
        .MEM_GPR_write_src_is_MEM(MEM_GPR_write_src_is_MEM),
        .MEM_ALU_result          (MEM_ALU_result),
        .MEM_MEM_read_data       (MEM_MEM_read_data),
        .WB_PC                   (WB_PC),
        .WB_GPR_write            (WB_GPR_write),
        .WB_GPR_write_num        (WB_GPR_write_num),
        .WB_GPR_write_src_is_MEM (WB_GPR_write_src_is_MEM),
        .WB_ALU_result           (WB_ALU_result),
        .WB_MEM_read_data        (WB_MEM_read_data)
    );

    WB_stage wb_stage (
        .busy                (WB_busy),
        .valid               (WB_valid),
        .GPR_write_src_is_MEM(WB_GPR_write_src_is_MEM),
        .GPR_write           (WB_GPR_write),
        .ALU_result          (WB_ALU_result),
        .MEM_read_data       (WB_MEM_read_data),
        .GPR_write_enable    (WB_GPR_write_enable),
        .GPR_write_data      (WB_GPR_write_data)
    );

    assign debug_wb_pc       = WB_PC;
    assign debug_wb_rf_we    = {4{WB_GPR_write_enable}};
    assign debug_wb_rf_wnum  = WB_GPR_write_num;
    assign debug_wb_rf_wdata = WB_GPR_write_data;
endmodule
