`include "macros.vh"

module mycpu_top #(
    parameter TLB_ENTRIES = `TLB_ENTRIES
) (
    input  wire        aclk,
    input  wire        aresetn,
    // read requast channel
    output wire [ 3:0] arid,
    output wire [31:0] araddr,
    output wire [ 7:0] arlen,             // fixed to 8'h00
    output wire [ 2:0] arsize,
    output wire [ 1:0] arburst,           // fixed to 2'b01
    output wire [ 1:0] arlock,            // fixed to 2'b00
    output wire [ 3:0] arcache,           // fixed to 4'b0000
    output wire [ 2:0] arprot,            // fixed to 3'b000
    output wire        arvalid,
    input  wire        arready,
    // read response channel
    input  wire [ 3:0] rid,
    input  wire [31:0] rdata,
    input  wire [ 1:0] rresp,             // ignored
    input  wire        rlast,             // ignored
    input  wire        rvalid,
    output wire        rready,
    // write requast channel
    output wire [ 3:0] awid,              // fixed to 4'b0001
    output wire [31:0] awaddr,
    output wire [ 7:0] awlen,             // fixed to 8'h00
    output wire [ 2:0] awsize,
    output wire [ 1:0] awburst,           // fixed to 2'b01
    output wire [ 1:0] awlock,            // fixed to 2'b00
    output wire [ 3:0] awcache,           // fixed to 4'b0000
    output wire [ 2:0] awprot,            // fixed to 3'b000
    output wire        awvalid,
    input  wire        awready,
    // write data channel
    output wire [ 3:0] wid,               // fixed to 4'b0001
    output wire [31:0] wdata,
    output wire [ 3:0] wstrb,
    output wire        wlast,             // fixed to 1'b1
    output wire        wvalid,
    input  wire        wready,
    // write response channel
    input  wire [ 3:0] bid,               // ignored
    input  wire [ 1:0] bresp,             // ignored
    input  wire        bvalid,
    output wire        bready,
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire                            clk;
    wire                            reset;
    // inst sram interface
    wire                            inst_sram_req;
    wire                            inst_sram_wr;
    wire [                     1:0] inst_sram_size;
    wire [                    31:0] inst_sram_vaddr;
    wire [                    31:0] inst_sram_paddr;
    wire [                     3:0] inst_sram_wstrb;
    wire [                    31:0] inst_sram_wdata;
    wire                            inst_sram_addr_ok;
    wire                            inst_sram_data_ok;
    wire [                    31:0] inst_sram_rdata;
    // data sram interface
    wire                            data_sram_req;
    wire                            data_sram_wr;
    wire [                     1:0] data_sram_size;
    wire [                    31:0] data_sram_vaddr;
    wire [                    31:0] data_sram_paddr;
    wire [                     3:0] data_sram_wstrb;
    wire [                    31:0] data_sram_wdata;
    wire                            data_sram_addr_ok;
    wire                            data_sram_data_ok;
    wire [                    31:0] data_sram_rdata;

    wire [                    31:0] PC;
    wire                            flush;
    wire [    `EXCEPTION_WIDTH-1:0] exception;
    wire                            ereturn;
    wire                            refetch;
    wire                            request;
    wire [                    31:0] eentry;
    wire [                    31:0] eraddr;
    wire [                    31:0] rentry;
    wire [                    31:0] rtarget;

    wire                            DA;
    wire                            PG;
    wire [                     9:0] ASID;
    wire [                     1:0] PLV;
    wire [                     1:0] PLV0;
    wire [                     2:0] PSEG0;
    wire [                     2:0] VSEG0;
    wire [                     1:0] PLV1;
    wire [                     2:0] PSEG1;
    wire [                     2:0] VSEG1;

    wire                            TLB_s_hit;
    wire [ $clog2(TLB_ENTRIES)-1:0] TLB_s_index;
    wire [       `TLBEHI_WIDTH-1:0] TLB_r_hi;
    wire [       `TLBELO_WIDTH-1:0] TLB_r_lo0;
    wire [       `TLBELO_WIDTH-1:0] TLB_r_lo1;
    wire [ $clog2(TLB_ENTRIES)-1:0] TLB_rw_index;
    wire [       `TLBEHI_WIDTH-1:0] TLB_sw_hi;
    wire [       `TLBELO_WIDTH-1:0] TLB_w_lo0;
    wire [       `TLBELO_WIDTH-1:0] TLB_w_lo1;

    wire                            IF_to_ID_valid;

    wire [                    31:0] IF_PC;
    wire [                    31:0] IF_link;
    wire [                    31:0] IF_inst;
    // wire [    `EXCEPTION_WIDTH-1:0] IF_exception;
    wire                            IF_ADEF;

    wire                            ID_done;
    wire                            ID_valid;
    wire                            ID_ready;
    wire                            ID_to_EXE_valid;

    wire [                    31:0] ID_PC;
    wire [                    31:0] ID_inst;
    wire [    `EXCEPTION_WIDTH-1:0] ID_exception;
    wire                            ID_ereturn;
    wire                            ID_refetch;
    wire                            ID_INT;
    wire                            ID_PIF;
    wire                            ID_PPI;
    wire                            ID_ADEF;
    wire                            ID_SYS;
    wire                            ID_BRK;
    wire                            ID_INE;
    wire                            ID_TLBR;

    wire                            ID_stall;
    wire                            ID_GPR_stall;
    wire                            ID_CSR_stall;
    wire                            ID_int_stall;
    wire                            ID_flush_stall;
    wire                            ID_bj_stall;
    wire                            ID_MEM_GPR1_A;
    wire                            ID_MEM_GPR2_A;
    wire                            ID_MEM_GPR1_T;
    wire                            ID_MEM_GPR2_T;
    wire                            ID_EXE_GPR1_A;
    wire                            ID_EXE_GPR2_A;
    wire                            ID_EXE_GPR1_T;
    wire                            ID_EXE_GPR2_T;
    wire                            ID_EXE_CSR;
    wire                            ID_MEM_CSR;
    wire                            ID_WB_CSR;
    wire                            ID_EXE_int;
    wire                            ID_MEM_int;
    wire                            ID_WB_int;

    wire                            ID_jump;
    wire [       `BRANCH_WIDTH-1:0] ID_branch;
    wire                            ID_bj_taken;
    wire [                    31:0] ID_target_PC;

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

    wire                            ID_ALU_src1_is_PC;
    wire                            ID_ALU_src2_is_imm;
    wire [       `ALU_OP_WIDTH-1:0] ID_ALU_operation;
    wire                            ID_mul_div_unsigned;

    wire [     `MEM_READ_WIDTH-1:0] ID_MEM_read;
    wire [    `MEM_WRITE_WIDTH-1:0] ID_MEM_write;

    wire [   `CSR_NUMBER_WIDTH-1:0] ID_CSR_number;
    wire [                    31:0] ID_CSR_read_data;
    wire [                    63:0] ID_CSR_counter;
    wire [                    31:0] ID_CSR_result;
    wire                            ID_CSR_write;
    wire                            ID_CSR_write_mask;
    wire                            ID_CSR_use;

    wire [       `TLB_OP_WIDTH-1:0] ID_TLB_operation;
    wire [                     4:0] ID_invtlb_op;

    wire                            EXE_done;
    wire                            EXE_valid;
    wire                            EXE_ready;
    wire                            EXE_to_MEM_valid;

    wire [                    31:0] EXE_PC;
    wire [    `EXCEPTION_WIDTH-1:0] EXE_exception;
    wire                            EXE_ereturn;
    wire                            EXE_refetch;
    wire                            EXE_INT;
    wire                            EXE_PIL;
    wire                            EXE_PIS;
    wire                            EXE_PME;
    wire                            EXE_PPI;
    wire                            EXE_ADEF;
    wire                            EXE_ALE;
    wire                            EXE_SYS;
    wire                            EXE_BRK;
    wire                            EXE_INE;
    wire                            EXE_TLBR;

    wire [                    31:0] EXE_rj_data;
    wire [                    31:0] EXE_rkd_data;
    wire [      `GPR_NEW_WIDTH-1:0] EXE_GPR_new;
    wire                            EXE_GPR_write;
    wire [                     4:0] EXE_GPR_write_num;
    wire [`GPR_WRITE_SRC_WIDTH-1:0] EXE_GPR_write_src;
    wire [                    31:0] EXE_link;
    wire [                    31:0] EXE_imm;
    wire [                    31:0] EXE_forward_data;

    wire                            EXE_ALU_src1_is_PC;
    wire                            EXE_ALU_src2_is_imm;
    wire [       `ALU_OP_WIDTH-1:0] EXE_ALU_operation;
    wire                            EXE_mul_div_unsigned;
    wire [                    31:0] EXE_ALU_result;

    wire [     `MEM_READ_WIDTH-1:0] EXE_MEM_read;
    wire [    `MEM_WRITE_WIDTH-1:0] EXE_MEM_write;

    wire [                    31:0] EXE_CSR_result;
    wire                            EXE_CSR_write;
    wire [   `CSR_NUMBER_WIDTH-1:0] EXE_CSR_write_number;
    wire [                    31:0] EXE_CSR_write_data;

    wire [       `TLB_OP_WIDTH-1:0] EXE_TLB_operation;
    wire [                     4:0] EXE_invtlb_op;

    wire                            MEM_done;
    wire                            MEM_valid;
    wire                            MEM_ready;
    wire                            MEM_to_WB_valid;

    wire [                    31:0] MEM_PC;
    wire [    `EXCEPTION_WIDTH-1:0] MEM_exception;
    wire                            MEM_ereturn;
    wire                            MEM_refetch;
    wire                            MEM_INT;
    wire                            MEM_ADEF;
    wire                            MEM_ALE;
    wire                            MEM_SYS;
    wire                            MEM_BRK;
    wire                            MEM_INE;

    wire [                    31:0] MEM_rj_data;
    wire [                    31:0] MEM_rkd_data;
    wire [      `GPR_NEW_WIDTH-1:0] MEM_GPR_new;
    wire                            MEM_GPR_write;
    wire [                     4:0] MEM_GPR_write_num;
    wire [`GPR_WRITE_SRC_WIDTH-1:0] MEM_GPR_write_src;
    wire [                    31:0] MEM_forward_data;

    wire [`ALU_OP_MULH:`ALU_OP_MUL] MEM_ALU_operation;
    wire [                    63:0] MEM_mul_result;
    wire [                    31:0] MEM_EXE_ALU_result;
    wire [                    31:0] MEM_ALU_result;

    wire [     `MEM_READ_WIDTH-1:0] MEM_MEM_read;
    wire [    `MEM_WRITE_WIDTH-1:0] MEM_MEM_write;
    wire [                    31:0] MEM_MEM_result;

    wire [                    31:0] MEM_CSR_result;
    wire                            MEM_CSR_write;
    wire [   `CSR_NUMBER_WIDTH-1:0] MEM_CSR_write_number;
    wire                            EXE_CSR_write_mask;
    wire [                    31:0] MEM_CSR_write_data;

    wire [       `TLB_OP_WIDTH-1:0] MEM_TLB_operation;
    wire [                     4:0] MEM_invtlb_op;

    wire                            WB_done;
    wire                            WB_valid;
    wire                            WB_ready;

    wire [                    31:0] WB_PC;
    wire [    `EXCEPTION_WIDTH-1:0] WB_exception;
    wire                            WB_ereturn;
    wire                            WB_refetch;
    wire                            WB_INT;
    wire                            WB_ADEF;
    wire                            WB_ALE;
    wire                            WB_SYS;
    wire                            WB_BRK;
    wire                            WB_INE;

    wire [                    31:0] WB_rj_data;
    wire [                    31:0] WB_rkd_data;
    wire                            WB_GPR_write;
    wire                            WB_GPR_write_enable;
    wire [                     4:0] WB_GPR_write_num;
    wire [`GPR_WRITE_SRC_WIDTH-1:0] WB_GPR_write_src;
    wire [                    31:0] WB_GPR_write_data;
    wire [                    31:0] WB_ALU_result;
    wire [                    31:0] WB_MEM_result;
    wire [                    31:0] WB_CSR_result;
    // wire [                31:0] WB_forward_data;

    wire                            WB_CSR_write;
    wire                            WB_CSR_write_enable;
    wire [   `CSR_NUMBER_WIDTH-1:0] WB_CSR_write_number;
    wire [                    31:0] WB_CSR_write_data;

    wire [       `TLB_OP_WIDTH-1:0] WB_TLB_operation;
    wire [                     4:0] WB_invtlb_op;

    AXI_Bridge axi_bridge (
        .aclk             (aclk),
        .aresetn          (aresetn),
        .clk              (clk),
        .reset            (reset),
        .inst_sram_req    (inst_sram_req),
        .inst_sram_wr     (inst_sram_wr),
        .inst_sram_size   (inst_sram_size),
        .inst_sram_addr   (inst_sram_vaddr),
        .inst_sram_wstrb  (inst_sram_wstrb),
        .inst_sram_wdata  (inst_sram_wdata),
        .inst_sram_addr_ok(inst_sram_addr_ok),
        .inst_sram_data_ok(inst_sram_data_ok),
        .inst_sram_rdata  (inst_sram_rdata),
        .data_sram_req    (data_sram_req),
        .data_sram_wr     (data_sram_wr),
        .data_sram_size   (data_sram_size),
        .data_sram_addr   (data_sram_vaddr),
        .data_sram_wstrb  (data_sram_wstrb),
        .data_sram_wdata  (data_sram_wdata),
        .data_sram_addr_ok(data_sram_addr_ok),
        .data_sram_data_ok(data_sram_data_ok),
        .data_sram_rdata  (data_sram_rdata),
        .arid             (arid),
        .araddr           (araddr),
        .arlen            (arlen),
        .arsize           (arsize),
        .arburst          (arburst),
        .arlock           (arlock),
        .arcache          (arcache),
        .arprot           (arprot),
        .arvalid          (arvalid),
        .arready          (arready),
        .rid              (rid),
        .rdata            (rdata),
        .rresp            (rresp),
        .rlast            (rlast),
        .rvalid           (rvalid),
        .rready           (rready),
        .awid             (awid),
        .awaddr           (awaddr),
        .awlen            (awlen),
        .awsize           (awsize),
        .awburst          (awburst),
        .awlock           (awlock),
        .awcache          (awcache),
        .awprot           (awprot),
        .awvalid          (awvalid),
        .awready          (awready),
        .wid              (wid),
        .wdata            (wdata),
        .wstrb            (wstrb),
        .wlast            (wlast),
        .wvalid           (wvalid),
        .wready           (wready),
        .bid              (bid),
        .bresp            (bresp),
        .bvalid           (bvalid),
        .bready           (bready)
    );

    IF_stage if_stage (
        .clk              (clk),
        .reset            (reset),
        .exception        (exception),
        .ereturn          (ereturn),
        .refetch          (refetch),
        .eentry           (eentry),
        .eraddr           (eraddr),
        .rentry           (rentry),
        .rtarget          (rtarget),
        .bj_taken         (ID_bj_taken),
        .bj_stall         (ID_bj_stall),
        .bj_target        (ID_target_PC),
        .ID_ready         (ID_ready),
        .IF_to_ID_valid   (IF_to_ID_valid),
        .inst_sram_req    (inst_sram_req),
        .inst_sram_wr     (inst_sram_wr),
        .inst_sram_size   (inst_sram_size),
        .inst_sram_vaddr  (inst_sram_vaddr),
        .inst_sram_wstrb  (inst_sram_wstrb),
        .inst_sram_wdata  (inst_sram_wdata),
        .inst_sram_addr_ok(inst_sram_addr_ok),
        .inst_sram_data_ok(inst_sram_data_ok),
        .inst_sram_rdata  (inst_sram_rdata),
        .PC               (IF_PC),
        .link             (IF_link),
        .inst             (IF_inst),
        .ADEF             (IF_ADEF)
    );

    // assign IF_exception = {9'b0, IF_ADEF, 6'b0};

    ID_reg id_reg (
        .clk            (clk),
        .reset          (reset),
        .flush          (flush),
        .ID_done        (ID_done),
        .EXE_ready      (EXE_ready),
        .IF_to_ID_valid (IF_to_ID_valid),
        .ID_valid       (ID_valid),
        .ID_ready       (ID_ready),
        .ID_to_EXE_valid(ID_to_EXE_valid),
        .IF_PC          (IF_PC),
        .IF_link        (IF_link),
        .IF_inst        (IF_inst),
        .IF_ADEF        (IF_ADEF),
        .ID_PC          (ID_PC),
        .ID_link        (ID_link),
        .ID_inst        (ID_inst),
        .ID_ADEF        (ID_ADEF)
    );

    ID_stage id_stage (
        .valid           (ID_valid),
        .inst            (ID_inst),
        .jump            (ID_jump),
        .branch          (ID_branch),
        .PC              (ID_PC),
        .GPR_read_num1   (ID_GPR_read_num1),
        .rj_data         (ID_rj_data),
        .GPR_read_num2   (ID_GPR_read_num2),
        .rkd_data        (ID_rkd_data),
        .CSR_number      (ID_CSR_number),
        .CSR_read_data   (ID_CSR_read_data),
        .CSR_counter     (ID_CSR_counter),
        .CSR_result      (ID_CSR_result),
        .ALU_src1_is_PC  (ID_ALU_src1_is_PC),
        .ALU_src2_is_imm (ID_ALU_src2_is_imm),
        .ALU_operation   (ID_ALU_operation),
        .mul_div_unsigned(ID_mul_div_unsigned),
        .MEM_read        (ID_MEM_read),
        .MEM_write       (ID_MEM_write),
        .GPR_write       (ID_GPR_write),
        .GPR_write_num   (ID_GPR_write_num),
        .GPR_write_src   (ID_GPR_write_src),
        .CSR_write       (ID_CSR_write),
        .CSR_write_mask  (ID_CSR_write_mask),
        .TLB_operation   (ID_TLB_operation),
        .invtlb_op       (ID_invtlb_op),
        .GPR1_use        (ID_GPR1_use),
        .GPR2_use        (ID_GPR2_use),
        .GPR_new         (ID_GPR_new),
        .CSR_use         (ID_CSR_use),
        .bj_taken        (ID_bj_taken),
        .target_PC       (ID_target_PC),
        .imm             (ID_imm),
        .ereturn         (ID_ereturn),
        .refetch         (ID_refetch),
        .SYS             (ID_SYS),
        .BRK             (ID_BRK),
        .INE             (ID_INE)
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

    assign ID_INT = request & ~ID_int_stall;

    assign ID_exception = {4'b0, ID_INE, ID_BRK, ID_SYS, 2'b0, ID_ADEF, 5'b0, ID_INT};

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

    assign ID_EXE_CSR = ID_CSR_use & EXE_CSR_write & ID_CSR_number == EXE_CSR_write_number;
    assign ID_MEM_CSR = ID_CSR_use & MEM_CSR_write & ID_CSR_number == MEM_CSR_write_number;
    assign ID_WB_CSR = ID_CSR_use & WB_CSR_write & ID_CSR_number == WB_CSR_write_number;

    assign ID_EXE_int = EXE_CSR_write &
                       (EXE_CSR_write_number == `CSR_CRMD | EXE_CSR_write_number == `CSR_ECFG |
                        EXE_CSR_write_number == `CSR_ECFG | EXE_CSR_write_number == `CSR_ESTAT |
                        EXE_CSR_write_number == `CSR_TCFG | EXE_CSR_write_number == `CSR_TICLR);
    assign ID_MEM_int = MEM_CSR_write &
                       (MEM_CSR_write_number == `CSR_CRMD| MEM_CSR_write_number == `CSR_ECFG |
                        MEM_CSR_write_number == `CSR_ECFG | MEM_CSR_write_number == `CSR_ESTAT |
                        MEM_CSR_write_number == `CSR_TCFG  | MEM_CSR_write_number == `CSR_TICLR);
    assign ID_WB_int  = WB_CSR_write &
                       (WB_CSR_write_number == `CSR_CRMD | WB_CSR_write_number == `CSR_ECFG |
                        WB_CSR_write_number == `CSR_ECFG | WB_CSR_write_number == `CSR_ESTAT |
                        WB_CSR_write_number == `CSR_TCFG | WB_CSR_write_number == `CSR_TICLR);

    assign ID_GPR_stall = EXE_valid & (ID_EXE_GPR1_A & ID_EXE_GPR1_T |
                                       ID_EXE_GPR2_A & ID_EXE_GPR2_T) |
                          MEM_valid & (ID_MEM_GPR1_A & ID_MEM_GPR1_T |
                                       ID_MEM_GPR2_A & ID_MEM_GPR2_T);

    assign ID_CSR_stall = EXE_valid & ID_EXE_CSR | MEM_valid & ID_MEM_CSR | WB_valid & ID_WB_CSR;

    assign ID_int_stall = EXE_valid & ID_EXE_int | MEM_valid & ID_MEM_int | WB_valid & ID_WB_int;

    // TODO: delay memory write
    assign ID_flush_stall = EXE_valid & (EXE_refetch | EXE_ereturn) |
                            MEM_valid & (MEM_refetch | MEM_ereturn);

    assign ID_bj_stall = ID_valid & ID_jump & (EXE_valid & ID_EXE_GPR1_A &
                        |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM] |
                         MEM_valid & ID_MEM_GPR1_A & MEM_GPR_new[`GPR_NEW_WB]) |
                         ID_valid & |ID_branch[`BRANCH_LTU:`BRANCH_EQ] &
                        (EXE_valid & (ID_EXE_GPR1_A | ID_EXE_GPR2_A) &
                        |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM] |
                         MEM_valid & (ID_MEM_GPR1_A | ID_MEM_GPR2_A) & MEM_GPR_new[`GPR_NEW_WB]);

    assign ID_stall = ID_GPR_stall | ID_CSR_stall | ID_int_stall | ID_flush_stall;

    assign ID_done = ~ID_stall | |ID_exception;

    EXE_reg exe_reg (
        .clk                 (clk),
        .reset               (reset),
        .flush               (flush),
        .EXE_done            (EXE_done),
        .MEM_ready           (MEM_ready),
        .ID_to_EXE_valid     (ID_to_EXE_valid),
        .EXE_valid           (EXE_valid),
        .EXE_ready           (EXE_ready),
        .EXE_to_MEM_valid    (EXE_to_MEM_valid),
        .ID_PC               (ID_PC),
        .ID_link             (ID_link),
        .ID_imm              (ID_imm),
        .ID_rj_data          (ID_rj_data),
        .ID_rkd_data         (ID_rkd_data),
        .ID_ALU_src1_is_PC   (ID_ALU_src1_is_PC),
        .ID_ALU_src2_is_imm  (ID_ALU_src2_is_imm),
        .ID_ALU_operation    (ID_ALU_operation),
        .ID_mul_div_unsigned (ID_mul_div_unsigned),
        .ID_MEM_read         (ID_MEM_read),
        .ID_MEM_write        (ID_MEM_write),
        .ID_GPR_write        (ID_GPR_write),
        .ID_GPR_write_num    (ID_GPR_write_num),
        .ID_GPR_write_src    (ID_GPR_write_src),
        .ID_CSR_result       (ID_CSR_result),
        .ID_CSR_write        (ID_CSR_write),
        .ID_CSR_write_number (ID_CSR_number),
        .ID_CSR_write_mask   (ID_CSR_write_mask),
        .ID_TLB_operation    (ID_TLB_operation),
        .ID_invtlb_op        (ID_invtlb_op),
        .ID_ereturn          (ID_ereturn),
        .ID_refetch          (ID_refetch),
        .ID_GPR_new          (ID_GPR_new),
        .ID_INT              (ID_INT),
        .ID_ADEF             (ID_ADEF),
        .ID_SYS              (ID_SYS),
        .ID_BRK              (ID_BRK),
        .ID_INE              (ID_INE),
        .EXE_PC              (EXE_PC),
        .EXE_link            (EXE_link),
        .EXE_imm             (EXE_imm),
        .EXE_rj_data         (EXE_rj_data),
        .EXE_rkd_data        (EXE_rkd_data),
        .EXE_ALU_src1_is_PC  (EXE_ALU_src1_is_PC),
        .EXE_ALU_src2_is_imm (EXE_ALU_src2_is_imm),
        .EXE_ALU_operation   (EXE_ALU_operation),
        .EXE_mul_div_unsigned(EXE_mul_div_unsigned),
        .EXE_MEM_read        (EXE_MEM_read),
        .EXE_MEM_write       (EXE_MEM_write),
        .EXE_GPR_write       (EXE_GPR_write),
        .EXE_GPR_write_num   (EXE_GPR_write_num),
        .EXE_GPR_write_src   (EXE_GPR_write_src),
        .EXE_CSR_result      (EXE_CSR_result),
        .EXE_CSR_write       (EXE_CSR_write),
        .EXE_CSR_write_number(EXE_CSR_write_number),
        .EXE_CSR_write_mask  (EXE_CSR_write_mask),
        .EXE_TLB_operation   (EXE_TLB_operation),
        .EXE_invtlb_op       (EXE_invtlb_op),
        .EXE_ereturn         (EXE_ereturn),
        .EXE_refetch         (EXE_refetch),
        .EXE_GPR_new         (EXE_GPR_new),
        .EXE_INT             (EXE_INT),
        .EXE_ADEF            (EXE_ADEF),
        .EXE_SYS             (EXE_SYS),
        .EXE_BRK             (EXE_BRK),
        .EXE_INE             (EXE_INE)
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
        .data_sram_vaddr  (data_sram_vaddr),
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
        .div_unsigned     (EXE_mul_div_unsigned),
        .MEM_read         (EXE_MEM_read),
        .MEM_write        (EXE_MEM_write),
        .CSR_read_data    (EXE_CSR_result),
        .CSR_write_mask   (EXE_CSR_write_mask),
        .CSR_write_data   (EXE_CSR_write_data),
        .ALU_result       (EXE_ALU_result),
        .ALE              (EXE_ALE)
    );

    multiplier mul (
        .clk         (clk),
        .mul_unsigned(EXE_mul_div_unsigned),
        .factor1     (EXE_rj_data),
        .factor2     (EXE_rkd_data),
        .product     (MEM_mul_result)
    );

    assign EXE_exception = {
        4'b0, EXE_INE, EXE_BRK, EXE_SYS, EXE_ALE, 1'b0, EXE_ADEF, 5'b0, EXE_INT
    };

    assign EXE_forward_data = {32{EXE_GPR_write_src[`GPR_WRITE_SRC_LINK]}} & EXE_link |
                              {32{EXE_GPR_write_src[`GPR_WRITE_SRC_LUI]}} & EXE_imm |
                              {32{EXE_GPR_write_src[`GPR_WRITE_SRC_CSR]}} & EXE_CSR_result;

    MEM_reg mem_reg (
        .clk                 (clk),
        .reset               (reset),
        .flush               (flush),
        .MEM_done            (MEM_done),
        .WB_ready            (WB_ready),
        .EXE_to_MEM_valid    (EXE_to_MEM_valid),
        .MEM_valid           (MEM_valid),
        .MEM_ready           (MEM_ready),
        .MEM_to_WB_valid     (MEM_to_WB_valid),
        .EXE_PC              (EXE_PC),
        .EXE_rj_data         (EXE_rj_data),
        .EXE_rkd_data        (EXE_rkd_data),
        .EXE_ALU_operation   (EXE_ALU_operation[`ALU_OP_MULH:`ALU_OP_MUL]),
        .EXE_ALU_result      (EXE_ALU_result),
        .EXE_MEM_read        (EXE_MEM_read),
        .EXE_MEM_write       (EXE_MEM_write),
        .EXE_GPR_write       (EXE_GPR_write),
        .EXE_GPR_write_num   (EXE_GPR_write_num),
        .EXE_GPR_write_src   (EXE_GPR_write_src),
        .EXE_CSR_result      (EXE_CSR_result),
        .EXE_CSR_write       (EXE_CSR_write),
        .EXE_CSR_write_number(EXE_CSR_write_number),
        .EXE_CSR_write_data  (EXE_CSR_write_data),
        .EXE_TLB_operation   (EXE_TLB_operation),
        .EXE_invtlb_op       (EXE_invtlb_op),
        .EXE_ereturn         (EXE_ereturn),
        .EXE_refetch         (EXE_refetch),
        .EXE_GPR_new         (EXE_GPR_new),
        .EXE_INT             (EXE_INT),
        .EXE_ADEF            (EXE_ADEF),
        .EXE_ALE             (EXE_ALE),
        .EXE_SYS             (EXE_SYS),
        .EXE_BRK             (EXE_BRK),
        .EXE_INE             (EXE_INE),
        .MEM_PC              (MEM_PC),
        .MEM_rj_data         (MEM_rj_data),
        .MEM_rkd_data        (MEM_rkd_data),
        .MEM_ALU_operation   (MEM_ALU_operation),
        .MEM_EXE_ALU_result  (MEM_EXE_ALU_result),
        .MEM_MEM_read        (MEM_MEM_read),
        .MEM_MEM_write       (MEM_MEM_write),
        .MEM_GPR_write       (MEM_GPR_write),
        .MEM_GPR_write_num   (MEM_GPR_write_num),
        .MEM_GPR_write_src   (MEM_GPR_write_src),
        .MEM_CSR_result      (MEM_CSR_result),
        .MEM_CSR_write       (MEM_CSR_write),
        .MEM_CSR_write_number(MEM_CSR_write_number),
        .MEM_CSR_write_data  (MEM_CSR_write_data),
        .MEM_TLB_operation   (MEM_TLB_operation),
        .MEM_invtlb_op       (MEM_invtlb_op),
        .MEM_refetch         (MEM_refetch),
        .MEM_ereturn         (MEM_ereturn),
        .MEM_GPR_new         (MEM_GPR_new),
        .MEM_INT             (MEM_INT),
        .MEM_ADEF            (MEM_ADEF),
        .MEM_ALE             (MEM_ALE),
        .MEM_SYS             (MEM_SYS),
        .MEM_BRK             (MEM_BRK),
        .MEM_INE             (MEM_INE)
    );

    MEM_stage mem_stage (
        .done             (MEM_done),
        .exception        (MEM_exception),
        .data_sram_data_ok(data_sram_data_ok),
        .data_sram_rdata  (data_sram_rdata),
        .ALU_operation    (MEM_ALU_operation),
        .mul_result       (MEM_mul_result),
        .EXE_ALU_result   (MEM_EXE_ALU_result),
        .MEM_read         (MEM_MEM_read),
        .MEM_write        (MEM_MEM_write),
        .ALU_result       (MEM_ALU_result),
        .MEM_result       (MEM_MEM_result)
    );

    assign MEM_exception = {
        4'b0, MEM_INE, MEM_BRK, MEM_SYS, MEM_ALE, 1'b0, MEM_ADEF, 5'b0, MEM_INT
    };

    assign MEM_forward_data = {32{MEM_GPR_write_src[`GPR_WRITE_SRC_CSR]}} & MEM_CSR_result |
                              {32{MEM_GPR_write_src[`GPR_WRITE_SRC_ALU]}} & MEM_ALU_result;

    WB_reg wb_reg (
        .clk                 (clk),
        .reset               (reset),
        .flush               (flush),
        .WB_done             (WB_done),
        .MEM_to_WB_valid     (MEM_to_WB_valid),
        .WB_valid            (WB_valid),
        .WB_ready            (WB_ready),
        .MEM_PC              (MEM_PC),
        .MEM_rj_data         (MEM_rj_data),
        .MEM_rkd_data        (MEM_rkd_data),
        .MEM_ALU_result      (MEM_ALU_result),
        .MEM_MEM_result      (MEM_MEM_result),
        .MEM_CSR_result      (MEM_CSR_result),
        .MEM_GPR_write       (MEM_GPR_write),
        .MEM_GPR_write_num   (MEM_GPR_write_num),
        .MEM_GPR_write_src   (MEM_GPR_write_src),
        .MEM_CSR_write       (MEM_CSR_write),
        .MEM_CSR_write_number(MEM_CSR_write_number),
        .MEM_CSR_write_data  (MEM_CSR_write_data),
        .MEM_TLB_operation   (MEM_TLB_operation),
        .MEM_invtlb_op       (MEM_invtlb_op),
        .MEM_ereturn         (MEM_ereturn),
        .MEM_refetch         (MEM_refetch),
        .MEM_INT             (MEM_INT),
        .MEM_ADEF            (MEM_ADEF),
        .MEM_ALE             (MEM_ALE),
        .MEM_SYS             (MEM_SYS),
        .MEM_BRK             (MEM_BRK),
        .MEM_INE             (MEM_INE),
        .WB_PC               (WB_PC),
        .WB_rj_data          (WB_rj_data),
        .WB_rkd_data         (WB_rkd_data),
        .WB_ALU_result       (WB_ALU_result),
        .WB_MEM_result       (WB_MEM_result),
        .WB_CSR_result       (WB_CSR_result),
        .WB_GPR_write        (WB_GPR_write),
        .WB_GPR_write_num    (WB_GPR_write_num),
        .WB_GPR_write_src    (WB_GPR_write_src),
        .WB_CSR_write        (WB_CSR_write),
        .WB_CSR_write_number (WB_CSR_write_number),
        .WB_CSR_write_data   (WB_CSR_write_data),
        .WB_TLB_operation    (WB_TLB_operation),
        .WB_invtlb_op        (WB_invtlb_op),
        .WB_ereturn          (WB_ereturn),
        .WB_refetch          (WB_refetch),
        .WB_INT              (WB_INT),
        .WB_ADEF             (WB_ADEF),
        .WB_ALE              (WB_ALE),
        .WB_SYS              (WB_SYS),
        .WB_BRK              (WB_BRK),
        .WB_INE              (WB_INE)
    );

    WB_stage wb_stage (
        .valid           (WB_valid),
        .done            (WB_done),
        .exception       (WB_exception),
        .ALU_result      (WB_ALU_result),
        .MEM_result      (WB_MEM_result),
        .CSR_result      (WB_CSR_result),
        .GPR_write       (WB_GPR_write),
        .GPR_write_src   (WB_GPR_write_src),
        .CSR_write       (WB_CSR_write),
        .GPR_write_enable(WB_GPR_write_enable),
        .GPR_write_data  (WB_GPR_write_data),
        .CSR_write_enable(WB_CSR_write_enable)
    );

    assign WB_exception = {4'b0, WB_INE, WB_BRK, WB_SYS, WB_ALE, 1'b0, WB_ADEF, 5'b0, WB_INT};

    // assign WB_forward_data   = WB_GPR_write_data;

    CSRF #(
        .TLB_ENTRIES(`TLB_ENTRIES)
    ) csr_file (
        .clk          (clk),
        .reset        (reset),
        .read_number  (ID_CSR_number),
        .read_data    (ID_CSR_read_data),
        .write_number (WB_CSR_write_number),
        .write_enable (WB_CSR_write_enable),
        .write_data   (WB_CSR_write_data),
        .counter      (ID_CSR_counter),
        .da           (DA),
        .pg           (PG),
        .asid         (ASID),
        .plv          (PLV),
        .plv0         (PLV0),
        .pseg0        (PSEG0),
        .vseg0        (VSEG0),
        .plv1         (PLV1),
        .pseg1        (PSEG1),
        .vseg1        (VSEG1),
        .TLB_operation({`TLB_OP_WIDTH{WB_valid & ~|WB_exception}} & WB_TLB_operation),
        .TLB_s_hit    (TLB_s_hit),
        .TLB_s_index  (TLB_s_index),
        .TLB_r_hi     (TLB_r_hi),
        .TLB_r_lo0    (TLB_r_lo0),
        .TLB_r_lo1    (TLB_r_lo1),
        .TLB_rw_index (TLB_rw_index),
        .TLB_sw_hi    (TLB_sw_hi),
        .TLB_w_lo0    (TLB_w_lo0),
        .TLB_w_lo1    (TLB_w_lo1),
        .hw_int       (8'b0),
        .ip_int       (1'b0),
        .interupt     (request),
        .exception    (exception),
        .ereturn      (ereturn),
        .PC           (PC),
        .vaddr        (WB_ALU_result),
        .eentry       (eentry),
        .eraddr       (eraddr),
        .rentry       (rentry)
    );

    MMU #(
        .TLB_ENTRIES(`TLB_ENTRIES)
    ) mmu (
        .clk          (clk),
        .TLB_operation({`TLB_OP_WIDTH{WB_valid & ~|WB_exception}} & WB_TLB_operation),
        .invtlb_vaddr (WB_rkd_data),
        .invtlb_asid  (WB_rj_data),
        .invtlb_op    (WB_invtlb_op),
        .TLB_rw_index (TLB_rw_index),
        .TLB_sw_hi    (TLB_sw_hi),
        .TLB_w_lo0    (TLB_w_lo0),
        .TLB_w_lo1    (TLB_w_lo1),
        .TLB_s_hit    (TLB_s_hit),
        .TLB_s_index  (TLB_s_index),
        .TLB_r_hi     (TLB_r_hi),
        .TLB_r_lo0    (TLB_r_lo0),
        .TLB_r_lo1    (TLB_r_lo1),
        .CSR_da       (DA),
        .CSR_pg       (PG),
        .CSR_asid     (ASID),
        .CSR_plv      (PLV),
        .DMW0_plv     (PLV0),
        .DMW0_pseg    (PSEG0),
        .DMW0_vseg    (VSEG0),
        .DMW1_plv     (PLV1),
        .DMW1_pseg    (PSEG1),
        .DMW1_vseg    (VSEG1),
        .inst_fetch   (inst_sram_req),
        .inst_vaddr   (inst_sram_vaddr),
        .inst_paddr   (inst_sram_paddr),
        .data_load    (data_sram_req & ~data_sram_wr),
        .data_store   (data_sram_req & data_sram_wr),
        .data_vaddr   (data_sram_vaddr),
        .data_paddr   (data_sram_paddr),
        .PIL          (EXE_PIL),
        .PIS          (EXE_PIS),
        .PIF          (ID_PIF),
        .PME          (EXE_PME),
        .inst_PPI     (ID_PPI),
        .data_PPI     (EXE_PPI),
        .inst_TLBR    (ID_TLBR),
        .data_TLBR    (EXE_TLBR)
    );

    assign PC                = WB_PC;
    assign exception         = {`EXCEPTION_WIDTH{WB_valid}} & WB_exception;
    assign ereturn           = WB_valid & WB_ereturn;
    assign refetch           = WB_valid & WB_refetch;
    assign rtarget           = WB_PC + 3'h4;
    assign flush             = WB_valid & (|WB_exception | WB_ereturn | WB_refetch);

    assign debug_wb_pc       = WB_PC;
    assign debug_wb_rf_we    = {4{WB_GPR_write_enable}};
    assign debug_wb_rf_wnum  = WB_GPR_write_num;
    assign debug_wb_rf_wdata = WB_GPR_write_data;
endmodule
