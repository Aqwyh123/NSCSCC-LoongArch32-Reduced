`include "macros.h"

module mycpu_top (
    input  wire        aclk,
    input  wire        aresetn,
`ifdef CHIPLAB
    input  wire [ 7:0] intrpt,
`endif
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
    wire clk;
    wire reset;
`ifndef CHIPLAB
    wire [7:0] intrpt = 8'h0;
`endif
    // inst MMU signals
    wire                            inst_fetch;
    wire [                    31:0] inst_vaddr;
    wire [                    31:0] inst_paddr;
    // inst sram interface
    wire                            inst_sram_req;
    wire                            inst_sram_wr;
    wire [                     1:0] inst_sram_size;
    wire [                    31:0] inst_sram_addr;
    wire [                     3:0] inst_sram_wstrb;
    wire [                    31:0] inst_sram_wdata;
    wire                            inst_sram_addr_ok;
    wire                            inst_sram_data_ok;
    wire [                    31:0] inst_sram_rdata;
    // data MMU signals
    wire                            data_load;
    wire                            data_store;
    wire [                    31:0] data_vaddr;
    wire [                    31:0] data_paddr;
    // data sram interface
    wire                            data_sram_req;
    wire                            data_sram_wr;
    wire [                     1:0] data_sram_size;
    wire [                    31:0] data_sram_addr;
    wire [                     3:0] data_sram_wstrb;
    wire [                    31:0] data_sram_wdata;
    wire                            data_sram_addr_ok;
    wire                            data_sram_data_ok;
    wire [                    31:0] data_sram_rdata;

    wire [                    31:0] PC;
    wire                            flush;
    wire [    `EXCEPTION_WIDTH-1:0] exception;
    wire                            interupt;
    wire                            ereturn;
    wire                            idle;
    wire                            refetch;
    wire [                    31:0] eentry;
    wire [                    31:0] eraddr;
    wire [                    31:0] rsource;

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
    wire [$clog2(`TLB_ENTRIES)-1:0] TLB_s_index;
    wire [       `TLBEHI_WIDTH-1:0] TLB_r_hi;
    wire [       `TLBELO_WIDTH-1:0] TLB_r_lo0;
    wire [       `TLBELO_WIDTH-1:0] TLB_r_lo1;
    wire [$clog2(`TLB_ENTRIES)-1:0] TLB_rw_index;
    wire [       `TLBEHI_WIDTH-1:0] TLB_sw_hi;
    wire [       `TLBELO_WIDTH-1:0] TLB_w_lo0;
    wire [       `TLBELO_WIDTH-1:0] TLB_w_lo1;
    wire [$clog2(`TLB_ENTRIES)-1:0] TLB_f_index;

    wire                            pre_IF_PIF;
    wire                            pre_IF_PPI;
    wire                            pre_IF_TLBR;

    wire                            IF_to_ID_valid;

    wire [                    31:0] IF_PC;
    wire [                    31:0] IF_inst;
    wire                            IF_PIF;
    wire                            IF_PPI;
    wire                            IF_ADEF;
    wire                            IF_TLBR;
    // wire [    `EXCEPTION_WIDTH-1:0] IF_exception;

    wire                            ID_done;
    wire                            ID_valid;
    wire                            ID_ready;
    wire                            ID_to_EXE_valid;

    wire [                    31:0] ID_PC;
    wire [                    31:0] ID_inst;
    wire [    `EXCEPTION_WIDTH-1:0] ID_exception;
    wire                            ID_ereturn;
    wire                            ID_idle;
    wire                            ID_refetch;
    wire                            ID_INT;
    wire                            ID_PIF;
    wire                            ID_IF_PPI;
    wire                            ID_ADEF;
    wire                            ID_SYS;
    wire                            ID_BRK;
    wire                            ID_INE;
    wire                            ID_IPE;
    wire                            ID_IF_TLBR;

    wire                            ID_stall;
    wire                            ID_GPR_stall;
    wire                            ID_CSR_stall;
    wire                            ID_int_stall;
    wire                            ID_barrier_stall;
    wire                            ID_data_stall;
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
    wire [                    31:0] ID_imm;

    wire                            ID_ALU_src1_is_PC;
    wire                            ID_ALU_src2_is_imm;
    wire [       `ALU_OP_WIDTH-1:0] ID_ALU_operation;
    wire                            ID_mul_div_unsigned;

    wire [     `MEM_READ_WIDTH-1:0] ID_MEM_read;
    wire [    `MEM_WRITE_WIDTH-1:0] ID_MEM_write;
    wire [      `MEM_BAR_WIDTH-1:0] ID_MEM_barrier;

    wire [   `CSR_NUMBER_WIDTH-1:0] ID_CSR_number;
    wire [                    31:0] ID_CSR_read_data;
    wire [                    63:0] ID_CSR_counter;
    wire [                    31:0] ID_CSR_result;
    wire                            ID_CSR_write;
    wire                            ID_CSR_write_mask;
    wire                            ID_CSR_use;

    wire [       `TLB_OP_WIDTH-1:0] ID_TLB_operation;

    wire [ `CACHE_TARGET_WIDTH-1:0] ID_cache_target;
    wire [     `CACHE_OP_WIDTH-1:0] ID_cache_operation;

    wire                            EXE_done;
    wire                            EXE_valid;
    wire                            EXE_ready;
    wire                            EXE_to_MEM_valid;

    wire [                    31:0] EXE_PC;
`ifdef CHIPLAB
    wire [31:0] EXE_inst;
`endif
    wire [    `EXCEPTION_WIDTH-1:0] EXE_exception;
    wire                            EXE_ereturn;
    wire                            EXE_idle;
    wire                            EXE_refetch;
    wire                            EXE_INT;
    wire                            EXE_PIL;
    wire                            EXE_PIS;
    wire                            EXE_PIF;
    wire                            EXE_PME;
    wire                            EXE_IF_PPI;
    wire                            EXE_PPI;
    wire                            EXE_ADEF;
    wire                            EXE_ALE;
    wire                            EXE_SYS;
    wire                            EXE_BRK;
    wire                            EXE_INE;
    wire                            EXE_IPE;
    wire                            EXE_IF_TLBR;
    wire                            EXE_TLBR;

    wire [                    31:0] EXE_rj_data;
    wire [                    31:0] EXE_rkd_data;
    wire [      `GPR_NEW_WIDTH-1:0] EXE_GPR_new;
    wire                            EXE_GPR_write;
    wire [                     4:0] EXE_GPR_write_num;
    wire [`GPR_WRITE_SRC_WIDTH-1:0] EXE_GPR_write_src;
    wire [                    31:0] EXE_imm;
    wire [                    31:0] EXE_forward_data;

    wire                            EXE_ALU_src1_is_PC;
    wire                            EXE_ALU_src2_is_imm;
    wire [       `ALU_OP_WIDTH-1:0] EXE_ALU_operation;
    wire                            EXE_mul_div_unsigned;
    wire [                    31:0] EXE_ALU_result;

    wire [     `MEM_READ_WIDTH-1:0] EXE_MEM_read;
    wire [    `MEM_WRITE_WIDTH-1:0] EXE_MEM_write;
    wire [      `MEM_BAR_WIDTH-1:0] EXE_MEM_barrier;
    wire [                    31:0] EXE_MEM_paddr = data_paddr;
    wire                            EXE_llbit;

`ifdef CHIPLAB
    wire [31:0] EXE_CSR_read_data;
    wire [63:0] EXE_CSR_counter;
`endif
    wire [                   31:0] EXE_CSR_result;
    wire                           EXE_CSR_write;
    wire [  `CSR_NUMBER_WIDTH-1:0] EXE_CSR_write_number;
    wire [                   31:0] EXE_CSR_write_data;

    wire [      `TLB_OP_WIDTH-1:0] EXE_TLB_operation;

    wire [`CACHE_TARGET_WIDTH-1:0] EXE_cache_target;
    wire [    `CACHE_OP_WIDTH-1:0] EXE_cache_operation;

    wire                           MEM_done;
    wire                           MEM_valid;
    wire                           MEM_ready;
    wire                           MEM_to_WB_valid;

    wire [                   31:0] MEM_PC;
`ifdef CHIPLAB
    wire [31:0] MEM_inst;
`endif
    wire [    `EXCEPTION_WIDTH-1:0] MEM_exception;
    wire                            MEM_ereturn;
    wire                            MEM_idle;
    wire                            MEM_refetch;
    wire                            MEM_INT;
    wire                            MEM_PIL;
    wire                            MEM_PIS;
    wire                            MEM_PIF;
    wire                            MEM_PME;
    wire                            MEM_IF_PPI;
    wire                            MEM_EXE_PPI;
    wire                            MEM_ADEF;
    wire                            MEM_ALE;
    wire                            MEM_SYS;
    wire                            MEM_BRK;
    wire                            MEM_INE;
    wire                            MEM_IPE;
    wire                            MEM_IF_TLBR;
    wire                            MEM_EXE_TLBR;

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
    wire [      `MEM_BAR_WIDTH-1:0] MEM_MEM_barrier;
`ifdef CHIPLAB
    wire [31:0] MEM_MEM_paddr;
`endif
    wire        MEM_llbit;
    wire [31:0] MEM_MEM_result;

`ifdef CHIPLAB
    wire [31:0] MEM_CSR_read_data;
    wire [63:0] MEM_CSR_counter;
`endif
    wire [                 31:0] MEM_CSR_result;
    wire                         MEM_CSR_write;
    wire [`CSR_NUMBER_WIDTH-1:0] MEM_CSR_write_number;
    wire                         EXE_CSR_write_mask;
    wire [                 31:0] MEM_CSR_write_data;

    wire [    `TLB_OP_WIDTH-1:0] MEM_TLB_operation;

    wire                         WB_done;
    wire                         WB_valid;
    wire                         WB_ready;

    wire [                 31:0] WB_PC;
`ifdef CHIPLAB
    wire [31:0] WB_inst;
`endif
    wire [    `EXCEPTION_WIDTH-1:0] WB_exception;
    wire                            WB_ereturn;
    wire                            WB_idle;
    wire                            WB_refetch;
    wire                            WB_INT;
    wire                            WB_PIL;
    wire                            WB_PIS;
    wire                            WB_PIF;
    wire                            WB_PME;
    wire                            WB_IF_PPI;
    wire                            WB_EXE_PPI;
    wire                            WB_ADEF;
    wire                            WB_ALE;
    wire                            WB_SYS;
    wire                            WB_BRK;
    wire                            WB_INE;
    wire                            WB_IPE;
    wire                            WB_IF_TLBR;
    wire                            WB_EXE_TLBR;

    wire [                    31:0] WB_rj_data;
    wire [                    31:0] WB_rkd_data;
    wire                            WB_GPR_write;
    wire                            WB_GPR_write_enable;
    wire [                     4:0] WB_GPR_write_num;
    wire [`GPR_WRITE_SRC_WIDTH-1:0] WB_GPR_write_src;
    wire [                    31:0] WB_GPR_write_data;
    // wire [                31:0] WB_forward_data;

    wire [                    31:0] WB_ALU_result;

    wire [     `MEM_READ_WIDTH-1:0] WB_MEM_read;
    wire [    `MEM_WRITE_WIDTH-1:0] WB_MEM_write;
`ifdef CHIPLAB
    wire [31:0] WB_MEM_paddr;
`endif
    wire        WB_llbit;
    wire [31:0] WB_MEM_result;

    wire        WB_llbit_write_enable;
    wire        WB_llbit_write_data;

`ifdef CHIPLAB
    wire [31:0] WB_CSR_read_data;
    wire [63:0] WB_CSR_counter;
`endif
    wire [                         31:0] WB_CSR_result;
    wire                                 WB_CSR_write;
    wire                                 WB_CSR_write_enable;
    wire [        `CSR_NUMBER_WIDTH-1:0] WB_CSR_write_number;
    wire [                         31:0] WB_CSR_write_data;

    wire [            `TLB_OP_WIDTH-1:0] WB_TLB_operation;
    wire [    `TLB_OP_READ:`TLB_OP_SRCH] WB_CSR_TLB_operation;
    wire [`TLB_OP_WIDTH-1:`TLB_OP_WRITE] WB_TLB_TLB_operation;

    AXI_Bridge axi_bridge (
        .aclk             (aclk),
        .aresetn          (aresetn),
        .clk              (clk),
        .reset            (reset),
        .inst_sram_req    (inst_sram_req),
        .inst_sram_wr     (inst_sram_wr),
        .inst_sram_size   (inst_sram_size),
        .inst_sram_addr   (inst_sram_addr),
        .inst_sram_wstrb  (inst_sram_wstrb),
        .inst_sram_wdata  (inst_sram_wdata),
        .inst_sram_addr_ok(inst_sram_addr_ok),
        .inst_sram_data_ok(inst_sram_data_ok),
        .inst_sram_rdata  (inst_sram_rdata),
        .data_sram_req    (data_sram_req),
        .data_sram_wr     (data_sram_wr),
        .data_sram_size   (data_sram_size),
        .data_sram_addr   (data_sram_addr),
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
        .idle             (idle),
        .interupt         (interupt),
        .refetch          (refetch),
        .eentry           (eentry),
        .eraddr           (eraddr),
        .rsource          (rsource),
        .bj_taken         (ID_bj_taken),
        .bj_stall         (ID_bj_stall),
        .bj_target        (ID_target_PC),
        .ID_ready         (ID_ready),
        .IF_to_ID_valid   (IF_to_ID_valid),
        .inst_fetch       (inst_fetch),
        .inst_vaddr       (inst_vaddr),
        .inst_paddr       (inst_paddr),
        .pre_IF_PIF       (pre_IF_PIF),
        .pre_IF_PPI       (pre_IF_PPI),
        .pre_IF_TLBR      (pre_IF_TLBR),
        .inst_sram_req    (inst_sram_req),
        .inst_sram_wr     (inst_sram_wr),
        .inst_sram_size   (inst_sram_size),
        .inst_sram_addr   (inst_sram_addr),
        .inst_sram_wstrb  (inst_sram_wstrb),
        .inst_sram_wdata  (inst_sram_wdata),
        .inst_sram_addr_ok(inst_sram_addr_ok),
        .inst_sram_data_ok(inst_sram_data_ok),
        .inst_sram_rdata  (inst_sram_rdata),
        .PC               (IF_PC),
        .inst             (IF_inst),
        .PIF              (IF_PIF),
        .PPI              (IF_PPI),
        .ADEF             (IF_ADEF),
        .TLBR             (IF_TLBR)
    );

    // assign IF_exception = {1'b0, IF_TLBR, 6'b0, IF_ADEF, 1'b0, IF_PPI, 1'b0, IF_PIF, 3'b0}

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
        .IF_inst        (IF_inst),
        .IF_PIF         (IF_PIF),
        .IF_PPI         (IF_PPI),
        .IF_ADEF        (IF_ADEF),
        .IF_TLBR        (IF_TLBR),
        .ID_PC          (ID_PC),
        .ID_inst        (ID_inst),
        .ID_PIF         (ID_PIF),
        .ID_IF_PPI      (ID_IF_PPI),
        .ID_ADEF        (ID_ADEF),
        .ID_IF_TLBR     (ID_IF_TLBR)
    );

    ID_stage id_stage (
        .valid           (ID_valid),
        .inst            (ID_inst),
        .plv             (PLV),
        .PC              (ID_PC),
        .jump            (ID_jump),
        .branch          (ID_branch),
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
        .MEM_barrier     (ID_MEM_barrier),
        .GPR_write       (ID_GPR_write),
        .GPR_write_num   (ID_GPR_write_num),
        .GPR_write_src   (ID_GPR_write_src),
        .CSR_write       (ID_CSR_write),
        .CSR_write_mask  (ID_CSR_write_mask),
        .TLB_operation   (ID_TLB_operation),
        .cache_target    (ID_cache_target),
        .cache_operation (ID_cache_operation),
        .GPR1_use        (ID_GPR1_use),
        .GPR2_use        (ID_GPR2_use),
        .GPR_new         (ID_GPR_new),
        .CSR_use         (ID_CSR_use),
        .bj_taken        (ID_bj_taken),
        .target_PC       (ID_target_PC),
        .imm             (ID_imm),
        .ereturn         (ID_ereturn),
        .idle            (ID_idle),
        .refetch         (ID_refetch),
        .SYS             (ID_SYS),
        .BRK             (ID_BRK),
        .INE             (ID_INE),
        .IPE             (ID_IPE)
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

    assign ID_INT = interupt & ~ID_int_stall;

    assign ID_exception = {
        1'b0,
        ID_IF_TLBR,
        ID_IPE,
        ID_INE,
        ID_BRK,
        ID_SYS,
        2'b0,
        ID_ADEF,
        1'b0,
        ID_IF_PPI,
        1'b0,
        IF_PIF,
        2'b0,
        ID_INT
    };

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

    assign ID_EXE_CSR = ID_CSR_use & EXE_CSR_write &
                       (ID_CSR_number == EXE_CSR_write_number |
                        ID_CSR_number == `CSR_PGD &
                       (EXE_CSR_write_number == `CSR_BADV |
                        EXE_CSR_write_number == `CSR_PGDL |
                        EXE_CSR_write_number == `CSR_PGDH));
    assign ID_MEM_CSR = ID_CSR_use & MEM_CSR_write &
                       (ID_CSR_number == MEM_CSR_write_number |
                        ID_CSR_number == `CSR_PGD &
                       (MEM_CSR_write_number == `CSR_BADV |
                        MEM_CSR_write_number == `CSR_PGDL |
                        MEM_CSR_write_number == `CSR_PGDH));
    assign ID_WB_CSR = ID_CSR_use & WB_CSR_write &
                      (ID_CSR_number == WB_CSR_write_number |
                       ID_CSR_number == `CSR_PGD &
                      (WB_CSR_write_number == `CSR_BADV |
                       WB_CSR_write_number == `CSR_PGDL |
                       WB_CSR_write_number == `CSR_PGDH));

    assign ID_EXE_int = EXE_CSR_write &
                       (EXE_CSR_write_number == `CSR_ECFG | EXE_CSR_write_number == `CSR_ESTAT |
                        EXE_CSR_write_number == `CSR_TCFG | EXE_CSR_write_number == `CSR_TICLR);
    assign ID_MEM_int = MEM_CSR_write &
                       (MEM_CSR_write_number == `CSR_ECFG | MEM_CSR_write_number == `CSR_ESTAT |
                        MEM_CSR_write_number == `CSR_TCFG  | MEM_CSR_write_number == `CSR_TICLR);
    assign ID_WB_int  = WB_CSR_write &
                       (WB_CSR_write_number == `CSR_ECFG | WB_CSR_write_number == `CSR_ESTAT |
                        WB_CSR_write_number == `CSR_TCFG | WB_CSR_write_number == `CSR_TICLR);

    assign ID_GPR_stall = EXE_valid & (ID_EXE_GPR1_A & ID_EXE_GPR1_T |
                                       ID_EXE_GPR2_A & ID_EXE_GPR2_T) |
                          MEM_valid & (ID_MEM_GPR1_A & ID_MEM_GPR1_T |
                                       ID_MEM_GPR2_A & ID_MEM_GPR2_T);

    assign ID_CSR_stall = EXE_valid & ID_EXE_CSR | MEM_valid & ID_MEM_CSR | WB_valid & ID_WB_CSR;

    assign ID_int_stall = EXE_valid & ID_EXE_int | MEM_valid & ID_MEM_int | WB_valid & ID_WB_int;

    assign ID_barrier_stall = ID_MEM_barrier[`MEM_BAR_DATA] &
                             (EXE_valid & (|EXE_MEM_read | |EXE_MEM_write) |
                              MEM_valid & (|MEM_MEM_read | |MEM_MEM_write));

    assign ID_data_stall = (|ID_MEM_read | |ID_MEM_write) &
                           (EXE_valid & EXE_MEM_barrier[`MEM_BAR_DATA] |
                            MEM_valid & MEM_MEM_barrier[`MEM_BAR_DATA]);

    // TODO: delay memory write
    assign ID_flush_stall = EXE_valid & (|EXE_exception | EXE_ereturn | | EXE_idle | EXE_refetch) |
                            MEM_valid & (|MEM_exception | MEM_ereturn | | MEM_idle | MEM_refetch);

    assign ID_bj_stall = ID_valid & ID_jump & (EXE_valid & ID_EXE_GPR1_A &
                        |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM] |
                         MEM_valid & ID_MEM_GPR1_A & MEM_GPR_new[`GPR_NEW_WB]) |
                         ID_valid & |ID_branch[`BRANCH_LTU:`BRANCH_EQ] &
                        (EXE_valid & (ID_EXE_GPR1_A | ID_EXE_GPR2_A) &
                        |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM] |
                         MEM_valid & (ID_MEM_GPR1_A | ID_MEM_GPR2_A) & MEM_GPR_new[`GPR_NEW_WB]);

    assign ID_stall = ID_GPR_stall | ID_CSR_stall | ID_barrier_stall | ID_data_stall |
                      ID_int_stall | ID_flush_stall;

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
`ifdef CHIPLAB
        .ID_inst             (ID_inst),
`endif
        .ID_imm              (ID_imm),
        .ID_rj_data          (ID_rj_data),
        .ID_rkd_data         (ID_rkd_data),
`ifdef CHIPLAB
        .ID_CSR_read_data    (ID_CSR_read_data),
        .ID_CSR_counter      (ID_CSR_counter),
`endif
        .ID_CSR_result       (ID_CSR_result),
        .ID_ALU_src1_is_PC   (ID_ALU_src1_is_PC),
        .ID_ALU_src2_is_imm  (ID_ALU_src2_is_imm),
        .ID_ALU_operation    (ID_ALU_operation),
        .ID_mul_div_unsigned (ID_mul_div_unsigned),
        .ID_MEM_read         (ID_MEM_read),
        .ID_MEM_write        (ID_MEM_write),
        .ID_MEM_barrier      (ID_MEM_barrier),
        .ID_GPR_write        (ID_GPR_write),
        .ID_GPR_write_num    (ID_GPR_write_num),
        .ID_GPR_write_src    (ID_GPR_write_src),
        .ID_CSR_write        (ID_CSR_write),
        .ID_CSR_write_number (ID_CSR_number),
        .ID_CSR_write_mask   (ID_CSR_write_mask),
        .ID_TLB_operation    (ID_TLB_operation),
        .ID_cache_target     (ID_cache_target),
        .ID_cache_operation  (ID_cache_operation),
        .ID_ereturn          (ID_ereturn),
        .ID_idle             (ID_idle),
        .ID_refetch          (ID_refetch),
        .ID_GPR_new          (ID_GPR_new),
        .ID_INT              (ID_INT),
        .ID_PIF              (ID_PIF),
        .ID_IF_PPI           (ID_IF_PPI),
        .ID_ADEF             (ID_ADEF),
        .ID_SYS              (ID_SYS),
        .ID_BRK              (ID_BRK),
        .ID_INE              (ID_INE),
        .ID_IPE              (ID_IPE),
        .ID_IF_TLBR          (ID_IF_TLBR),
        .EXE_PC              (EXE_PC),
`ifdef CHIPLAB
        .EXE_inst            (EXE_inst),
`endif
        .EXE_imm             (EXE_imm),
        .EXE_rj_data         (EXE_rj_data),
        .EXE_rkd_data        (EXE_rkd_data),
`ifdef CHIPLAB
        .EXE_CSR_read_data   (EXE_CSR_read_data),
        .EXE_CSR_counter     (EXE_CSR_counter),
`endif
        .EXE_CSR_result      (EXE_CSR_result),
        .EXE_ALU_src1_is_PC  (EXE_ALU_src1_is_PC),
        .EXE_ALU_src2_is_imm (EXE_ALU_src2_is_imm),
        .EXE_ALU_operation   (EXE_ALU_operation),
        .EXE_mul_div_unsigned(EXE_mul_div_unsigned),
        .EXE_MEM_read        (EXE_MEM_read),
        .EXE_MEM_write       (EXE_MEM_write),
        .EXE_MEM_barrier     (EXE_MEM_barrier),
        .EXE_GPR_write       (EXE_GPR_write),
        .EXE_GPR_write_num   (EXE_GPR_write_num),
        .EXE_GPR_write_src   (EXE_GPR_write_src),
        .EXE_CSR_write       (EXE_CSR_write),
        .EXE_CSR_write_number(EXE_CSR_write_number),
        .EXE_CSR_write_mask  (EXE_CSR_write_mask),
        .EXE_TLB_operation   (EXE_TLB_operation),
        .EXE_cache_target    (EXE_cache_target),
        .EXE_cache_operation (EXE_cache_operation),
        .EXE_ereturn         (EXE_ereturn),
        .EXE_idle            (EXE_idle),
        .EXE_refetch         (EXE_refetch),
        .EXE_GPR_new         (EXE_GPR_new),
        .EXE_INT             (EXE_INT),
        .EXE_PIF             (EXE_PIF),
        .EXE_IF_PPI          (EXE_IF_PPI),
        .EXE_ADEF            (EXE_ADEF),
        .EXE_SYS             (EXE_SYS),
        .EXE_BRK             (EXE_BRK),
        .EXE_INE             (EXE_INE),
        .EXE_IPE             (EXE_IPE),
        .EXE_IF_TLBR         (EXE_IF_TLBR)
    );

    EXE_stage exe_stage (
        .clk              (clk),
        .reset            (reset),
        .valid            (EXE_valid),
        .MEM_ready        (MEM_ready),
        .done             (EXE_done),
        .data_load        (data_load),
        .data_store       (data_store),
        .data_vaddr       (data_vaddr),
        .data_paddr       (data_paddr),
        .exception        (EXE_exception),
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
        .div_unsigned     (EXE_mul_div_unsigned),
        .MEM_read         (EXE_MEM_read),
        .MEM_write        (EXE_MEM_write),
        .llbit            (EXE_llbit),
        .CSR_read_data    (EXE_CSR_result),
        .CSR_write_mask   (EXE_CSR_write_mask),
        .cache_target     (EXE_cache_target),
        .cache_operation  (EXE_cache_operation),
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
        EXE_TLBR,
        EXE_IF_TLBR,
        EXE_IPE,
        EXE_INE,
        EXE_BRK,
        EXE_SYS,
        EXE_ALE,
        1'b0,
        EXE_ADEF,
        EXE_PPI,
        EXE_IF_PPI,
        EXE_PME,
        EXE_PIF,
        EXE_PIS,
        EXE_PIL,
        EXE_INT
    };

    assign EXE_forward_data = {32{EXE_GPR_write_src[`GPR_WRITE_SRC_LUI]}} & EXE_imm |
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
`ifdef CHIPLAB
        .EXE_inst            (EXE_inst),
`endif
        .EXE_rj_data         (EXE_rj_data),
        .EXE_rkd_data        (EXE_rkd_data),
`ifdef CHIPLAB
        .EXE_CSR_read_data   (EXE_CSR_read_data),
        .EXE_CSR_counter     (EXE_CSR_counter),
`endif
        .EXE_CSR_result      (EXE_CSR_result),
        .EXE_ALU_operation   (EXE_ALU_operation[`ALU_OP_MULH:`ALU_OP_MUL]),
        .EXE_ALU_result      (EXE_ALU_result),
        .EXE_MEM_read        (EXE_MEM_read),
        .EXE_MEM_write       (EXE_MEM_write),
        .EXE_MEM_barrier     (EXE_MEM_barrier),
`ifdef CHIPLAB
        .EXE_MEM_paddr       (EXE_MEM_paddr),
`endif
        .EXE_llbit           (EXE_llbit),
        .EXE_GPR_write       (EXE_GPR_write),
        .EXE_GPR_write_num   (EXE_GPR_write_num),
        .EXE_GPR_write_src   (EXE_GPR_write_src),
        .EXE_CSR_write       (EXE_CSR_write),
        .EXE_CSR_write_number(EXE_CSR_write_number),
        .EXE_CSR_write_data  (EXE_CSR_write_data),
        .EXE_TLB_operation   (EXE_TLB_operation),
        .EXE_ereturn         (EXE_ereturn),
        .EXE_idle            (EXE_idle),
        .EXE_refetch         (EXE_refetch),
        .EXE_GPR_new         (EXE_GPR_new),
        .EXE_INT             (EXE_INT),
        .EXE_PIL             (EXE_PIL),
        .EXE_PIS             (EXE_PIS),
        .EXE_PIF             (EXE_PIF),
        .EXE_PME             (EXE_PME),
        .EXE_IF_PPI          (EXE_IF_PPI),
        .EXE_PPI             (EXE_PPI),
        .EXE_ADEF            (EXE_ADEF),
        .EXE_ALE             (EXE_ALE),
        .EXE_SYS             (EXE_SYS),
        .EXE_BRK             (EXE_BRK),
        .EXE_INE             (EXE_INE),
        .EXE_IPE             (EXE_IPE),
        .EXE_IF_TLBR         (EXE_IF_TLBR),
        .EXE_TLBR            (EXE_TLBR),
        .MEM_PC              (MEM_PC),
`ifdef CHIPLAB
        .MEM_inst            (MEM_inst),
`endif
        .MEM_rj_data         (MEM_rj_data),
        .MEM_rkd_data        (MEM_rkd_data),
`ifdef CHIPLAB
        .MEM_CSR_read_data   (MEM_CSR_read_data),
        .MEM_CSR_counter     (MEM_CSR_counter),
`endif
        .MEM_CSR_result      (MEM_CSR_result),
        .MEM_ALU_operation   (MEM_ALU_operation),
        .MEM_EXE_ALU_result  (MEM_EXE_ALU_result),
        .MEM_MEM_read        (MEM_MEM_read),
        .MEM_MEM_write       (MEM_MEM_write),
        .MEM_MEM_barrier     (MEM_MEM_barrier),
`ifdef CHIPLAB
        .MEM_MEM_paddr       (MEM_MEM_paddr),
`endif
        .MEM_llbit           (MEM_llbit),
        .MEM_GPR_write       (MEM_GPR_write),
        .MEM_GPR_write_num   (MEM_GPR_write_num),
        .MEM_GPR_write_src   (MEM_GPR_write_src),
        .MEM_CSR_write       (MEM_CSR_write),
        .MEM_CSR_write_number(MEM_CSR_write_number),
        .MEM_CSR_write_data  (MEM_CSR_write_data),
        .MEM_TLB_operation   (MEM_TLB_operation),
        .MEM_ereturn         (MEM_ereturn),
        .MEM_idle            (MEM_idle),
        .MEM_refetch         (MEM_refetch),
        .MEM_GPR_new         (MEM_GPR_new),
        .MEM_INT             (MEM_INT),
        .MEM_PIL             (MEM_PIL),
        .MEM_PIS             (MEM_PIS),
        .MEM_PIF             (MEM_PIF),
        .MEM_PME             (MEM_PME),
        .MEM_IF_PPI          (MEM_IF_PPI),
        .MEM_EXE_PPI         (MEM_EXE_PPI),
        .MEM_ADEF            (MEM_ADEF),
        .MEM_ALE             (MEM_ALE),
        .MEM_SYS             (MEM_SYS),
        .MEM_BRK             (MEM_BRK),
        .MEM_INE             (MEM_INE),
        .MEM_IPE             (MEM_IPE),
        .MEM_IF_TLBR         (MEM_IF_TLBR),
        .MEM_EXE_TLBR        (MEM_EXE_TLBR)
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
        .llbit            (MEM_llbit),
        .ALU_result       (MEM_ALU_result),
        .MEM_result       (MEM_MEM_result)
    );

    assign MEM_exception = {
        MEM_EXE_TLBR,
        MEM_IF_TLBR,
        MEM_IPE,
        MEM_INE,
        MEM_BRK,
        MEM_SYS,
        MEM_ALE,
        1'b0,
        MEM_ADEF,
        MEM_EXE_PPI,
        MEM_IF_PPI,
        MEM_PME,
        MEM_PIF,
        MEM_PIS,
        MEM_PIL,
        MEM_INT
    };

    assign MEM_forward_data = {32{MEM_GPR_write_src[`GPR_WRITE_SRC_CSR]}} & MEM_CSR_result |
                              {32{MEM_GPR_write_src[`GPR_WRITE_SRC_ALU]}} & MEM_ALU_result |
                              {31'b0, MEM_GPR_write_src[`GPR_WRITE_SRC_COND] & MEM_llbit};

    WB_reg wb_reg (
        .clk                 (clk),
        .reset               (reset),
        .flush               (flush),
        .WB_done             (WB_done),
        .MEM_to_WB_valid     (MEM_to_WB_valid),
        .WB_valid            (WB_valid),
        .WB_ready            (WB_ready),
        .MEM_PC              (MEM_PC),
`ifdef CHIPLAB
        .MEM_inst            (MEM_inst),
`endif
        .MEM_rj_data         (MEM_rj_data),
        .MEM_rkd_data        (MEM_rkd_data),
`ifdef CHIPLAB
        .MEM_CSR_read_data   (MEM_CSR_read_data),
        .MEM_CSR_counter     (MEM_CSR_counter),
`endif
        .MEM_CSR_result      (MEM_CSR_result),
        .MEM_ALU_result      (MEM_ALU_result),
        .MEM_MEM_read        (MEM_MEM_read),
        .MEM_MEM_write       (MEM_MEM_write),
`ifdef CHIPLAB
        .MEM_MEM_paddr       (MEM_MEM_paddr),
`endif
        .MEM_llbit           (MEM_llbit),
        .MEM_MEM_result      (MEM_MEM_result),
        .MEM_GPR_write       (MEM_GPR_write),
        .MEM_GPR_write_num   (MEM_GPR_write_num),
        .MEM_GPR_write_src   (MEM_GPR_write_src),
        .MEM_CSR_write       (MEM_CSR_write),
        .MEM_CSR_write_number(MEM_CSR_write_number),
        .MEM_CSR_write_data  (MEM_CSR_write_data),
        .MEM_TLB_operation   (MEM_TLB_operation),
        .MEM_ereturn         (MEM_ereturn),
        .MEM_idle            (MEM_idle),
        .MEM_refetch         (MEM_refetch),
        .MEM_INT             (MEM_INT),
        .MEM_PIL             (MEM_PIL),
        .MEM_PIS             (MEM_PIS),
        .MEM_PIF             (MEM_PIF),
        .MEM_PME             (MEM_PME),
        .MEM_IF_PPI          (MEM_IF_PPI),
        .MEM_EXE_PPI         (MEM_EXE_PPI),
        .MEM_ADEF            (MEM_ADEF),
        .MEM_ALE             (MEM_ALE),
        .MEM_SYS             (MEM_SYS),
        .MEM_BRK             (MEM_BRK),
        .MEM_INE             (MEM_INE),
        .MEM_IPE             (MEM_IPE),
        .MEM_IF_TLBR         (MEM_IF_TLBR),
        .MEM_EXE_TLBR        (MEM_EXE_TLBR),
        .WB_PC               (WB_PC),
`ifdef CHIPLAB
        .WB_inst             (WB_inst),
`endif
        .WB_rj_data          (WB_rj_data),
        .WB_rkd_data         (WB_rkd_data),
`ifdef CHIPLAB
        .WB_CSR_read_data    (WB_CSR_read_data),
        .WB_CSR_counter      (WB_CSR_counter),
`endif
        .WB_CSR_result       (WB_CSR_result),
        .WB_ALU_result       (WB_ALU_result),
        .WB_MEM_write        (WB_MEM_write),
`ifdef CHIPLAB
        .WB_MEM_paddr        (WB_MEM_paddr),
`endif
        .WB_llbit            (WB_llbit),
        .WB_MEM_read         (WB_MEM_read),
        .WB_MEM_result       (WB_MEM_result),
        .WB_GPR_write        (WB_GPR_write),
        .WB_GPR_write_num    (WB_GPR_write_num),
        .WB_GPR_write_src    (WB_GPR_write_src),
        .WB_CSR_write        (WB_CSR_write),
        .WB_CSR_write_number (WB_CSR_write_number),
        .WB_CSR_write_data   (WB_CSR_write_data),
        .WB_TLB_operation    (WB_TLB_operation),
        .WB_ereturn          (WB_ereturn),
        .WB_idle             (WB_idle),
        .WB_refetch          (WB_refetch),
        .WB_INT              (WB_INT),
        .WB_PIL              (WB_PIL),
        .WB_PIS              (WB_PIS),
        .WB_PIF              (WB_PIF),
        .WB_PME              (WB_PME),
        .WB_IF_PPI           (WB_IF_PPI),
        .WB_EXE_PPI          (WB_EXE_PPI),
        .WB_ADEF             (WB_ADEF),
        .WB_ALE              (WB_ALE),
        .WB_SYS              (WB_SYS),
        .WB_BRK              (WB_BRK),
        .WB_INE              (WB_INE),
        .WB_IPE              (WB_IPE),
        .WB_IF_TLBR          (WB_IF_TLBR),
        .WB_EXE_TLBR         (WB_EXE_TLBR)
    );

    WB_stage wb_stage (
        .valid             (WB_valid),
        .done              (WB_done),
        .exception         (WB_exception),
        .CSR_result        (WB_CSR_result),
        .ALU_result        (WB_ALU_result),
        .llbit             (WB_llbit),
        .MEM_result        (WB_MEM_result),
        .MEM_read          (WB_MEM_read),
        .MEM_write         (WB_MEM_write),
        .GPR_write         (WB_GPR_write),
        .GPR_write_src     (WB_GPR_write_src),
        .CSR_write         (WB_CSR_write),
        .TLB_operation     (WB_TLB_operation),
        .llbit_write_enable(WB_llbit_write_enable),
        .llbit_write_data  (WB_llbit_write_data),
        .GPR_write_enable  (WB_GPR_write_enable),
        .GPR_write_data    (WB_GPR_write_data),
        .CSR_write_enable  (WB_CSR_write_enable),
        .CSR_TLB_operation (WB_CSR_TLB_operation),
        .TLB_TLB_operation (WB_TLB_TLB_operation)
    );

    assign WB_exception = {
        WB_EXE_TLBR,
        WB_IF_TLBR,
        WB_IPE,
        WB_INE,
        WB_BRK,
        WB_SYS,
        WB_ALE,
        1'b0,
        WB_ADEF,
        WB_EXE_PPI,
        WB_IF_PPI,
        WB_PME,
        WB_PIF,
        WB_PIS,
        WB_PIL,
        WB_INT
    };

    // assign WB_forward_data   = WB_GPR_write_data;

    CSRF #(
        .TLB_ENTRIES(`TLB_ENTRIES)
    ) csr_file (
        .clk               (clk),
        .reset             (reset),
        .read_number       (ID_CSR_number),
        .read_data         (ID_CSR_read_data),
        .write_number      (WB_CSR_write_number),
        .write_enable      (WB_CSR_write_enable),
        .write_data        (WB_CSR_write_data),
        .counter           (ID_CSR_counter),
        .da                (DA),
        .pg                (PG),
        .asid              (ASID),
        .plv               (PLV),
        .plv0              (PLV0),
        .pseg0             (PSEG0),
        .vseg0             (VSEG0),
        .plv1              (PLV1),
        .pseg1             (PSEG1),
        .vseg1             (VSEG1),
        .TLB_operation     (WB_CSR_TLB_operation),
        .TLB_s_hit         (TLB_s_hit),
        .TLB_s_index       (TLB_s_index),
        .TLB_r_hi          (TLB_r_hi),
        .TLB_r_lo0         (TLB_r_lo0),
        .TLB_r_lo1         (TLB_r_lo1),
        .TLB_rw_index      (TLB_rw_index),
        .TLB_sw_hi         (TLB_sw_hi),
        .TLB_w_lo0         (TLB_w_lo0),
        .TLB_w_lo1         (TLB_w_lo1),
        .TLB_f_index       (TLB_f_index),
        .hw_int            (intrpt),
        .ip_int            (1'b0),
        .llbit             (EXE_llbit),
        .paddr             (EXE_MEM_paddr),
        .llbit_write_enable(WB_llbit_write_enable),
        .llbit_write_data  (WB_llbit_write_data),
        .interupt          (interupt),
        .exception         (exception),
        .ereturn           (ereturn),
        .PC                (PC),
        .vaddr             (WB_ALU_result),
        .eentry            (eentry),
        .eraddr            (eraddr)
    );

    MMU #(
        .TLB_ENTRIES(`TLB_ENTRIES)
    ) mmu (
        .clk          (clk),
        .TLB_operation(WB_TLB_TLB_operation),
        .invtlb_vaddr (WB_rkd_data),
        .invtlb_asid  (WB_rj_data),
        .TLB_rw_index (TLB_rw_index),
        .TLB_sw_hi    (TLB_sw_hi),
        .TLB_w_lo0    (TLB_w_lo0),
        .TLB_w_lo1    (TLB_w_lo1),
        .TLB_s_hit    (TLB_s_hit),
        .TLB_s_index  (TLB_s_index),
        .TLB_r_hi     (TLB_r_hi),
        .TLB_r_lo0    (TLB_r_lo0),
        .TLB_r_lo1    (TLB_r_lo1),
        .TLB_f_index  (TLB_f_index),
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
        .inst_fetch   (inst_fetch),
        .inst_vaddr   (inst_vaddr),
        .inst_paddr   (inst_paddr),
        .data_load    (data_load),
        .data_store   (data_store),
        .data_vaddr   (data_vaddr),
        .data_paddr   (data_paddr),
        .PIL          (EXE_PIL),
        .PIS          (EXE_PIS),
        .PIF          (pre_IF_PIF),
        .PME          (EXE_PME),
        .inst_PPI     (pre_IF_PPI),
        .data_PPI     (EXE_PPI),
        .inst_TLBR    (pre_IF_TLBR),
        .data_TLBR    (EXE_TLBR)
    );

    assign PC                = WB_PC;
    assign exception         = {`EXCEPTION_WIDTH{WB_valid}} & WB_exception;
    assign ereturn           = WB_valid & WB_ereturn;
    assign idle              = WB_valid & WB_idle & ~WB_exception[`EXCEPTION_IPE];
    assign refetch           = WB_valid & WB_refetch;
    assign rsource           = WB_PC;
    assign flush             = WB_valid & (|WB_exception | WB_ereturn | WB_idle | WB_refetch);

    assign debug_wb_pc       = WB_PC;
    assign debug_wb_rf_we    = {4{WB_GPR_write_enable}};
    assign debug_wb_rf_wnum  = WB_GPR_write_num;
    assign debug_wb_rf_wdata = WB_GPR_write_data;
endmodule
