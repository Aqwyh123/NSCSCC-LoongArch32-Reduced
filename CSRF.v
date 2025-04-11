`include "macros.h"

module CSRF #(
    parameter TLB_ENTRIES = 16
) (
    input  wire                             clk,
    input  wire                             reset,
    // data signals
    input  wire [    `CSR_NUMBER_WIDTH-1:0] read_number,
    output wire [                     31:0] read_data,
    input  wire [    `CSR_NUMBER_WIDTH-1:0] write_number,
    input  wire                             write_enable,
    input  wire [                     31:0] write_data,
    // counter signals
    output wire [                     63:0] counter,
    // TLB signals
    input  wire [`TLB_OP_READ:`TLB_OP_SRCH] TLB_operation,
    input  wire                             TLB_s_hit,
    input  wire [  $clog2(TLB_ENTRIES)-1:0] TLB_s_index,
    input  wire [        `TLBEHI_WIDTH-1:0] TLB_r_hi,
    input  wire [        `TLBELO_WIDTH-1:0] TLB_r_lo0,
    input  wire [        `TLBELO_WIDTH-1:0] TLB_r_lo1,
    output wire [  $clog2(TLB_ENTRIES)-1:0] TLB_rw_index,
    output wire [        `TLBEHI_WIDTH-1:0] TLB_sw_hi,
    output wire [        `TLBELO_WIDTH-1:0] TLB_w_lo0,
    output wire [        `TLBELO_WIDTH-1:0] TLB_w_lo1,
    output wire [  $clog2(TLB_ENTRIES)-1:0] TLB_f_index,
    // inst / data access signals
    output wire                             da,
    output wire                             pg,
    output wire [                      9:0] asid,
    output wire [                      1:0] plv,
    // inst access signals
    output wire [                      1:0] plv0,
    output wire [  `CSR_DMW_PSEG_WIDTH-1:0] pseg0,
    output wire [  `CSR_DMW_VSEG_WIDTH-1:0] vseg0,
    // data access signals
    output wire [                      1:0] plv1,
    output wire [  `CSR_DMW_PSEG_WIDTH-1:0] pseg1,
    output wire [  `CSR_DMW_VSEG_WIDTH-1:0] vseg1,
    // interupt signals
    input  wire [                      7:0] hw_int,
    input  wire                             ip_int,
    output wire                             interupt,
    // exception signals
    input  wire [     `EXCEPTION_WIDTH-1:0] exception,
    input  wire                             ereturn,
    input  wire [                     31:0] PC,
    input  wire [                     31:0] vaddr,
    output wire [                     31:0] eentry,
    output wire [                     31:0] eraddr,
    output wire [                     31:0] rentry
);
    reg  [               31:0] CRMD;
    reg  [               31:0] PRMD;
    reg  [               31:0] ECFG;
    reg  [               31:0] ESTAT;
    reg  [               31:0] ERA;
    reg  [               31:0] BADV;
    reg  [               31:0] EENTRY;
    reg  [               31:0] TLBIDX;
    reg  [               31:0] TLBEHI;
    reg  [               31:0] TLBELO0;
    reg  [               31:0] TLBELO1;
    reg  [               31:0] ASID;
    reg  [               31:0] SAVE      [3:0];
    reg  [               31:0] TID;
    reg  [               31:0] TCFG;
    reg  [               31:0] TVAL;
    wire [               31:0] TICLR;
    reg  [               31:0] TLBRENTRY;
    reg  [               31:0] DMW       [1:0];

    wire [   `ECODE_WIDTH-1:0] ecode;
    wire [`ESUBCODE_WIDTH-1:0] esubcode;

    assign ecode    = exception[`EXCEPTION_INT] ? `ECODE_INT :
                      exception[`EXCEPTION_ADEF] ? `ECODE_ADEF :
                      exception[`EXCEPTION_PIF] ? `ECODE_PIF :
                      exception[`EXCEPTION_F_PPI] ? `ECODE_PPI :
                      exception[`EXCEPTION_F_TLBR] ? `ECODE_TLBR :
                      exception[`EXCEPTION_SYS] ? `ECODE_SYS  :
                      exception[`EXCEPTION_BRK] ? `ECODE_BRK  :
                      exception[`EXCEPTION_INE] ? `ECODE_INE  :
                      exception[`EXCEPTION_ALE] ? `ECODE_ALE  :
                      exception[`EXCEPTION_PIL] ? `ECODE_PIL :
                      exception[`EXCEPTION_PIS] ? `ECODE_PIS :
                      exception[`EXCEPTION_PME] ? `ECODE_PME :
                      exception[`EXCEPTION_M_PPI] ? `ECODE_PPI :
                      exception[`EXCEPTION_M_TLBR] ? `ECODE_TLBR : `ECODE_WIDTH'b0;
    assign esubcode = {8'b0, exception[`EXCEPTION_ADEM]};

    StableCounter stable_counter (
        .clk  (clk),
        .reset(reset),
        .data (counter)
    );

    always @(posedge clk) begin
        if (reset) begin
            CRMD[`CSR_CRMD_PLV]  <= 2'b0;
            CRMD[`CSR_CRMD_IE]   <= 1'b0;
            CRMD[`CSR_CRMD_DA]   <= 1'b1;
            CRMD[`CSR_CRMD_PG]   <= 1'b0;
            CRMD[`CSR_CRMD_DATF] <= 2'b0;
            CRMD[`CSR_CRMD_DATM] <= 2'b0;
        end else if (|exception) begin
            CRMD[`CSR_CRMD_PLV] <= 2'b0;
            CRMD[`CSR_CRMD_IE]  <= 1'b0;
            if (|exception[`EXCEPTION_TLBR]) begin
                CRMD[`CSR_CRMD_DA] <= 1'b1;
                CRMD[`CSR_CRMD_PG] <= 1'b0;
            end
        end else if (ereturn) begin
            CRMD[`CSR_CRMD_PLV] <= PRMD[`CSR_PRMD_PPLV];
            CRMD[`CSR_CRMD_IE]  <= PRMD[`CSR_PRMD_PIE];
            if (ESTAT[`CSR_ESTAT_ECODE] == `ECODE_TLBR) begin
                CRMD[`CSR_CRMD_DA] <= 1'b0;
                CRMD[`CSR_CRMD_PG] <= 1'b1;
            end
        end else if (write_enable & write_number == `CSR_CRMD) begin
            CRMD[`CSR_CRMD_PLV]  <= write_data[`CSR_CRMD_PLV];
            CRMD[`CSR_CRMD_IE]   <= write_data[`CSR_CRMD_IE];
            CRMD[`CSR_CRMD_DA]   <= write_data[`CSR_CRMD_DA];
            CRMD[`CSR_CRMD_PG]   <= write_data[`CSR_CRMD_PG];
            CRMD[`CSR_CRMD_DATF] <= write_data[`CSR_CRMD_DATF];
            CRMD[`CSR_CRMD_DATM] <= write_data[`CSR_CRMD_DATM];
        end
        CRMD[`CSR_CRMD_0] <= `CSR_CRMD_0_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (|exception) begin
            PRMD[`CSR_PRMD_PPLV] <= CRMD[`CSR_CRMD_PLV];
            PRMD[`CSR_PRMD_PIE]  <= CRMD[`CSR_CRMD_IE];
        end else if (write_enable & write_number == `CSR_PRMD) begin
            PRMD[`CSR_PRMD_PPLV] <= write_data[`CSR_PRMD_PPLV];
            PRMD[`CSR_PRMD_PIE]  <= write_data[`CSR_PRMD_PIE];
        end
        PRMD[`CSR_PRMD_0] <= `CSR_PRMD_0_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (reset) begin
            ECFG[`CSR_ECFG_LIE_9_0]   <= 10'b0;
            ECFG[`CSR_ECFG_LIE_12_11] <= 2'b0;
        end else if (write_enable & write_number == `CSR_ECFG) begin
            ECFG[`CSR_ECFG_LIE_9_0]   <= write_data[`CSR_ECFG_LIE_9_0];
            ECFG[`CSR_ECFG_LIE_12_11] <= write_data[`CSR_ECFG_LIE_12_11];
        end
        ECFG[`CSR_ECFG_0_LO] <= `CSR_ECFG_0_LO_WIDTH'b0;
        ECFG[`CSR_ECFG_0_HI] <= `CSR_ECFG_0_HI_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (reset) begin
            ESTAT[`CSR_ESTAT_IS_1_0] <= 2'b0;
        end else if (write_enable & write_number == `CSR_ESTAT) begin
            ESTAT[`CSR_ESTAT_IS_1_0] <= write_data[`CSR_ESTAT_IS_1_0];
        end
        ESTAT[`CSR_ESTAT_IS_9_2] <= hw_int;
        if (TCFG[`CSR_TCFG_EN] & ~|TVAL[`CSR_TVAL_TVAL]) begin
            ESTAT[`CSR_ESTAT_IS_11] <= 1'b1;
        end else if (write_enable & write_number == `CSR_TICLR & write_data[`CSR_TICLR_CLR]) begin
            ESTAT[`CSR_ESTAT_IS_11] <= 1'b0;
        end
        ESTAT[`CSR_ESTAT_IS_12] <= ip_int;
        if (|exception) begin
            ESTAT[`CSR_ESTAT_ECODE]    <= ecode;
            ESTAT[`CSR_ESTAT_ESUBCODE] <= esubcode;
        end
        ESTAT[`CSR_ESTAT_0_LO] <= `CSR_ESTAT_0_LO_WIDTH'b0;
        ESTAT[`CSR_ESTAT_0_MD] <= `CSR_ESTAT_0_MD_WIDTH'b0;
        ESTAT[`CSR_ESTAT_0_HI] <= `CSR_ESTAT_0_HI_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (|exception) begin
            ERA[`CSR_ERA_PC] <= PC;
        end else if (write_enable & write_number == `CSR_ERA) begin
            ERA[`CSR_ERA_PC] <= write_data[`CSR_ERA_PC];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            TLBIDX[`CSR_TLBIDX_NE] <= 1'b0;
        end else if (write_enable & write_number == `CSR_TLBIDX) begin
            TLBIDX[`CSR_TLBIDX_INDEX] <= write_data[`CSR_TLBIDX_INDEX];
            TLBIDX[`CSR_TLBIDX_PS]    <= write_data[`CSR_TLBIDX_PS];
            TLBIDX[`CSR_TLBIDX_NE]    <= write_data[`CSR_TLBIDX_NE];
        end else if (TLB_operation[`TLB_OP_SRCH]) begin
            if (TLB_s_hit) begin
                TLBIDX[`CSR_TLBIDX_INDEX] <= TLB_s_index;
                TLBIDX[`CSR_TLBIDX_NE]    <= 1'b0;
            end else begin
                TLBIDX[`CSR_TLBIDX_NE] <= 1'b1;
            end
        end else if (TLB_operation[`TLB_OP_READ]) begin
            if (TLB_r_hi[`TLBEHI_E]) begin
                TLBIDX[`CSR_TLBIDX_PS] <= TLB_r_hi[`TLBEHI_PS];
                TLBIDX[`CSR_TLBIDX_NE] <= 1'b0;
            end else begin
                TLBIDX[`CSR_TLBIDX_PS] <= `CSR_TLBIDX_PS_WIDTH'b0;
                TLBIDX[`CSR_TLBIDX_NE] <= 1'b1;
            end
        end
        TLBIDX[`CSR_TLBIDX_0_LO] <= 0;  // (23-$clog2(`TLB_ENTRIES)+1)'b0;
        TLBIDX[`CSR_TLBIDX_0_HI] <= `CSR_TLBIDX_0_HI_WIDTH'b0;
    end

    always @(posedge clk) begin
        TLBEHI[`CSR_TLBEHI_0] <= `CSR_TLBEHI_0_WIDTH'b0;
        if (write_enable & write_number == `CSR_TLBEHI) begin
            TLBEHI[`CSR_TLBEHI_VPPN] <= write_data[`CSR_TLBEHI_VPPN];
        end else if (|exception[`EXCEPTION_M_PPI:`EXCEPTION_PIL] |
                     |exception[`EXCEPTION_TLBR]) begin
            TLBEHI[`CSR_TLBEHI_VPPN] <= (exception[`EXCEPTION_PIF] |
                                         exception[`EXCEPTION_F_PPI] |
                                         exception[`EXCEPTION_F_TLBR]) ? PC[`CSR_TLBEHI_VPPN] :
                                         vaddr[`CSR_TLBEHI_VPPN];
        end else if (TLB_operation[`TLB_OP_READ]) begin
            if (TLB_r_hi[`TLBEHI_E]) begin
                TLBEHI[`CSR_TLBEHI_VPPN] <= TLB_r_hi[`TLBEHI_VPPN];
            end else begin
                TLBEHI[`CSR_TLBEHI_VPPN] <= `CSR_TLBEHI_VPPN_WIDTH'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (write_enable && write_number == `CSR_TLBELO0) begin
            TLBELO0[`CSR_TLBELO0_V]   <= write_data[`CSR_TLBELO0_V];
            TLBELO0[`CSR_TLBELO0_D]   <= write_data[`CSR_TLBELO0_D];
            TLBELO0[`CSR_TLBELO0_PLV] <= write_data[`CSR_TLBELO0_PLV];
            TLBELO0[`CSR_TLBELO0_MAT] <= write_data[`CSR_TLBELO0_MAT];
            TLBELO0[`CSR_TLBELO0_G]   <= write_data[`CSR_TLBELO0_G];
            TLBELO0[`CSR_TLBELO0_PPN] <= write_data[`CSR_TLBELO0_PPN];
        end else if (TLB_operation[`TLB_OP_READ]) begin
            if (TLB_r_hi[`TLBEHI_E]) begin
                TLBELO0[`CSR_TLBELO0_V]   <= TLB_r_lo0[`TLBELO_V];
                TLBELO0[`CSR_TLBELO0_D]   <= TLB_r_lo0[`TLBELO_D];
                TLBELO0[`CSR_TLBELO0_PLV] <= TLB_r_lo0[`TLBELO_PLV];
                TLBELO0[`CSR_TLBELO0_MAT] <= TLB_r_lo0[`TLBELO_MAT];
                TLBELO0[`CSR_TLBELO0_G]   <= TLB_r_hi[`TLBEHI_G];
                TLBELO0[`CSR_TLBELO0_PPN] <= TLB_r_lo0[`TLBELO_PPN];
            end else begin
                TLBELO0[`CSR_TLBELO0_V]   <= 1'b0;
                TLBELO0[`CSR_TLBELO0_D]   <= 1'b0;
                TLBELO0[`CSR_TLBELO0_PLV] <= 2'b0;
                TLBELO0[`CSR_TLBELO0_MAT] <= 2'b0;
                TLBELO0[`CSR_TLBELO0_G]   <= 1'b0;
                TLBELO0[`CSR_TLBELO0_PPN] <= 0;  // (`PALEN-5-8+1)'b0;
            end
        end
        TLBELO0[`CSR_TLBELO0_0_LO] <= `CSR_TLBELO0_0_LO_WIDTH'b0;
        TLBELO0[`CSR_TLBELO0_0_HI] <= 0;  // (31-`TLBELO_WIDTH+1)'b0;
    end

    always @(posedge clk) begin
        if (write_enable && write_number == `CSR_TLBELO1) begin
            TLBELO1[`CSR_TLBELO1_V]   <= write_data[`CSR_TLBELO1_V];
            TLBELO1[`CSR_TLBELO1_D]   <= write_data[`CSR_TLBELO1_D];
            TLBELO1[`CSR_TLBELO1_PLV] <= write_data[`CSR_TLBELO1_PLV];
            TLBELO1[`CSR_TLBELO1_MAT] <= write_data[`CSR_TLBELO1_MAT];
            TLBELO1[`CSR_TLBELO1_G]   <= write_data[`CSR_TLBELO1_G];
            TLBELO1[`CSR_TLBELO1_PPN] <= write_data[`CSR_TLBELO1_PPN];
        end else if (TLB_operation[`TLB_OP_READ]) begin
            if (TLB_r_hi[`TLBEHI_E]) begin
                TLBELO1[`CSR_TLBELO1_V]   <= TLB_r_lo1[`TLBELO_V];
                TLBELO1[`CSR_TLBELO1_D]   <= TLB_r_lo1[`TLBELO_D];
                TLBELO1[`CSR_TLBELO1_PLV] <= TLB_r_lo1[`TLBELO_PLV];
                TLBELO1[`CSR_TLBELO1_MAT] <= TLB_r_lo1[`TLBELO_MAT];
                TLBELO1[`CSR_TLBELO1_G]   <= TLB_r_hi[`TLBEHI_G];
                TLBELO1[`CSR_TLBELO1_PPN] <= TLB_r_lo1[`TLBELO_PPN];
            end else begin
                TLBELO1[`CSR_TLBELO1_V]   <= 1'b0;
                TLBELO1[`CSR_TLBELO1_D]   <= 1'b0;
                TLBELO1[`CSR_TLBELO1_PLV] <= 2'b0;
                TLBELO1[`CSR_TLBELO1_MAT] <= 2'b0;
                TLBELO1[`CSR_TLBELO1_G]   <= 1'b0;
                TLBELO1[`CSR_TLBELO1_PPN] <= 0;  // (`PALEN-5-8+1)'b0;
            end
        end
        TLBELO1[`CSR_TLBELO1_0_LO] <= `CSR_TLBELO1_0_LO_WIDTH'b0;
        TLBELO1[`CSR_TLBELO1_0_HI] <= 0;  // (31-`TLBELO_WIDTH+1)'b0;
    end

    always @(posedge clk) begin
        if (write_enable && write_number == `CSR_ASID) begin
            ASID[`CSR_ASID_ASID] <= write_data[`CSR_ASID_ASID];
        end else if (TLB_operation[`TLB_OP_READ]) begin
            if (TLB_r_hi[`TLBEHI_E]) begin
                ASID[`CSR_ASID_ASID] <= TLB_r_hi[`TLBEHI_ASID];
            end else begin
                ASID[`CSR_ASID_ASID] <= `CSR_ASID_ASID_WIDTH'b0;
            end
        end
        ASID[`CSR_ASID_0_LO]     <= `CSR_ASID_0_LO_WIDTH'b0;
        ASID[`CSR_ASID_ASIDBITS] <= `CSR_ASID_ASIDBITS_WIDTH'd`CSR_ASID_ASID_WIDTH;
        ASID[`CSR_ASID_0_HI]     <= `CSR_ASID_0_HI_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (|exception[`EXCEPTION_ADEF:`EXCEPTION_PIL] |
             exception[`EXCEPTION_ALE] | |exception[`EXCEPTION_TLBR] ) begin
            BADV[`CSR_BADV_VADDR] <= (exception[`EXCEPTION_PIF] |
                                      exception[`EXCEPTION_F_PPI] |
                                      exception[`EXCEPTION_ADEF] |
                                      exception[`EXCEPTION_F_TLBR]) ? PC :
                                      vaddr;
        end else if (write_enable & write_number == `CSR_BADV) begin
            BADV[`CSR_BADV_VADDR] <= write_data[`CSR_BADV_VADDR];
        end
    end

    always @(posedge clk) begin
        if (write_enable & write_number == `CSR_EENTRY) begin
            EENTRY[`CSR_EENTRY_VA] <= write_data[`CSR_EENTRY_VA];
        end
        EENTRY[`CSR_EENTRY_0] <= `CSR_EENTRY_0_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (write_enable & write_number == `CSR_SAVE0) begin
            SAVE[0][`CSR_SAVE_DATA] <= write_data[`CSR_SAVE_DATA];
        end
        if (write_enable & write_number == `CSR_SAVE1) begin
            SAVE[1][`CSR_SAVE_DATA] <= write_data[`CSR_SAVE_DATA];
        end
        if (write_enable & write_number == `CSR_SAVE2) begin
            SAVE[2][`CSR_SAVE_DATA] <= write_data[`CSR_SAVE_DATA];
        end
        if (write_enable & write_number == `CSR_SAVE3) begin
            SAVE[3][`CSR_SAVE_DATA] <= write_data[`CSR_SAVE_DATA];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            TID[`CSR_TID_TID] <= {{(32 - `COREID_WIDTH) {1'b0}}, `COREID};
        end else if (write_enable & write_number == `CSR_TID) begin
            TID[`CSR_TID_TID] <= write_data[`CSR_TID_TID];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            TCFG[`CSR_TCFG_EN] <= 1'b0;
        end else if (write_enable & write_number == `CSR_TCFG) begin
            TCFG[`CSR_TCFG_EN] <= write_data[`CSR_TCFG_EN];
        end
        if (write_enable & write_number == `CSR_TCFG) begin
            TCFG[`CSR_TCFG_PERIODIC] <= write_data[`CSR_TCFG_PERIODIC];
            TCFG[`CSR_TCFG_INITVAL]  <= write_data[`CSR_TCFG_INITVAL];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            TVAL[`CSR_TVAL_TVAL] <= `CSR_TVAL_TVAL_INIT;
        end else if (write_enable & write_number == `CSR_TCFG && write_data[`CSR_TCFG_EN]) begin
            TVAL[`CSR_TVAL_TVAL] <= {write_data[`CSR_TCFG_INITVAL], 2'b0};
        end else if (TCFG[`CSR_TCFG_EN] & ~&TVAL[`CSR_TVAL_TVAL]) begin
            if (~|TVAL[`CSR_TVAL_TVAL] & TCFG[`CSR_TCFG_PERIODIC]) begin
                TVAL[`CSR_TVAL_TVAL] <= {TCFG[`CSR_TCFG_INITVAL], 2'b0};
            end else begin
                TVAL[`CSR_TVAL_TVAL] <= TVAL[`CSR_TVAL_TVAL] - 1'b1;
            end
        end
    end

    assign TICLR = 32'b0;

    always @(posedge clk) begin
        TLBRENTRY[`CSR_TLBRENTRY_0] <= `CSR_TLBRENTRY_0_WIDTH'b0;
        if (write_enable & write_number == `CSR_TLBRENTRY) begin
            TLBRENTRY[`CSR_TLBRENTRY_PA] <= write_data[`CSR_TLBRENTRY_PA];
        end
    end

    always @(posedge clk) begin
        DMW[0][`CSR_DMW_0_LO] <= `CSR_DMW_0_LO_WIDTH'b0;
        DMW[0][`CSR_DMW_0_MD] <= `CSR_DMW_0_MD_WIDTH'b0;
        DMW[0][`CSR_DMW_0_HI] <= `CSR_DMW_0_HI_WIDTH'b0;
        if (write_enable && write_number == `CSR_DMW0) begin
            DMW[0][`CSR_DMW_PLV0] <= write_data[`CSR_DMW_PLV0];
            DMW[0][`CSR_DMW_PLV3] <= write_data[`CSR_DMW_PLV3];
            DMW[0][`CSR_DMW_MAT]  <= write_data[`CSR_DMW_MAT];
            DMW[0][`CSR_DMW_PSEG] <= write_data[`CSR_DMW_PSEG];
            DMW[0][`CSR_DMW_VSEG] <= write_data[`CSR_DMW_VSEG];
        end
        DMW[1][`CSR_DMW_0_LO] <= `CSR_DMW_0_LO_WIDTH'b0;
        DMW[1][`CSR_DMW_0_MD] <= `CSR_DMW_0_MD_WIDTH'b0;
        DMW[1][`CSR_DMW_0_HI] <= `CSR_DMW_0_HI_WIDTH'b0;
        if (write_enable && write_number == `CSR_DMW1) begin
            DMW[1][`CSR_DMW_PLV0] <= write_data[`CSR_DMW_PLV0];
            DMW[1][`CSR_DMW_PLV3] <= write_data[`CSR_DMW_PLV3];
            DMW[1][`CSR_DMW_MAT]  <= write_data[`CSR_DMW_MAT];
            DMW[1][`CSR_DMW_PSEG] <= write_data[`CSR_DMW_PSEG];
            DMW[1][`CSR_DMW_VSEG] <= write_data[`CSR_DMW_VSEG];
        end
    end

    assign read_data = {32{read_number == `CSR_CRMD}} & CRMD |
                       {32{read_number == `CSR_PRMD}} & PRMD |
                       {32{read_number == `CSR_ECFG}} & ECFG |
                       {32{read_number == `CSR_ESTAT}} & ESTAT |
                       {32{read_number == `CSR_ERA}} & ERA |
                       {32{read_number == `CSR_BADV}} & BADV |
                       {32{read_number == `CSR_EENTRY}} & EENTRY |
                       {32{read_number == `CSR_TLBIDX}} & TLBIDX |
                       {32{read_number == `CSR_TLBEHI}} & TLBEHI |
                       {32{read_number == `CSR_TLBELO0}} & TLBELO0 |
                       {32{read_number == `CSR_TLBELO1}} & TLBELO1 |
                       {32{read_number == `CSR_ASID}} & ASID |
                       {32{read_number == `CSR_SAVE0}} & SAVE[0] |
                       {32{read_number == `CSR_SAVE1}} & SAVE[1] |
                       {32{read_number == `CSR_SAVE2}} & SAVE[2] |
                       {32{read_number == `CSR_SAVE3}} & SAVE[3] |
                       {32{read_number == `CSR_TID}} & TID |
                       {32{read_number == `CSR_TCFG}} & TCFG |
                       {32{read_number == `CSR_TVAL}} & TVAL |
                       {32{read_number == `CSR_TICLR}} & TICLR |
                       {32{read_number == `CSR_TLBRENTRY}} & TLBRENTRY |
                       {32{read_number == `CSR_DMW0}} & DMW[0] |
                       {32{read_number == `CSR_DMW1}} & DMW[1];

    assign TLB_rw_index = TLBIDX[`CSR_TLBIDX_INDEX];
    assign TLB_sw_hi[`TLBEHI_E] = ESTAT[`CSR_ESTAT_ECODE] == `ECODE_TLBR | ~TLBIDX[`CSR_TLBIDX_NE];
    assign TLB_sw_hi[`TLBEHI_ASID] = ASID[`CSR_ASID_ASID];
    assign TLB_sw_hi[`TLBEHI_G] = TLBELO0[`CSR_TLBELO0_G] & TLBELO1[`CSR_TLBELO1_G];
    assign TLB_sw_hi[`TLBEHI_PS] = TLBIDX[`CSR_TLBIDX_PS];
    assign TLB_sw_hi[`TLBEHI_VPPN] = TLBEHI[`CSR_TLBEHI_VPPN];
    assign TLB_w_lo0[`TLBELO_V] = TLBELO0[`CSR_TLBELO0_V];
    assign TLB_w_lo0[`TLBELO_D] = TLBELO0[`CSR_TLBELO0_D];
    assign TLB_w_lo0[`TLBELO_MAT] = TLBELO0[`CSR_TLBELO0_MAT];
    assign TLB_w_lo0[`TLBELO_PLV] = TLBELO0[`CSR_TLBELO0_PLV];
    assign TLB_w_lo0[`TLBELO_PPN] = TLBELO0[`CSR_TLBELO0_PPN];
    assign TLB_w_lo1[`TLBELO_V] = TLBELO1[`CSR_TLBELO1_V];
    assign TLB_w_lo1[`TLBELO_D] = TLBELO1[`CSR_TLBELO1_D];
    assign TLB_w_lo1[`TLBELO_MAT] = TLBELO1[`CSR_TLBELO1_MAT];
    assign TLB_w_lo1[`TLBELO_PLV] = TLBELO1[`CSR_TLBELO1_PLV];
    assign TLB_w_lo1[`TLBELO_PPN] = TLBELO1[`CSR_TLBELO1_PPN];
    assign TLB_f_index = counter[$clog2(TLB_ENTRIES)-1:0];

    assign da = CRMD[`CSR_CRMD_DA];
    assign pg = CRMD[`CSR_CRMD_PG];
    assign asid = ASID[`CSR_ASID_ASID];
    assign plv = CRMD[`CSR_CRMD_PLV];

    encoder #(
        .WIDTH(`CSR_DMW_PLV_WIDTH)
    ) enc_plv0 (
        .in (DMW[0][`CSR_DMW_PLV]),
        .out(plv0)
    );
    assign pseg0 = DMW[0][`CSR_DMW_PSEG];
    assign vseg0 = DMW[0][`CSR_DMW_VSEG];

    encoder #(
        .WIDTH(`CSR_DMW_PLV_WIDTH)
    ) enc_plv1 (
        .in (DMW[1][`CSR_DMW_PLV]),
        .out(plv1)
    );
    assign pseg1    = DMW[1][`CSR_DMW_PSEG];
    assign vseg1    = DMW[1][`CSR_DMW_VSEG];

    assign interupt = |(ESTAT[`CSR_ESTAT_IS] & ECFG[`CSR_ECFG_LIE]) & CRMD[`CSR_CRMD_IE];

    assign eentry   = EENTRY;
    assign eraddr   = ERA;
    assign rentry   = TLBRENTRY;
endmodule
