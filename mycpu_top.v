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

    wire [                    31:0] PC;
    wire                            flush;
    wire [    `EXCEPTION_WIDTH-1:0] exception;
    wire                            ereturn;
    wire                            refetch;
    wire                            request;
    wire [                    31:0] eentry;
    wire [                    31:0] eraddr;
    wire [                    31:0] rentry;
    wire [                    31:0] rsource;

    wire [                     1:0] PLV;
    wire                            DA;
    wire                            PG;
    wire [                     1:0] DATF;
    wire [                     1:0] DATM;
    wire [                     9:0] ASID;
    wire [                     1:0] PLV0;
    wire [                     2:0] PSEG0;
    wire [                     2:0] VSEG0;
    wire [                     1:0] MAT0;
    wire [                     1:0] PLV1;
    wire [                     2:0] PSEG1;
    wire [                     2:0] VSEG1;
    wire [                     1:0] MAT1;

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

    wire                            inst_req;
    wire [                     4:0] inst_op;
    wire [                    31:0] inst_vaddr;
    wire [                     2:0] inst_access_size;
    wire [   `CACHE_STRB_WIDTH-1:0] inst_wstrb;
    wire [   `CACHE_DATA_WIDTH-1:0] inst_wdata;
    wire                            inst_addr_ok;
    wire                            inst_data_ok;
    wire [   `CACHE_DATA_WIDTH-1:0] inst_rdata;

    wire [                     2:0] inst_search_op;
    wire [                    31:0] inst_paddr;
    wire [                     1:0] inst_access_type;

    wire                            inst_cacop_req;
    wire [                     4:0] inst_cacop_op;
    wire [                    31:0] inst_cacop_vaddr;

    wire                            ICache_mem_rd_req;
    wire [                     2:0] ICache_mem_rd_type;
    wire [                    31:0] ICache_mem_rd_addr;
    wire                            ICache_mem_rd_rdy;
    wire                            ICache_mem_ret_valid;
    wire                            ICache_mem_ret_last;
    wire [                    31:0] ICache_mem_ret_data;

    wire                            data_req;
    wire [                     4:0] data_op;
    wire [                    31:0] data_vaddr;
    wire [                     2:0] data_access_size;
    wire [   `CACHE_STRB_WIDTH-1:0] data_wstrb;
    wire [   `CACHE_DATA_WIDTH-1:0] data_wdata;
    wire                            data_addr_ok;
    wire                            data_data_ok;
    wire [   `CACHE_DATA_WIDTH-1:0] data_rdata;

    wire [                     2:0] data_search_op;
    wire [                    31:0] data_paddr;
    wire [                     1:0] data_access_type;

    wire                            DCache_mem_rd_req;
    wire [                     2:0] DCache_mem_rd_type;
    wire [                    31:0] DCache_mem_rd_addr;
    wire                            DCache_mem_rd_rdy;
    wire                            DCache_mem_ret_valid;
    wire                            DCache_mem_ret_last;
    wire [                    31:0] DCache_mem_ret_data;
    wire                            DCache_mem_wr_req;
    wire [                     2:0] DCache_mem_wr_type;
    wire [                    31:0] DCache_mem_wr_addr;
    wire [                     3:0] DCache_mem_wr_wstrb;
    wire [                   127:0] DCache_mem_wr_data;
    wire                            DCache_mem_wr_rdy;
    wire                            DCache_mem_wr_resp;

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
    wire                            ID_refetch;
    wire                            ID_INT;
    wire                            ID_PIF;
    wire                            ID_IF_PPI;
    wire                            ID_ADEF;
    wire                            ID_SYS;
    wire                            ID_BRK;
    wire                            ID_INE;
    wire                            ID_IF_TLBR;

    wire                            ID_stall;
    wire                            ID_GPR_stall;
    wire                            ID_CSR_stall;
    wire                            ID_TLB_stall;
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
    wire                            ID_EXE_TLB;
    wire                            ID_MEM_TLB;
    wire                            ID_WB_TLB;
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
    wire [ `CACHE_TARGET_WIDTH-1:0] ID_cache_target;
    wire [     `CACHE_OP_WIDTH-1:0] ID_cache_operation;

    wire [   `CSR_NUMBER_WIDTH-1:0] ID_CSR_number;
    wire [                    31:0] ID_CSR_read_data;
    wire [                    63:0] ID_CSR_counter;
    wire [                    31:0] ID_CSR_result;
    wire                            ID_CSR_write;
    wire                            ID_CSR_write_mask;
    wire                            ID_CSR_use;

    wire [       `TLB_OP_WIDTH-1:0] ID_TLB_operation;

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
    wire                            EXE_IF_TLBR;
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
    wire [ `CACHE_TARGET_WIDTH-1:0] EXE_cache_target;
    wire [     `CACHE_OP_WIDTH-1:0] EXE_cache_operation;

`ifdef CHIPLAB
    wire [31:0] EXE_MEM_paddr = data_paddr;
    wire [31:0] EXE_CSR_read_data;
    wire [63:0] EXE_CSR_counter;
`endif
    wire [                 31:0] EXE_CSR_result;
    wire                         EXE_CSR_write;
    wire [`CSR_NUMBER_WIDTH-1:0] EXE_CSR_write_number;
    wire [                 31:0] EXE_CSR_write_data;

    wire [    `TLB_OP_WIDTH-1:0] EXE_TLB_operation;

    wire                         MEM_done;
    wire                         MEM_valid;
    wire                         MEM_ready;
    wire                         MEM_to_WB_valid;

    wire [                 31:0] MEM_PC;
`ifdef CHIPLAB
    wire [31:0] MEM_inst;
`endif
    wire [    `EXCEPTION_WIDTH-1:0] MEM_exception;
    wire                            MEM_ereturn;
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
    wire [                    31:0] MEM_MEM_result;

`ifdef CHIPLAB
    wire [31:0] MEM_MEM_paddr;
    wire [31:0] MEM_CSR_read_data;
    wire [63:0] MEM_CSR_counter;
`endif
    wire [                   31:0] MEM_CSR_result;
    wire                           MEM_CSR_write;
    wire [  `CSR_NUMBER_WIDTH-1:0] MEM_CSR_write_number;
    wire                           EXE_CSR_write_mask;
    wire [                   31:0] MEM_CSR_write_data;

    wire [      `TLB_OP_WIDTH-1:0] MEM_TLB_operation;

    wire [`CACHE_TARGET_WIDTH-1:0] MEM_cache_target;

    wire                           WB_done;
    wire                           WB_valid;
    wire                           WB_ready;

    wire [                   31:0] WB_PC;
`ifdef CHIPLAB
    wire [31:0] WB_inst;
`endif
    wire [    `EXCEPTION_WIDTH-1:0] WB_exception;
    wire                            WB_ereturn;
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

`ifdef CHIPLAB
    wire [ `MEM_READ_WIDTH-1:0] WB_MEM_read;
    wire [`MEM_WRITE_WIDTH-1:0] WB_MEM_write;
    wire [                31:0] WB_MEM_paddr;
`endif
    wire [31:0] WB_MEM_result;
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
        .aclk                 (aclk),
        .aresetn              (aresetn),
        .clk                  (clk),
        .reset                (reset),
        // ICache
        .inst_sram_req        (ICache_mem_rd_req),
        .inst_sram_rd_type    (ICache_mem_rd_type),
        .inst_sram_addr       (ICache_mem_rd_addr),
        .inst_sram_addr_ok    (ICache_mem_rd_rdy),
        .inst_sram_data_ok    (ICache_mem_ret_valid),
        .inst_sram_rdata      (ICache_mem_ret_data),
        .inst_sram_ret_last   (ICache_mem_ret_last),
        .inst_sram_access_type(|inst_access_type),
        // DCache
        .data_sram_rd_req     (DCache_mem_rd_req),
        .data_sram_rd_type    (DCache_mem_rd_type),
        .data_sram_rd_addr    (DCache_mem_rd_addr),
        .data_sram_rd_addr_ok (DCache_mem_rd_rdy),
        .data_sram_ret_valid  (DCache_mem_ret_valid),
        .data_rdata           (DCache_mem_ret_data),
        .data_sram_ret_last   (DCache_mem_ret_last),
        .data_sram_wr_req     (DCache_mem_wr_req),
        .data_sram_wr_type    (DCache_mem_wr_type),
        .data_sram_wr_addr    (DCache_mem_wr_addr),
        .data_sram_wr_wstrb   (DCache_mem_wr_wstrb),
        .data_sram_wr_data    (DCache_mem_wr_data),
        .data_sram_wr_addr_ok (DCache_mem_wr_rdy),
        .data_sram_wr_resp    (DCache_mem_wr_resp),
        .data_sram_access_type(|data_access_type),
        .arid                 (arid),
        .araddr               (araddr),
        .arlen                (arlen),
        .arsize               (arsize),
        .arburst              (arburst),
        .arlock               (arlock),
        .arcache              (arcache),
        .arprot               (arprot),
        .arvalid              (arvalid),
        .arready              (arready),
        .rid                  (rid),
        .rdata                (rdata),
        .rresp                (rresp),
        .rlast                (rlast),
        .rvalid               (rvalid),
        .rready               (rready),
        .awid                 (awid),
        .awaddr               (awaddr),
        .awlen                (awlen),
        .awsize               (awsize),
        .awburst              (awburst),
        .awlock               (awlock),
        .awcache              (awcache),
        .awprot               (awprot),
        .awvalid              (awvalid),
        .awready              (awready),
        .wid                  (wid),
        .wdata                (wdata),
        .wstrb                (wstrb),
        .wlast                (wlast),
        .wvalid               (wvalid),
        .wready               (wready),
        .bid                  (bid),
        .bresp                (bresp),
        .bvalid               (bvalid),
        .bready               (bready)
    );

    cache icache (
        .clk        (clk),
        .reset      (reset),
        // IF_stage <-> ICache
        .valid      (inst_req | inst_cacop_req),
        .op         (inst_cacop_req ? inst_cacop_op : inst_op),
        .vaddr      (inst_cacop_req ? inst_cacop_vaddr : inst_vaddr),
        .access_size(inst_access_size),
        .wstrb      (inst_wstrb),
        .wdata      (inst_wdata),
        .addr_ok    (inst_addr_ok),
        .data_ok    (inst_data_ok),
        .rdata      (inst_rdata),
        // ICache <-> MMU
        .search_op  (inst_search_op),
        .paddr      (inst_paddr),
        .access_type(|inst_access_type),
        // ICache <-> AXI_Bridge
        .rd_req     (ICache_mem_rd_req),
        .rd_type    (ICache_mem_rd_type),
        .rd_addr    (ICache_mem_rd_addr),
        .rd_rdy     (ICache_mem_rd_rdy),
        .ret_valid  (ICache_mem_ret_valid),
        .ret_last   ({1'b0, ICache_mem_ret_last}),
        .ret_data   (ICache_mem_ret_data),
        .wr_req     (),
        .wr_type    (),
        .wr_addr    (),
        .wr_wstrb   (),
        .wr_data    (),
        .wr_rdy     (1'b1)
    );

    IF_stage if_stage (
        .clk             (clk),
        .reset           (reset),
        .exception       (exception),
        .ereturn         (ereturn),
        .refetch         (refetch),
        .eentry          (eentry),
        .eraddr          (eraddr),
        .rentry          (rentry),
        .rsource         (rsource),
        .bj_taken        (ID_bj_taken),
        .bj_stall        (ID_bj_stall),
        .bj_target       (ID_target_PC),
        .ID_ready        (ID_ready),
        .IF_to_ID_valid  (IF_to_ID_valid),
        // ICache interface
        .inst_req        (inst_req),
        .inst_op         (inst_op),
        .inst_access_size(inst_access_size),
        .inst_vaddr      (inst_vaddr),
        .inst_wstrb      (inst_wstrb),
        .inst_wdata      (inst_wdata),
        .inst_addr_ok    (inst_addr_ok),
        .inst_data_ok    (inst_data_ok),
        .inst_rdata      (inst_rdata),
        .pre_IF_PIF      (pre_IF_PIF),
        .pre_IF_PPI      (pre_IF_PPI),
        .pre_IF_TLBR     (pre_IF_TLBR),
        .PC              (IF_PC),
        .inst            (IF_inst),
        .PIF             (IF_PIF),
        .PPI             (IF_PPI),
        .ADEF            (IF_ADEF),
        .TLBR            (IF_TLBR)
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
        .cache_target    (ID_cache_target),
        .cache_operation (ID_cache_operation),
        .GPR1_use        (ID_GPR1_use),
        .GPR2_use        (ID_GPR2_use),
        .GPR_new         (ID_GPR_new),
        .CSR_use         (ID_CSR_use),
        .bj_taken        (ID_bj_taken),
        .target_PC       (ID_target_PC),
        .imm             (ID_imm),
        .link            (ID_link),
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

    assign ID_rj_data = EXE_valid & ID_EXE_GPR1_A & EXE_GPR_new[`GPR_NEW_EXE] ? EXE_forward_data : MEM_valid & ID_MEM_GPR1_A & |MEM_GPR_new[`GPR_NEW_MEM:`GPR_NEW_EXE] ? MEM_forward_data : ID_GPR_read_data1;
    assign ID_rkd_data = EXE_valid & ID_EXE_GPR2_A & EXE_GPR_new[`GPR_NEW_EXE] ? EXE_forward_data : MEM_valid & ID_MEM_GPR2_A & |MEM_GPR_new[`GPR_NEW_MEM:`GPR_NEW_EXE] ? MEM_forward_data : ID_GPR_read_data2;

    assign ID_INT = request & ~ID_int_stall;

    assign ID_exception = {1'b0, ID_IF_TLBR, 1'b0, ID_INE, ID_BRK, ID_SYS, 2'b0, ID_ADEF, 1'b0, ID_IF_PPI, 1'b0, IF_PIF, 2'b0, ID_INT};

    assign ID_EXE_GPR1_A = |EXE_GPR_write_num & EXE_GPR_write & ID_GPR_read_num1 == EXE_GPR_write_num;
    assign ID_EXE_GPR2_A = |EXE_GPR_write_num & EXE_GPR_write & ID_GPR_read_num2 == EXE_GPR_write_num;
    assign ID_MEM_GPR1_A = |MEM_GPR_write_num & MEM_GPR_write & ID_GPR_read_num1 == MEM_GPR_write_num;
    assign ID_MEM_GPR2_A = |MEM_GPR_write_num & MEM_GPR_write & ID_GPR_read_num2 == MEM_GPR_write_num;

    assign ID_EXE_GPR1_T = ID_GPR1_use & |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM];
    assign ID_EXE_GPR2_T = ID_GPR2_use & |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM];
    assign ID_MEM_GPR1_T = ID_GPR1_use & MEM_GPR_new[`GPR_NEW_WB];
    assign ID_MEM_GPR2_T = ID_GPR2_use & MEM_GPR_new[`GPR_NEW_WB];

    assign ID_EXE_CSR = ID_CSR_use & EXE_CSR_write & ID_CSR_number == EXE_CSR_write_number;
    assign ID_MEM_CSR = ID_CSR_use & MEM_CSR_write & ID_CSR_number == MEM_CSR_write_number;
    assign ID_WB_CSR = ID_CSR_use & WB_CSR_write & ID_CSR_number == WB_CSR_write_number;

    assign ID_EXE_TLB = ID_CSR_use & EXE_TLB_operation[`TLB_OP_SRCH] & ID_CSR_number == `CSR_TLBIDX;
    assign ID_MEM_TLB = ID_CSR_use & MEM_TLB_operation[`TLB_OP_SRCH] & ID_CSR_number == `CSR_TLBIDX;
    assign ID_WB_TLB = ID_CSR_use & WB_TLB_operation[`TLB_OP_SRCH] & ID_CSR_number == `CSR_TLBIDX;

    assign ID_EXE_int = EXE_CSR_write &
                       (EXE_CSR_write_number == `CSR_CRMD | EXE_CSR_write_number == `CSR_ECFG |
                        EXE_CSR_write_number == `CSR_ECFG | EXE_CSR_write_number == `CSR_ESTAT |
                        EXE_CSR_write_number == `CSR_TCFG | EXE_CSR_write_number == `CSR_TICLR);
    assign ID_MEM_int = MEM_CSR_write &
                       (MEM_CSR_write_number == `CSR_CRMD| MEM_CSR_write_number == `CSR_ECFG |
                        MEM_CSR_write_number == `CSR_ECFG | MEM_CSR_write_number == `CSR_ESTAT |
                        MEM_CSR_write_number == `CSR_TCFG  | MEM_CSR_write_number == `CSR_TICLR);
    assign ID_WB_int = WB_CSR_write & (WB_CSR_write_number == `CSR_CRMD | WB_CSR_write_number == `CSR_ECFG | WB_CSR_write_number == `CSR_ECFG | WB_CSR_write_number == `CSR_ESTAT | WB_CSR_write_number == `CSR_TCFG | WB_CSR_write_number == `CSR_TICLR);

    assign ID_GPR_stall = EXE_valid & (ID_EXE_GPR1_A & ID_EXE_GPR1_T | ID_EXE_GPR2_A & ID_EXE_GPR2_T) | MEM_valid & (ID_MEM_GPR1_A & ID_MEM_GPR1_T | ID_MEM_GPR2_A & ID_MEM_GPR2_T);

    assign ID_CSR_stall = EXE_valid & ID_EXE_CSR | MEM_valid & ID_MEM_CSR | WB_valid & ID_WB_CSR;

    assign ID_TLB_stall = EXE_valid & ID_EXE_TLB | MEM_valid & ID_MEM_TLB | WB_valid & ID_WB_TLB;

    assign ID_int_stall = EXE_valid & ID_EXE_int | MEM_valid & ID_MEM_int | WB_valid & ID_WB_int;

    // TODO: delay memory write
    assign ID_flush_stall = EXE_valid & (|EXE_exception | EXE_ereturn | EXE_refetch) | MEM_valid & (|MEM_exception | MEM_ereturn | MEM_refetch);

    assign ID_bj_stall = ID_valid & ID_jump & (EXE_valid & ID_EXE_GPR1_A &
                        |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM] |
                         MEM_valid & ID_MEM_GPR1_A & MEM_GPR_new[`GPR_NEW_WB]) |
                         ID_valid & |ID_branch[`BRANCH_LTU:`BRANCH_EQ] &
                        (EXE_valid & (ID_EXE_GPR1_A | ID_EXE_GPR2_A) &
                        |EXE_GPR_new[`GPR_NEW_WB:`GPR_NEW_MEM] |
                         MEM_valid & (ID_MEM_GPR1_A | ID_MEM_GPR2_A) & MEM_GPR_new[`GPR_NEW_WB]);

    assign ID_stall = ID_GPR_stall | ID_CSR_stall | ID_TLB_stall | ID_int_stall | ID_flush_stall;

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
        .ID_link             (ID_link),
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
        .ID_refetch          (ID_refetch),
        .ID_GPR_new          (ID_GPR_new),
        .ID_INT              (ID_INT),
        .ID_PIF              (ID_PIF),
        .ID_IF_PPI           (ID_IF_PPI),
        .ID_ADEF             (ID_ADEF),
        .ID_SYS              (ID_SYS),
        .ID_BRK              (ID_BRK),
        .ID_INE              (ID_INE),
        .ID_IF_TLBR          (ID_IF_TLBR),
        .EXE_PC              (EXE_PC),
`ifdef CHIPLAB
        .EXE_inst            (EXE_inst),
`endif
        .EXE_link            (EXE_link),
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
        .EXE_refetch         (EXE_refetch),
        .EXE_GPR_new         (EXE_GPR_new),
        .EXE_INT             (EXE_INT),
        .EXE_PIF             (EXE_PIF),
        .EXE_IF_PPI          (EXE_IF_PPI),
        .EXE_ADEF            (EXE_ADEF),
        .EXE_SYS             (EXE_SYS),
        .EXE_BRK             (EXE_BRK),
        .EXE_INE             (EXE_INE),
        .EXE_IF_TLBR         (EXE_IF_TLBR)
    );

    cache dcache (
        .clk        (clk),
        .reset      (reset),
        // Dcache <-> EXE/MEM
        .valid      (data_req),
        .op         (data_op),
        .vaddr      (data_vaddr),
        .access_size(data_access_size),
        .wstrb      (data_wstrb),
        .wdata      (data_wdata),
        .addr_ok    (data_addr_ok),
        .data_ok    (data_data_ok),
        .rdata      (data_rdata),
        // Dcache <-> MMU
        .search_op  (data_search_op),
        .paddr      (data_paddr),
        .access_type(|data_access_type),
        // to AXI Bridge
        .rd_req     (DCache_mem_rd_req),
        .rd_type    (DCache_mem_rd_type),
        .rd_addr    (DCache_mem_rd_addr),
        .rd_rdy     (DCache_mem_rd_rdy),
        .ret_valid  (DCache_mem_ret_valid),
        .ret_last   ({1'b0, DCache_mem_ret_last}),
        .ret_data   (DCache_mem_ret_data),
        .wr_req     (DCache_mem_wr_req),
        .wr_type    (DCache_mem_wr_type),
        .wr_addr    (DCache_mem_wr_addr),
        .wr_wstrb   (DCache_mem_wr_wstrb),
        .wr_data    (DCache_mem_wr_data),
        .wr_rdy     (DCache_mem_wr_rdy)
    );

    EXE_stage exe_stage (
        .clk             (clk),
        .reset           (reset),
        .valid           (EXE_valid),
        .MEM_ready       (MEM_ready),
        .done            (EXE_done),
        .exception       (EXE_exception),
        .inst_req        (inst_cacop_req),
        .inst_op         (inst_cacop_op),
        .inst_vaddr      (inst_cacop_vaddr),
        .inst_addr_ok    (inst_addr_ok),
        .data_req        (data_req),
        .data_op         (data_op),
        .data_access_size(data_access_size),
        .data_vaddr      (data_vaddr),
        .data_wstrb      (data_wstrb),
        .data_wdata      (data_wdata),
        .data_addr_ok    (data_addr_ok),
        .PC              (EXE_PC),
        .imm             (EXE_imm),
        .rj_data         (EXE_rj_data),
        .rkd_data        (EXE_rkd_data),
        .ALU_src1_is_PC  (EXE_ALU_src1_is_PC),
        .ALU_src2_is_imm (EXE_ALU_src2_is_imm),
        .ALU_operation   (EXE_ALU_operation),
        .div_unsigned    (EXE_mul_div_unsigned),
        .MEM_read        (EXE_MEM_read),
        .MEM_write       (EXE_MEM_write),
        .CSR_read_data   (EXE_CSR_result),
        .CSR_write_mask  (EXE_CSR_write_mask),
        .cache_target    (EXE_cache_target),
        .ALU_result      (EXE_ALU_result),
        .CSR_write_data  (EXE_CSR_write_data),
        .ALE             (EXE_ALE)
    );

    multiplier mul (
        .clk         (clk),
        .mul_unsigned(EXE_mul_div_unsigned),
        .factor1     (EXE_rj_data),
        .factor2     (EXE_rkd_data),
        .product     (MEM_mul_result)
    );

    assign EXE_exception    = {EXE_TLBR, EXE_IF_TLBR, 1'b0, EXE_INE, EXE_BRK, EXE_SYS, EXE_ALE, 1'b0, EXE_ADEF, EXE_PPI, EXE_IF_PPI, EXE_PME, EXE_PIF, EXE_PIS, EXE_PIL, EXE_INT};

    assign EXE_forward_data = {32{EXE_GPR_write_src[`GPR_WRITE_SRC_LINK]}} & EXE_link | {32{EXE_GPR_write_src[`GPR_WRITE_SRC_LUI]}} & EXE_imm | {32{EXE_GPR_write_src[`GPR_WRITE_SRC_CSR]}} & EXE_CSR_result;

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
`ifdef CHIPLAB
        .EXE_MEM_paddr       (EXE_MEM_paddr),
`endif
        .EXE_GPR_write       (EXE_GPR_write),
        .EXE_GPR_write_num   (EXE_GPR_write_num),
        .EXE_GPR_write_src   (EXE_GPR_write_src),
        .EXE_CSR_write       (EXE_CSR_write),
        .EXE_CSR_write_number(EXE_CSR_write_number),
        .EXE_CSR_write_data  (EXE_CSR_write_data),
        .EXE_TLB_operation   (EXE_TLB_operation),
        .EXE_cache_target    (EXE_cache_target),
        .EXE_ereturn         (EXE_ereturn),
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
`ifdef CHIPLAB
        .MEM_MEM_paddr       (MEM_MEM_paddr),
`endif
        .MEM_GPR_write       (MEM_GPR_write),
        .MEM_GPR_write_num   (MEM_GPR_write_num),
        .MEM_GPR_write_src   (MEM_GPR_write_src),
        .MEM_CSR_write       (MEM_CSR_write),
        .MEM_CSR_write_number(MEM_CSR_write_number),
        .MEM_CSR_write_data  (MEM_CSR_write_data),
        .MEM_TLB_operation   (MEM_TLB_operation),
        .MEM_cache_target    (MEM_cache_target),
        .MEM_refetch         (MEM_refetch),
        .MEM_ereturn         (MEM_ereturn),
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
        .MEM_IF_TLBR         (MEM_IF_TLBR),
        .MEM_EXE_TLBR        (MEM_EXE_TLBR)
    );

    MEM_stage mem_stage (
        .done          (MEM_done),
        .exception     (MEM_exception),
        .inst_data_ok  (inst_data_ok),
        .data_data_ok  (data_data_ok),
        .data_rdata    (data_rdata),
        .ALU_operation (MEM_ALU_operation),
        .mul_result    (MEM_mul_result),
        .EXE_ALU_result(MEM_EXE_ALU_result),
        .MEM_read      (MEM_MEM_read),
        .MEM_write     (MEM_MEM_write),
        .cache_target  (MEM_cache_target),
        .ALU_result    (MEM_ALU_result),
        .MEM_result    (MEM_MEM_result)
    );

    assign MEM_exception    = {MEM_EXE_TLBR, MEM_IF_TLBR, 1'b0, MEM_INE, MEM_BRK, MEM_SYS, MEM_ALE, 1'b0, MEM_ADEF, MEM_EXE_PPI, MEM_IF_PPI, MEM_PME, MEM_PIF, MEM_PIS, MEM_PIL, MEM_INT};

    assign MEM_forward_data = {32{MEM_GPR_write_src[`GPR_WRITE_SRC_CSR]}} & MEM_CSR_result | {32{MEM_GPR_write_src[`GPR_WRITE_SRC_ALU]}} & MEM_ALU_result;

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
`ifdef CHIPLAB
        .MEM_MEM_read        (MEM_MEM_read),
        .MEM_MEM_write       (MEM_MEM_write),
        .MEM_MEM_paddr       (MEM_MEM_paddr),
`endif
        .MEM_MEM_result      (MEM_MEM_result),
        .MEM_GPR_write       (MEM_GPR_write),
        .MEM_GPR_write_num   (MEM_GPR_write_num),
        .MEM_GPR_write_src   (MEM_GPR_write_src),
        .MEM_CSR_write       (MEM_CSR_write),
        .MEM_CSR_write_number(MEM_CSR_write_number),
        .MEM_CSR_write_data  (MEM_CSR_write_data),
        .MEM_TLB_operation   (MEM_TLB_operation),
        .MEM_ereturn         (MEM_ereturn),
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
`ifdef CHIPLAB
        .WB_MEM_read         (WB_MEM_read),
        .WB_MEM_write        (WB_MEM_write),
        .WB_MEM_paddr        (WB_MEM_paddr),
`endif
        .WB_MEM_result       (WB_MEM_result),
        .WB_GPR_write        (WB_GPR_write),
        .WB_GPR_write_num    (WB_GPR_write_num),
        .WB_GPR_write_src    (WB_GPR_write_src),
        .WB_CSR_write        (WB_CSR_write),
        .WB_CSR_write_number (WB_CSR_write_number),
        .WB_CSR_write_data   (WB_CSR_write_data),
        .WB_TLB_operation    (WB_TLB_operation),
        .WB_ereturn          (WB_ereturn),
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
        .WB_IF_TLBR          (WB_IF_TLBR),
        .WB_EXE_TLBR         (WB_EXE_TLBR)
    );

    WB_stage wb_stage (
        .valid            (WB_valid),
        .done             (WB_done),
        .exception        (WB_exception),
        .ALU_result       (WB_ALU_result),
        .MEM_result       (WB_MEM_result),
        .CSR_result       (WB_CSR_result),
        .GPR_write        (WB_GPR_write),
        .GPR_write_src    (WB_GPR_write_src),
        .CSR_write        (WB_CSR_write),
        .TLB_operation    (WB_TLB_operation),
        .GPR_write_enable (WB_GPR_write_enable),
        .GPR_write_data   (WB_GPR_write_data),
        .CSR_write_enable (WB_CSR_write_enable),
        .CSR_TLB_operation(WB_CSR_TLB_operation),
        .TLB_TLB_operation(WB_TLB_TLB_operation)
    );

    assign WB_exception = {WB_EXE_TLBR, WB_IF_TLBR, 1'b0, WB_INE, WB_BRK, WB_SYS, WB_ALE, 1'b0, WB_ADEF, WB_EXE_PPI, WB_IF_PPI, WB_PME, WB_PIF, WB_PIS, WB_PIL, WB_INT};

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
        .plv          (PLV),
        .da           (DA),
        .pg           (PG),
        .datf         (DATF),
        .datm         (DATM),
        .asid         (ASID),
        .plv0         (PLV0),
        .pseg0        (PSEG0),
        .vseg0        (VSEG0),
        .mat0         (MAT0),
        .plv1         (PLV1),
        .pseg1        (PSEG1),
        .vseg1        (VSEG1),
        .mat1         (MAT1),
        .TLB_operation(WB_CSR_TLB_operation),
        .TLB_s_hit    (TLB_s_hit),
        .TLB_s_index  (TLB_s_index),
        .TLB_r_hi     (TLB_r_hi),
        .TLB_r_lo0    (TLB_r_lo0),
        .TLB_r_lo1    (TLB_r_lo1),
        .TLB_rw_index (TLB_rw_index),
        .TLB_sw_hi    (TLB_sw_hi),
        .TLB_w_lo0    (TLB_w_lo0),
        .TLB_w_lo1    (TLB_w_lo1),
        .TLB_f_index  (TLB_f_index),
        .hw_int       (intrpt),
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
        .clk             (clk),
        .TLB_operation   (WB_TLB_TLB_operation),
        .invtlb_vaddr    (WB_rkd_data),
        .invtlb_asid     (WB_rj_data),
        .TLB_rw_index    (TLB_rw_index),
        .TLB_sw_hi       (TLB_sw_hi),
        .TLB_w_lo0       (TLB_w_lo0),
        .TLB_w_lo1       (TLB_w_lo1),
        .TLB_s_hit       (TLB_s_hit),
        .TLB_s_index     (TLB_s_index),
        .TLB_r_hi        (TLB_r_hi),
        .TLB_r_lo0       (TLB_r_lo0),
        .TLB_r_lo1       (TLB_r_lo1),
        .TLB_f_index     (TLB_f_index),
        .CSR_plv         (PLV),
        .CSR_da          (DA),
        .CSR_pg          (PG),
        .CSR_datf        (DATF),
        .CSR_datm        (DATM),
        .CSR_asid        (ASID),
        .DMW0_plv        (PLV0),
        .DMW0_pseg       (PSEG0),
        .DMW0_vseg       (VSEG0),
        .DMW0_mat        (MAT0),
        .DMW1_plv        (PLV1),
        .DMW1_pseg       (PSEG1),
        .DMW1_vseg       (VSEG1),
        .DMW1_mat        (MAT1),
        .inst_op         (inst_search_op),
        .inst_vaddr      (inst_search_op[0] ? inst_cacop_vaddr : inst_vaddr),
        .inst_paddr      (inst_paddr),
        .inst_access_type(inst_access_type),
        .data_op         (data_search_op),
        .data_vaddr      (data_vaddr),
        .data_paddr      (data_paddr),
        .data_access_type(data_access_type),
        .PIL             (EXE_PIL),
        .PIS             (EXE_PIS),
        .PIF             (pre_IF_PIF),
        .PME             (EXE_PME),
        .inst_PPI        (pre_IF_PPI),
        .data_PPI        (EXE_PPI),
        .inst_TLBR       (pre_IF_TLBR),
        .data_TLBR       (EXE_TLBR)
    );

    assign PC                = WB_PC;
    assign exception         = {`EXCEPTION_WIDTH{WB_valid}} & WB_exception;
    assign ereturn           = WB_valid & WB_ereturn;
    assign refetch           = WB_valid & WB_refetch;
    assign rsource           = WB_PC;
    assign flush             = WB_valid & (|WB_exception | WB_ereturn | WB_refetch);

    assign debug_wb_pc       = WB_PC;
    assign debug_wb_rf_we    = {4{WB_GPR_write_enable}};
    assign debug_wb_rf_wnum  = WB_GPR_write_num;
    assign debug_wb_rf_wdata = WB_GPR_write_data;
endmodule
