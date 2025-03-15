`include "../macros.vh"

module TLB #(
    parameter TLB_ENTRIES = 16
) (
    input  wire                           clk,
    // search port
    input  wire [        `VPPN_WIDTH-1:0] s_vppn,
    input  wire [                    9:0] s_asid,
    output wire                           s_found,
    output wire [$clog2(TLB_ENTRIES)-1:0] s_index,
    // read port
    input  wire [$clog2(TLB_ENTRIES)-1:0] r_index,
    output wire [        `VPPN_WIDTH-1:0] r_vppn,
    output wire [                    5:0] r_ps,
    output wire                           r_g,
    output wire [                    9:0] r_asid,
    output wire                           r_e,
    output wire [         `PPN_WIDTH-1:0] r_ppn0,
    output wire [                    1:0] r_plv0,
    output wire [                    1:0] r_mat0,
    output wire                           r_d0,
    output wire                           r_v0,
    output wire [         `PPN_WIDTH-1:0] r_ppn1,
    output wire [                    1:0] r_plv1,
    output wire [                    1:0] r_mat1,
    output wire                           r_d1,
    output wire                           r_v1,
    // write port
    input  wire                           we,
    input  wire [$clog2(TLB_ENTRIES)-1:0] w_index,
    input  wire [        `VPPN_WIDTH-1:0] w_vppn,
    input  wire [                    5:0] w_ps,
    input  wire                           w_g,
    input  wire [                    9:0] w_asid,
    input  wire                           w_e,
    input  wire [         `PPN_WIDTH-1:0] w_ppn0,
    input  wire [                    1:0] w_plv0,
    input  wire [                    1:0] w_mat0,
    input  wire                           w_d0,
    input  wire                           w_v0,
    input  wire [         `PPN_WIDTH-1:0] w_ppn1,
    input  wire [                    1:0] w_plv1,
    input  wire [                    1:0] w_mat1,
    input  wire                           w_d1,
    input  wire                           w_v1,
    // invalid port
    input  wire                           invtlb_en,
    input  wire [                    4:0] invtlb_op,
    input  wire [        `VPPN_WIDTH-1:0] invtlb_vppn,
    input  wire [                    9:0] invtlb_asid,
    // search port 0 (for fetch inst)
    input  wire [        `VPPN_WIDTH-1:0] s0_vppn,
    input  wire                           s0_va_bit12,
    input  wire [                    9:0] s0_asid,
    output wire                           s0_found,
    output wire [$clog2(TLB_ENTRIES)-1:0] s0_index,
    output wire [                    5:0] s0_ps,
    output wire [         `PPN_WIDTH-1:0] s0_ppn,
    output wire [                    1:0] s0_plv,
    output wire [                    1:0] s0_mat,
    output wire                           s0_d,
    output wire                           s0_v,
    // search port 1 (for load/store)
    input  wire [        `VPPN_WIDTH-1:0] s1_vppn,
    input  wire                           s1_va_bit12,
    input  wire [                    9:0] s1_asid,
    output wire                           s1_found,
    output wire [$clog2(TLB_ENTRIES)-1:0] s1_index,
    output wire [                    5:0] s1_ps,
    output wire [         `PPN_WIDTH-1:0] s1_ppn,
    output wire [                    1:0] s1_plv,
    output wire [                    1:0] s1_mat,
    output wire                           s1_d,
    output wire                           s1_v
);
    wire [     `VALEN-1:0] tlb_va                                [TLB_ENTRIES-1:0];
    reg  [`VPPN_WIDTH-1:0] tlb_vppn                              [TLB_ENTRIES-1:0];
    reg  [            5:0] tlb_ps                                [TLB_ENTRIES-1:0];
    reg                    tlb_g                                 [TLB_ENTRIES-1:0];
    reg  [            9:0] tlb_asid                              [TLB_ENTRIES-1:0];
    reg                    tlb_e                                 [TLB_ENTRIES-1:0];
    reg  [ `PPN_WIDTH-1:0] tlb_ppn0                              [TLB_ENTRIES-1:0];
    reg  [            1:0] tlb_plv0                              [TLB_ENTRIES-1:0];
    reg  [            1:0] tlb_mat0                              [TLB_ENTRIES-1:0];
    reg                    tlb_d0                                [TLB_ENTRIES-1:0];
    reg                    tlb_v0                                [TLB_ENTRIES-1:0];
    reg  [ `PPN_WIDTH-1:0] tlb_ppn1                              [TLB_ENTRIES-1:0];
    reg  [            1:0] tlb_plv1                              [TLB_ENTRIES-1:0];
    reg  [            1:0] tlb_mat1                              [TLB_ENTRIES-1:0];
    reg                    tlb_d1                                [TLB_ENTRIES-1:0];
    reg                    tlb_v1                                [TLB_ENTRIES-1:0];

    wire [     `VALEN-1:0] s_va = {s_vppn, 13'h0};
    wire [       2**5-1:0] s_vppn_match                          [TLB_ENTRIES-1:0];
    wire [TLB_ENTRIES-1:0] s_match;  // vector for encoding
    wire [     `VALEN-1:0] invtlb_va = {invtlb_vppn, 13'h0};
    wire [       2**5-1:0] invtlb_vppn_match                     [TLB_ENTRIES-1:0];
    wire                   invtlb_match                          [TLB_ENTRIES-1:0];
    wire [     `VALEN-1:0] s0_va = {s0_vppn, s0_va_bit12, 12'h0};
    wire [       2**5-1:0] s0_vppn_match                         [TLB_ENTRIES-1:0];
    wire [TLB_ENTRIES-1:0] s0_match;  // vector for encoding
    wire                   s0_odd;
    wire [     `VALEN-1:0] s1_va = {s1_vppn, s1_va_bit12, 12'h0};
    wire [       2**5-1:0] s1_vppn_match                         [TLB_ENTRIES-1:0];
    wire [TLB_ENTRIES-1:0] s1_match;  // vector for encoding
    wire                   s1_odd;

    assign r_vppn = tlb_vppn[r_index];
    assign r_ps   = tlb_ps[r_index];
    assign r_g    = tlb_g[r_index];
    assign r_asid = tlb_asid[r_index];
    assign r_e    = tlb_e[r_index];
    assign r_ppn0 = tlb_ppn0[r_index];
    assign r_plv0 = tlb_plv0[r_index];
    assign r_mat0 = tlb_mat0[r_index];
    assign r_d0   = tlb_d0[r_index];
    assign r_v0   = tlb_v0[r_index];
    assign r_ppn1 = tlb_ppn1[r_index];
    assign r_plv1 = tlb_plv1[r_index];
    assign r_mat1 = tlb_mat1[r_index];
    assign r_d1   = tlb_d1[r_index];
    assign r_v1   = tlb_v1[r_index];

    genvar i, j;
    generate
        for (i = 0; i < TLB_ENTRIES; i = i + 1) begin : gen_tlb
            always @(posedge clk) begin
                if (we & w_index == i) begin
                    tlb_vppn[i] <= w_vppn;
                    tlb_ps[i]   <= w_ps;
                    tlb_g[i]    <= w_g;
                    tlb_asid[i] <= w_asid;
                    tlb_e[i]    <= w_e;
                    tlb_ppn0[i] <= w_ppn0;
                    tlb_plv0[i] <= w_plv0;
                    tlb_mat0[i] <= w_mat0;
                    tlb_d0[i]   <= w_d0;
                    tlb_v0[i]   <= w_v0;
                    tlb_ppn1[i] <= w_ppn1;
                    tlb_plv1[i] <= w_plv1;
                    tlb_mat1[i] <= w_mat1;
                    tlb_d1[i]   <= w_d1;
                    tlb_v1[i]   <= w_v1;
                end else if (invtlb_en & invtlb_match[i]) begin
                    tlb_e[i] <= 1'b0;
                end
            end

            assign tlb_va[i]                    = {tlb_vppn[i], 13'h0};

            assign s_vppn_match[i][2**5-1]     = 1'b1;
            assign invtlb_vppn_match[i][2**5-1] = 1'b1;
            assign s0_vppn_match[i][2**5-1]     = 1'b1;
            assign s1_vppn_match[i][2**5-1]     = 1'b1;
            for (j = 0; j < 2 ** 5 - 1; j = j + 1) begin : gen_vppn_match
                assign s_vppn_match[i][j]     = tlb_va[i][`VALEN-1:j+1] == s_va[`VALEN-1:j+1];
                assign invtlb_vppn_match[i][j] = tlb_va[i][`VALEN-1:j+1] == invtlb_va[`VALEN-1:j+1];
                assign s0_vppn_match[i][j] = tlb_va[i][`VALEN-1:j+1] == s0_va[`VALEN-1:j+1];
                assign s1_vppn_match[i][j] = tlb_va[i][`VALEN-1:j+1] == s1_va[`VALEN-1:j+1];
            end

            assign s_match[i] = tlb_e[i] & (tlb_g[i] | tlb_asid[i] == s_asid) &
                                s_vppn_match[i][tlb_ps[i]];
            assign invtlb_match[i] = invtlb_op == 5'h00 |
                                     invtlb_op == 5'h01 |
                                     invtlb_op == 5'h02 & tlb_g[i] |
                                     invtlb_op == 5'h03 & ~tlb_g[i] |
                                     invtlb_op == 5'h04 & ~tlb_g[i] & tlb_asid[i] == invtlb_asid |
                                     invtlb_op == 5'h05 & ~tlb_g[i] & tlb_asid[i] == invtlb_asid &
                                     invtlb_vppn_match[i][tlb_ps[i]] |
                                     invtlb_op == 5'h06 & (tlb_g[i] | tlb_asid[i] == invtlb_asid) &
                                     invtlb_vppn_match[i][tlb_ps[i]];
            assign s0_match[i] = tlb_e[i] & (tlb_g[i] | tlb_asid[i] == s0_asid) &
                                 s0_vppn_match[i][tlb_ps[i]];
            assign s1_match[i] = tlb_e[i] & (tlb_g[i] | tlb_asid[i] == s1_asid) &
                                 s1_vppn_match[i][tlb_ps[i]];
        end
    endgenerate

    assign s_found = |s_match;
    encoder #(
        .WIDTH(TLB_ENTRIES)
    ) encoder_s (
        .in (s_match),
        .out(s_index)
    );

    assign s0_found = |s0_match;
    encoder #(
        .WIDTH(TLB_ENTRIES)
    ) encoder_s0 (
        .in (s0_match),
        .out(s0_index)
    );
    assign s0_ps    = tlb_ps[s0_index];
    assign s0_odd   = s0_va[s0_ps];
    assign s0_ppn   = s0_odd ? tlb_ppn1[s0_index] : tlb_ppn0[s0_index];
    assign s0_plv   = s0_odd ? tlb_plv1[s0_index] : tlb_plv0[s0_index];
    assign s0_mat   = s0_odd ? tlb_mat1[s0_index] : tlb_mat0[s0_index];
    assign s0_d     = s0_odd ? tlb_d1[s0_index] : tlb_d0[s0_index];
    assign s0_v     = s0_odd ? tlb_v1[s0_index] : tlb_v0[s0_index];

    assign s1_found = |s1_match;
    encoder #(
        .WIDTH(TLB_ENTRIES)
    ) encoder_s1 (
        .in (s1_match),
        .out(s1_index)
    );
    assign s1_ps  = tlb_ps[s1_index];
    assign s1_odd = s1_va[s1_ps];
    assign s1_ppn = s1_odd ? tlb_ppn1[s1_index] : tlb_ppn0[s1_index];
    assign s1_plv = s1_odd ? tlb_plv1[s1_index] : tlb_plv0[s1_index];
    assign s1_mat = s1_odd ? tlb_mat1[s1_index] : tlb_mat0[s1_index];
    assign s1_d   = s1_odd ? tlb_d1[s1_index] : tlb_d0[s1_index];
    assign s1_v   = s1_odd ? tlb_v1[s1_index] : tlb_v0[s1_index];
endmodule
