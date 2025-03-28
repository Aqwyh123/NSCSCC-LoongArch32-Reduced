`include "../macros.h"

module MMU #(
    parameter TLB_ENTRIES = 16
) (
    input  wire                                 clk,
    // TLB signals
    input  wire [`TLB_OP_WIDTH-1:`TLB_OP_WRITE] TLB_operation,
    input  wire [                         31:0] invtlb_vaddr,
    input  wire [                         31:0] invtlb_asid,
    input  wire [      $clog2(TLB_ENTRIES)-1:0] TLB_rw_index,
    input  wire [            `TLBEHI_WIDTH-1:0] TLB_sw_hi,
    input  wire [            `TLBELO_WIDTH-1:0] TLB_w_lo0,
    input  wire [            `TLBELO_WIDTH-1:0] TLB_w_lo1,
    input  wire [      $clog2(TLB_ENTRIES)-1:0] TLB_f_index,
    output wire                                 TLB_s_hit,
    output wire [      $clog2(TLB_ENTRIES)-1:0] TLB_s_index,
    output wire [            `TLBEHI_WIDTH-1:0] TLB_r_hi,
    output wire [            `TLBELO_WIDTH-1:0] TLB_r_lo0,
    output wire [            `TLBELO_WIDTH-1:0] TLB_r_lo1,
    // status signals
    input  wire                                 CSR_da,
    input  wire                                 CSR_pg,
    input  wire [                          9:0] CSR_asid,
    input  wire [                          1:0] CSR_plv,
    // DMW signals
    input  wire [                          1:0] DMW0_plv,
    input  wire [                          2:0] DMW0_pseg,
    input  wire [                          2:0] DMW0_vseg,
    input  wire [                          1:0] DMW1_plv,
    input  wire [                          2:0] DMW1_pseg,
    input  wire [                          2:0] DMW1_vseg,
    // inst fetch signals
    input  wire                                 inst_fetch,
    input  wire [                         31:0] inst_vaddr,
    output wire [                         31:0] inst_paddr,
    // data load / store signals
    input  wire                                 data_load,
    input  wire                                 data_store,
    input  wire [                         31:0] data_vaddr,
    output wire [                         31:0] data_paddr,
    // exception signals
    output wire                                 PIL,
    output wire                                 PIS,
    output wire                                 PIF,
    output wire                                 PME,
    output wire                                 inst_PPI,
    output wire                                 data_PPI,
    output wire                                 inst_TLBR,
    output wire                                 data_TLBR
);
    wire [$clog2(TLB_ENTRIES)-1:0] TLB_wf_index;

    wire                           CSR_mode_is_dir;
    // wire                           CSR_mode_is_map;

    wire                           inst_DMW0_hit;
    wire                           inst_DMW1_hit;
    wire                           TLB0_hit;
    wire [$clog2(TLB_ENTRIES)-1:0] TLB0_index;
    wire [                    5:0] TLB0_ps;
    wire [        31:`PPN_4KB_LSB] TLB0_ppn;
    wire [                    1:0] TLB0_plv;
    wire [                    1:0] TLB0_mat;
    wire                           TLB0_d;
    wire                           TLB0_v;

    wire                           data_DMW0_hit;
    wire                           data_DMW1_hit;
    wire                           TLB1_hit;
    wire [$clog2(TLB_ENTRIES)-1:0] TLB1_index;
    wire [                    5:0] TLB1_ps;
    wire [        31:`PPN_4KB_LSB] TLB1_ppn;
    wire [                    1:0] TLB1_plv;
    wire [                    1:0] TLB1_mat;
    wire                           TLB1_d;
    wire                           TLB1_v;

    assign TLB_wf_index = {$clog2(
        TLB_ENTRIES
    ) {TLB_operation[`TLB_OP_WRITE]}} & TLB_rw_index | {$clog2(
        TLB_ENTRIES
    ) {TLB_operation[`TLB_OP_FILL]}} & TLB_f_index;

    assign CSR_mode_is_dir = CSR_da & ~CSR_pg;
    // assign CSR_mode_is_map = ~CSR_da & CSR_pg;

    assign inst_DMW0_hit = inst_vaddr[31:29] == DMW0_vseg & CSR_plv <= DMW0_plv;
    assign inst_DMW1_hit = inst_vaddr[31:29] == DMW1_vseg & CSR_plv <= DMW1_plv;
    assign inst_paddr = CSR_mode_is_dir ? inst_vaddr :
                        inst_DMW0_hit ? {DMW0_pseg, inst_vaddr[28:0]} :
                        inst_DMW1_hit ? {DMW1_pseg, inst_vaddr[28:0]} :
                        TLB0_ps == 6'd12 ? {TLB0_ppn[31:`PPN_4KB_LSB], inst_vaddr[12-1:0]} :
                       {TLB0_ppn[31:`PPN_4MB_LSB], inst_vaddr[22-1:0]};
    assign data_DMW0_hit = data_vaddr[31:29] == DMW0_vseg & CSR_plv <= DMW0_plv;
    assign data_DMW1_hit = data_vaddr[31:29] == DMW1_vseg & CSR_plv <= DMW1_plv;
    assign data_paddr = CSR_mode_is_dir ? data_vaddr :
                        data_DMW0_hit ? {DMW0_pseg, data_vaddr[28:0]} :
                        data_DMW1_hit ? {DMW1_pseg, data_vaddr[28:0]} :
                        TLB1_ps == 6'd12 ? {TLB1_ppn[31:`PPN_4KB_LSB], data_vaddr[12-1:0]} :
                       {TLB1_ppn[31:`PPN_4MB_LSB], data_vaddr[22-1:0]};

    TLB #(
        .TLB_ENTRIES(TLB_ENTRIES)
    ) tlb (
        .clk        (clk),
        .s_vppn     (TLB_sw_hi[`TLBEHI_VPPN]),
        .s_asid     (TLB_sw_hi[`TLBEHI_ASID]),
        .s_hit      (TLB_s_hit),
        .s_index    (TLB_s_index),
        .r_index    (TLB_rw_index),
        .r_vppn     (TLB_r_hi[`TLBEHI_VPPN]),
        .r_ps       (TLB_r_hi[`TLBEHI_PS]),
        .r_g        (TLB_r_hi[`TLBEHI_G]),
        .r_asid     (TLB_r_hi[`TLBEHI_ASID]),
        .r_e        (TLB_r_hi[`TLBEHI_E]),
        .r_ppn0     (TLB_r_lo0[`TLBELO_PPN]),
        .r_plv0     (TLB_r_lo0[`TLBELO_PLV]),
        .r_mat0     (TLB_r_lo0[`TLBELO_MAT]),
        .r_d0       (TLB_r_lo0[`TLBELO_D]),
        .r_v0       (TLB_r_lo0[`TLBELO_V]),
        .r_ppn1     (TLB_r_lo1[`TLBELO_PPN]),
        .r_plv1     (TLB_r_lo1[`TLBELO_PLV]),
        .r_mat1     (TLB_r_lo1[`TLBELO_MAT]),
        .r_d1       (TLB_r_lo1[`TLBELO_D]),
        .r_v1       (TLB_r_lo1[`TLBELO_V]),
        .we         (TLB_operation[`TLB_OP_WRITE] | TLB_operation[`TLB_OP_FILL]),
        .w_index    (TLB_wf_index),
        .w_vppn     (TLB_sw_hi[`TLBEHI_VPPN]),
        .w_ps       (TLB_sw_hi[`TLBEHI_PS]),
        .w_g        (TLB_sw_hi[`TLBEHI_G]),
        .w_asid     (TLB_sw_hi[`TLBEHI_ASID]),
        .w_e        (TLB_sw_hi[`TLBEHI_E]),
        .w_ppn0     (TLB_w_lo0[`TLBELO_PPN]),
        .w_plv0     (TLB_w_lo0[`TLBELO_PLV]),
        .w_mat0     (TLB_w_lo0[`TLBELO_MAT]),
        .w_d0       (TLB_w_lo0[`TLBELO_D]),
        .w_v0       (TLB_w_lo0[`TLBELO_V]),
        .w_ppn1     (TLB_w_lo1[`TLBELO_PPN]),
        .w_plv1     (TLB_w_lo1[`TLBELO_PLV]),
        .w_mat1     (TLB_w_lo1[`TLBELO_MAT]),
        .w_d1       (TLB_w_lo1[`TLBELO_D]),
        .w_v1       (TLB_w_lo1[`TLBELO_V]),
        .invtlb_op  (TLB_operation[`TLB_OP_INV]),
        .invtlb_vppn(invtlb_vaddr[31:`VPPN_4KB_LSB]),
        .invtlb_asid(invtlb_asid[9:0]),
        .s0_vppn    (inst_vaddr[31:`VPPN_4KB_LSB]),
        .s0_va_bit12(inst_vaddr[12]),
        .s0_asid    (CSR_asid),
        .s0_hit     (TLB0_hit),
        .s0_index   (TLB0_index),
        .s0_ps      (TLB0_ps),
        .s0_ppn     (TLB0_ppn),
        .s0_plv     (TLB0_plv),
        .s0_mat     (TLB0_mat),
        .s0_d       (TLB0_d),
        .s0_v       (TLB0_v),
        .s1_vppn    (data_vaddr[31:`VPPN_4KB_LSB]),
        .s1_va_bit12(data_vaddr[12]),
        .s1_asid    (CSR_asid),
        .s1_hit     (TLB1_hit),
        .s1_index   (TLB1_index),
        .s1_ps      (TLB1_ps),
        .s1_ppn     (TLB1_ppn),
        .s1_plv     (TLB1_plv),
        .s1_mat     (TLB1_mat),
        .s1_d       (TLB1_d),
        .s1_v       (TLB1_v)
    );

    assign PIL = data_load & ~CSR_mode_is_dir & ~data_DMW0_hit & ~data_DMW1_hit &
                 TLB1_hit & ~TLB1_v & CSR_plv <= TLB1_plv;
    assign PIS = data_store & ~CSR_mode_is_dir & ~data_DMW0_hit & ~data_DMW1_hit &
                 TLB1_hit & ~TLB1_v & CSR_plv <= TLB1_plv;
    assign PIF = inst_fetch & ~CSR_mode_is_dir & ~inst_DMW0_hit & ~inst_DMW1_hit &
                 TLB0_hit & ~TLB0_v & CSR_plv <= TLB0_plv;
    assign PME = data_store & ~CSR_mode_is_dir & ~data_DMW0_hit & ~data_DMW1_hit &
                 TLB1_hit & TLB1_v & CSR_plv <= TLB1_plv & ~TLB1_d;
    assign inst_PPI = inst_fetch & ~CSR_mode_is_dir &
                     ~inst_DMW0_hit & ~inst_DMW1_hit & TLB0_hit & TLB0_v & CSR_plv > TLB0_plv;
    assign data_PPI = (data_load | data_store) & ~CSR_mode_is_dir &
                      ~data_DMW0_hit & ~data_DMW1_hit & TLB1_hit & TLB1_v & CSR_plv > TLB1_plv;
    assign inst_TLBR = inst_fetch & ~CSR_mode_is_dir & ~inst_DMW0_hit & ~inst_DMW1_hit & ~TLB0_hit;
    assign data_TLBR = (data_load | data_store) & ~CSR_mode_is_dir &
                       ~data_DMW0_hit & ~data_DMW1_hit & ~TLB1_hit;
endmodule
