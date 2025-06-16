`include "macros.h"

module cache #(
    parameter CACHE_AW           = `CACHE_AW,
    parameter CACHE_DATA_NUM     = `CACHE_DATA_NUM,
    parameter CACHE_WAY_NUM      = `CACHE_WAY_NUM,
    parameter CACHE_LINE_BANKS   = `CACHE_LINE_BANKS,
    parameter CACHE_TAG_WIDTH    = `CACHE_TAG_WIDTH,
    parameter CACHE_INDEX_WIDTH  = `CACHE_INDEX_WIDTH,
    parameter CACHE_OFFSET_WIDTH = `CACHE_OFFSET_WIDTH,
    parameter CACHE_DATA_WIDTH   = `CACHE_DATA_WIDTH,
    parameter CACHE_STRB_WIDTH   = `CACHE_STRB_WIDTH
) (
    input  wire                         clk,
    input  wire                         reset,
    // CPU interface
    input  wire                         valid,
    input  wire                         op,
    input  wire [                 31:0] vaddr,
    input  wire [`CACHE_STRB_WIDTH-1:0] wstrb,
    input  wire [`CACHE_DATA_WIDTH-1:0] wdata,
    output wire                         addr_ok,
    output wire                         data_ok,
    output wire [`CACHE_DATA_WIDTH-1:0] rdata,
    input  wire                         access_type,
    input  wire [                  2:0] op_size,
    input  wire                         is_cacop,
    input  wire [                  4:0] cacop_code,
    // MMU interface
    output wire [                  2:0] search_op,
    input  wire [                 31:0] paddr,
    // AXI-like interface
    output wire                         rd_req,
    output wire [                  2:0] rd_type,
    output wire [                 31:0] rd_addr,
    input  wire                         rd_rdy,
    input  wire                         ret_valid,
    input  wire [                  1:0] ret_last,
    input  wire [                 31:0] ret_data,
    output wire                         wr_req,
    output wire [                  2:0] wr_type,
    output wire [                 31:0] wr_addr,
    output wire [                  3:0] wr_wstrb,
    output wire [                127:0] wr_data,
    input  wire                         wr_rdy
);
    // ========== 状态机定义 ==========
    localparam M_IDLE = 3'd0;
    localparam M_LOOKUP = 3'd1;
    localparam M_MISS = 3'd2;
    localparam M_REPLACE = 3'd3;
    localparam M_REFILL = 3'd4;
    localparam H_IDLE = 1'b0;
    localparam H_WRITE = 1'b1;

    wire [ CACHE_INDEX_WIDTH-1:0] index; // V
    wire [CACHE_OFFSET_WIDTH-1:0] offset; // V
    wire [   CACHE_TAG_WIDTH-1:0] tag; // P

    assign index     = vaddr[`CACHE_INDEX_WIDTH+`CACHE_OFFSET_WIDTH-1 : `CACHE_OFFSET_WIDTH];
    assign offset    = vaddr[`CACHE_OFFSET_WIDTH-1 : 0];
    assign tag       = paddr[31 : `CACHE_INDEX_WIDTH+`CACHE_OFFSET_WIDTH];
 
    reg search_op_vld;
    always @(posedge clk) begin
        if (reset)               search_op_vld <= 1'b0;
        else                     search_op_vld <= valid && addr_ok;
    end
    assign search_op = search_op_vld ? {1'b0, op, ~op} : 3'b0;
 
    reg  [                   2:0] main_st;
    reg  [                   2:0] main_nst;
    reg                           hit_st;
    reg                           hit_nst;

    // 其他控制与请求信号
    wire                          wr_op;
    wire                          rd_op;
    wire                          rd_conflict;
    wire                          replace_rd;
    wire                          lookup_rd;
    wire                          rdreq_lookup_rd;
    wire                          hitwrite_wr;

    wire [ CACHE_INDEX_WIDTH-1:0] replace_index;
    reg                           replace_way;
    wire [   CACHE_TAG_WIDTH-1:0] replace_tag;

    // tagv/data SRAM接口信号
    wire                          tagv_rd;
    wire                          tagv_wr;
    wire [          CACHE_AW-1:0] tagv_index;
    wire [     CACHE_WAY_NUM-1:0] tagv_way;
    wire [     CACHE_TAG_WIDTH:0] tagv_d;

    wire                          data_rd;
    wire                          data_wr;
    wire [          CACHE_AW-1:0] data_index;
    wire [  CACHE_STRB_WIDTH-1:0] data_wstrb;
    wire [     CACHE_WAY_NUM-1:0] data_way;
    wire [                   1:0] data_offset;
    wire [  CACHE_DATA_WIDTH-1:0] data_d;

    // ====== 请求Buffer相关 ======
    reg  [                  78:0] request_buf;
    wire                          req_buf_up_en;
    wire                          op_1d;
    wire                          access_type_1d;
    wire [                   2:0] req_op_size_1d;
    wire [ CACHE_INDEX_WIDTH-1:0] index_1d;
    wire [   CACHE_TAG_WIDTH-1:0] tag_1d;
    wire [CACHE_OFFSET_WIDTH-1:0] offset_1d;
    wire [  CACHE_STRB_WIDTH-1:0] wstrb_1d;
    wire [  CACHE_DATA_WIDTH-1:0] wdata_1d;
    wire                          is_cacop_1d;
    wire [                   4:0] cacop_code_1d;
    reg  [  CACHE_DATA_WIDTH-1:0] local_rdata;

    // 读出请求Buffer分配
    assign is_cacop_1d    = request_buf[78];
    assign cacop_code_1d  = request_buf[77:73];
    assign op_1d          = request_buf[72];
    assign access_type_1d = request_buf[71];
    assign req_op_size_1d = request_buf[70:68];
    assign index_1d       = request_buf[67:60];
    assign tag_1d         = request_buf[59:40];
    assign offset_1d      = request_buf[39:36];
    assign wstrb_1d       = request_buf[35:32];
    assign wdata_1d       = request_buf[31:0];

    // ====== 写命中Buffer相关 ======
    reg                           wbuf_vld;
    reg  [                  49:0] write_buf;
    wire [  CACHE_DATA_WIDTH-1:0] wbuf_data;
    wire [ CACHE_INDEX_WIDTH-1:0] wbuf_index;
    wire [CACHE_OFFSET_WIDTH-1:0] wbuf_offset;
    wire [  CACHE_STRB_WIDTH-1:0] wbuf_strb;
    wire [     CACHE_WAY_NUM-1:0] wbuf_way;

    assign {wbuf_data, wbuf_index, wbuf_offset, wbuf_strb, wbuf_way} = write_buf;

    // Refill计数
    reg  [                 1:0] return_cnt;

    // Dirty表
    reg  [  CACHE_DATA_NUM-1:0] d_table              [CACHE_WAY_NUM-1:0];

    // 伪随机替换
    reg                         rand_data;

    // ------ SRAM读写信号 ------
    wire [CACHE_DATA_WIDTH-1:0] sram_data_q          [CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];
    wire                        sram_data_rd         [CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];
    wire                        sram_data_wr         [CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];
    wire [CACHE_STRB_WIDTH-1:0] sram_data_wstrb      [CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];
    wire [        CACHE_AW-1:0] sram_data_index      [CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];
    wire [CACHE_DATA_WIDTH-1:0] sram_data_d          [CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];

    wire [   CACHE_TAG_WIDTH:0] sram_tagv_q          [CACHE_WAY_NUM-1:0];
    wire                        sram_tagv_rd         [CACHE_WAY_NUM-1:0];
    wire                        sram_tagv_wr         [CACHE_WAY_NUM-1:0];
    wire [        CACHE_AW-1:0] sram_tagv_index      [CACHE_WAY_NUM-1:0];
    wire [   CACHE_TAG_WIDTH:0] sram_tagv_d          [CACHE_WAY_NUM-1:0];

    // ===== 命中相关信号 =====
    wire [ CACHE_TAG_WIDTH-1:0] tag_sel              [CACHE_WAY_NUM-1:0];
    wire [   CACHE_WAY_NUM-1:0] valid_sel;
    wire [   CACHE_WAY_NUM-1:0] tag_hit;
    wire                        req_hit;

    wire [                 1:0] cacop_type;
    wire                        cacop_is_store_tag;
    wire                        cacop_is_index_op;
    wire                        cacop_is_hit_op;
    wire                        cacop_need_writeback;

    assign cacop_type         = cacop_code_1d[`CACOP_OP_TYPE_MSB:`CACOP_OP_TYPE_LSB];
    assign cacop_is_store_tag = is_cacop_1d && (cacop_type == `CACOP_TYPE_STORE_TAG);
    assign cacop_is_index_op  = is_cacop_1d && (cacop_type == `CACOP_TYPE_INDEX_OP);
    assign cacop_is_hit_op    = is_cacop_1d && (cacop_type == `CACOP_TYPE_HIT_OP);

    // 状态机控制
    assign wr_op              = valid & op;
    assign rd_op              = valid & !op;
    assign rdreq_lookup_rd    = (main_nst == M_LOOKUP);
    assign lookup_rd          = (main_nst == M_LOOKUP) || (main_st == M_IDLE && valid && is_cacop);
    assign hitwrite_wr        = wbuf_vld;

    // 替换相关信号
    assign replace_rd         = (main_nst == M_REPLACE) && (main_st == M_MISS);
    assign replace_index      = index_1d;
    assign replace_tag        = sram_tagv_q[replace_way][CACHE_TAG_WIDTH:1];

    // refill信号
    wire                         refill_wr;
    wire [CACHE_INDEX_WIDTH-1:0] refill_index;
    wire [  CACHE_TAG_WIDTH-1:0] refill_tag;
    wire [                  1:0] refill_bank;
    wire [ CACHE_STRB_WIDTH-1:0] refill_wstrb;
    wire [ CACHE_DATA_WIDTH-1:0] refill_data;
    wire [    CACHE_WAY_NUM-1:0] refill_way;

    assign refill_wr     = (ret_valid) || (main_st == M_REFILL && is_cacop_1d);
    assign refill_index  = replace_index;
    assign refill_tag    = tag_1d;
    assign refill_bank   = return_cnt;
    assign refill_wstrb  = wstrb_1d;
    assign refill_data   = (op_1d && (refill_bank == offset_1d[3:2])) ? wdata_1d : ret_data;
    assign refill_way    = (replace_way) ? {{(CACHE_WAY_NUM - 1) {1'b0}}, 1'b1} : {1'b1, {(CACHE_WAY_NUM - 1) {1'b0}}};

    // tagv信号
    assign tagv_rd       = lookup_rd | replace_rd;
    assign tagv_wr       = (refill_wr && access_type_1d) || (refill_wr && is_cacop_1d);
    assign tagv_index    = lookup_rd ? index : replace_rd ? replace_index : refill_index;
    assign tagv_way      = lookup_rd ? {CACHE_WAY_NUM{1'b1}} : replace_rd ? 1'b1 << replace_way : is_cacop_1d & (cacop_is_store_tag | cacop_is_index_op) ? {CACHE_WAY_NUM{1'b1}} : refill_way;
    assign tagv_d        = cacop_is_store_tag ? {`CACHE_TAG_WIDTH'b0, 1'b0} : is_cacop_1d ? {tag_sel[replace_way], 1'b0} : {tag_1d, 1'b1};

    // data信号
    assign data_rd       = rdreq_lookup_rd | replace_rd;
    assign data_wr       = (refill_wr && access_type_1d && !is_cacop_1d) || hitwrite_wr;
    assign data_index    = rdreq_lookup_rd ? index : replace_rd ? replace_index : refill_wr ? refill_index : wbuf_index;
    assign data_wstrb    = refill_wr ? {CACHE_STRB_WIDTH{1'b1}} : wbuf_strb;
    assign data_offset   = refill_wr ? refill_bank : wbuf_offset[3:2];
    assign data_way      = refill_wr ? refill_way : wbuf_way;
    assign data_d        = refill_wr ? refill_data : wbuf_data;

    // 请求Buffer
    assign req_buf_up_en = (main_nst == M_LOOKUP);

    // 读数据归并
    integer m;
    always @(*) begin
        local_rdata = {CACHE_DATA_WIDTH{1'b0}};
        for (m = 0; m < CACHE_WAY_NUM; m = m + 1) begin
            if (tag_hit[m]) local_rdata = sram_data_q[m][offset_1d[3:2]];
        end
    end

    // 冲突检测
    assign rd_conflict = wbuf_vld;

    // ========== always 块/时序逻辑部分 ==========

    // 请求Buffer
    always @(posedge clk) begin
        if (reset) request_buf <= 79'b0;
        else if (req_buf_up_en) request_buf <= {is_cacop, cacop_code, op, access_type, op_size, index, tag, offset, wstrb, wdata};
    end

    // 写命中buffer逻辑
    always @(posedge clk) begin
        if (hit_nst == H_WRITE) write_buf <= {wdata_1d, index_1d, offset_1d, wstrb_1d, tag_hit};
    end

    always @(posedge clk) begin
        if (reset) wbuf_vld <= 1'b0;
        else if (hit_nst == H_WRITE) wbuf_vld <= 1'b1;
        else if (hit_nst == H_IDLE) wbuf_vld <= 1'b0;
    end

    // 随机替换
    always @(posedge clk) begin
        if (reset) rand_data <= 1'b0;
        else rand_data <= ~rand_data;
    end

    // miss/replace/dirty记录
    always @(posedge clk) begin
        if (reset) replace_way <= 1'b0;
        else if ((main_st == M_LOOKUP) && (main_nst == M_MISS || (is_cacop_1d && main_nst != M_IDLE))) begin
            if (cacop_is_hit_op) begin
                replace_way <= |(tag_hit & 2'b10);
            end else if (!access_type_1d && |tag_hit) begin
                replace_way <= tag_hit[1];
            end else begin
                replace_way <= rand_data;
            end
        end
    end

    wire evict_line_is_dirty = d_table[replace_way][index_1d];

    assign cacop_need_writeback = is_cacop_1d && valid_sel[replace_way] && evict_line_is_dirty && (cacop_is_index_op || cacop_is_hit_op);

    // refill计数
    always @(posedge clk) begin
        if (reset) begin
            return_cnt <= 2'b0;
        end else if ((main_st == M_MISS && main_nst == M_REFILL) || (main_st == M_REPLACE && main_nst == M_REFILL)) begin
            return_cnt <= 2'b0;
        end else if (main_st == M_REFILL && ret_valid) begin
            if (ret_last[0]) begin
                return_cnt <= 2'b0;
            end else begin
                return_cnt <= return_cnt + 1'b1;
            end
        end
    end

    // 写回及读出AXI接口相关
    reg [127:0] wr_data_reg;
    reg [ 31:0] wr_addr_reg;
    reg [  2:0] wr_type_reg;
    reg [  3:0] wr_wstrb_reg;
    reg         wr_req_reg;

    reg         suc_wr_req_reg;
    reg [  2:0] suc_wr_type_reg;
    reg [ 31:0] suc_wr_addr_reg;
    reg [  3:0] suc_wr_wstrb_reg;
    reg [127:0] suc_wr_data_reg;

    always @(posedge clk) begin
        if (reset) begin
            wr_req_reg <= 1'b0;
        end else begin
            if ((main_st == M_MISS || (main_st == M_LOOKUP && is_cacop_1d)) && (evict_line_is_dirty || cacop_need_writeback) && wr_rdy) begin
                if (!wr_req_reg) begin
                    wr_data_reg  <= {sram_data_q[replace_way][3], sram_data_q[replace_way][2], sram_data_q[replace_way][1], sram_data_q[replace_way][0]};
                    wr_addr_reg  <= {sram_tagv_q[replace_way][CACHE_TAG_WIDTH:1], index_1d, 4'b0};
                    wr_type_reg  <= 3'b100;
                    wr_wstrb_reg <= 4'b1111;
                    wr_req_reg   <= 1'b1;
                end
            end
            if (wr_rdy && wr_req_reg) begin
                if (!suc_wr_req_reg) begin
                    wr_req_reg <= 1'b0;
                end
            end
        end
    end

    assign wr_req   = wr_req_reg || suc_wr_req_reg;
    assign wr_type  = suc_wr_req_reg ? suc_wr_type_reg : wr_type_reg;
    assign wr_addr  = suc_wr_req_reg ? suc_wr_addr_reg : wr_addr_reg;
    assign wr_data  = suc_wr_req_reg ? suc_wr_data_reg : wr_data_reg;
    assign wr_wstrb = suc_wr_req_reg ? suc_wr_wstrb_reg : wr_wstrb_reg;

    // refill读AXI信号
    assign rd_addr  = access_type_1d ? {refill_tag, refill_index, 4'b0} : {tag_1d, index_1d, offset_1d[3:0]};
    assign rd_type  = access_type_1d ? 3'b100 : req_op_size_1d;

    assign rd_req   = main_st == M_REPLACE && !wr_req && wr_rdy;

    always @(posedge clk) begin
        if (reset) begin
            suc_wr_req_reg   <= 1'b0;
            suc_wr_type_reg  <= 3'b0;
            suc_wr_addr_reg  <= 32'b0;
            suc_wr_wstrb_reg <= 4'b0;
            suc_wr_data_reg  <= 128'b0;
        end else if ((main_st == M_MISS) && !access_type_1d && op_1d && !suc_wr_req_reg) begin
            suc_wr_req_reg   <= 1'b1;
            suc_wr_type_reg  <= req_op_size_1d;
            suc_wr_addr_reg  <= {tag_1d, index_1d, offset_1d[3:0]};
            suc_wr_wstrb_reg <= wstrb_1d;
            suc_wr_data_reg  <= offset_1d[3:2] == 2'b00 ? {96'b0, wdata_1d} : offset_1d[3:2] == 2'b01 ? {64'b0, wdata_1d, 32'b0} : offset_1d[3:2] == 2'b10 ? {32'b0, wdata_1d, 64'b0} : {wdata_1d, 96'b0};
        end else if (wr_rdy && suc_wr_req_reg) begin
            suc_wr_req_reg <= 1'b0;
        end
    end

    // ========== Dirty表时序维护 ==========
    genvar i;
    generate
        for (i = 0; i < CACHE_WAY_NUM; i = i + 1) begin : gen_DIRTY
            always @(posedge clk) begin
                if (reset) d_table[i] <= 0;
                else if (wbuf_vld && (wbuf_way == (1'b1 << i))) d_table[i][wbuf_index] <= 1'b1;
                else if ((main_st == M_REFILL) && (data_way[i]) && op_1d && access_type_1d && !is_cacop_1d) d_table[i][refill_index] <= 1'b1;
                else if ((main_st == M_REFILL) && (data_way[i]) && (!op_1d || is_cacop_1d) && access_type_1d) d_table[i][refill_index] <= 1'b0;
            end
        end
    endgenerate

    // ========== SRAM 交互(generate块) ==========
    wire                        sram_data_ena[CACHE_WAY_NUM-1:0][CACHE_LINE_BANKS-1:0];
    wire [CACHE_STRB_WIDTH-1:0] sram_data_wea[CACHE_WAY_NUM-1:0][CACHE_LINE_BANKS-1:0];

    genvar j;
    generate
        for (i = 0; i < CACHE_WAY_NUM; i = i + 1) begin : gen_SRAM_WAY
            // TAGV SRAM
            assign sram_tagv_rd[i]    = tagv_rd;
            assign sram_tagv_wr[i]    = tagv_wr & tagv_way[i];
            assign sram_tagv_index[i] = tagv_index;
            assign sram_tagv_d[i]     = tagv_d;
            blk_mem_gen_tagv u_tagv_sram (
                .clka (clk),
                .ena  (sram_tagv_rd[i] | sram_tagv_wr[i]),
                .wea  (sram_tagv_wr[i] ? 1'b1 : 1'b0),
                .addra(sram_tagv_index[i]),
                .dina (sram_tagv_d[i]),
                .douta(sram_tagv_q[i])
            );
            // DATA SRAM 多BANK
            for (j = 0; j < CACHE_LINE_BANKS; j = j + 1) begin : gen_SRAM_BANK
                assign sram_data_rd[i][j]    = data_rd;
                assign sram_data_wr[i][j]    = data_wr & (data_way[i]) && (data_offset == j);
                assign sram_data_wstrb[i][j] = data_wstrb;
                assign sram_data_index[i][j] = data_index;
                assign sram_data_d[i][j]     = data_d;
                assign sram_data_ena[i][j]   = sram_data_rd[i][j] | sram_data_wr[i][j];
                assign sram_data_wea[i][j]   = sram_data_wr[i][j] ? sram_data_wstrb[i][j] : {CACHE_STRB_WIDTH{1'b0}};
                blk_mem_gen_data u_data_sram (
                    .clka (clk),
                    .ena  (sram_data_ena[i][j]),
                    .wea  (sram_data_wea[i][j]),
                    .addra(sram_data_index[i][j]),
                    .dina (sram_data_d[i][j]),
                    .douta(sram_data_q[i][j])
                );
            end
        end
    endgenerate

    // ========= 命中判定逻辑 =========
    generate
        for (i = 0; i < CACHE_WAY_NUM; i = i + 1) begin : gen_HIT_TAG
            assign tag_sel[i]   = sram_tagv_q[i][CACHE_TAG_WIDTH:1];
            assign valid_sel[i] = sram_tagv_q[i][0];
            assign tag_hit[i]   = (tag_1d == tag_sel[i]) && valid_sel[i];
        end
    endgenerate
    assign req_hit = |tag_hit & access_type_1d;

    // ========== 主状态机 ==========
    always @(*) begin
        case (main_st)
            M_IDLE:    main_nst = (wr_op || (rd_op && !rd_conflict)) ? M_LOOKUP : M_IDLE;
            M_LOOKUP: begin
                if (is_cacop_1d) begin
                    if (cacop_is_hit_op && !req_hit) begin
                        main_nst = M_IDLE;
                    end else if (cacop_need_writeback) begin
                        main_nst = (wr_rdy) ? M_REPLACE : M_MISS;
                    end else begin
                        main_nst = M_REFILL;
                    end
                end else if (!req_hit || !access_type_1d) begin
                    main_nst = M_MISS;
                end else begin
                    main_nst = (!valid || (rd_op && rd_conflict)) ? M_IDLE : M_LOOKUP;
                end
            end
            M_MISS:    main_nst = evict_line_is_dirty || (is_cacop_1d && cacop_need_writeback) ? (wr_rdy ? M_REPLACE : M_MISS) : M_REPLACE;
            M_REPLACE: main_nst = (rd_rdy ? M_REFILL : M_REPLACE);
            M_REFILL:  main_nst = ((ret_valid && ret_last[0]) || is_cacop_1d) ? M_IDLE : M_REFILL;
            default:   main_nst = M_IDLE;
        endcase
    end
    always @(posedge clk) begin
        if (reset) main_st <= M_IDLE;
        else main_st <= main_nst;
    end

    // 命中状态机
    always @(*) begin
        case (hit_st)
            H_IDLE: begin
                if (main_st == M_LOOKUP && req_hit && op_1d && !is_cacop_1d) begin
                    hit_nst = H_WRITE;
                end else begin
                    hit_nst = H_IDLE;
                end
            end
            H_WRITE: begin
                if (main_st == M_LOOKUP && req_hit && op_1d && !is_cacop_1d) begin
                    hit_nst = H_WRITE;
                end else begin
                    hit_nst = H_IDLE;
                end
            end
            default: hit_nst = H_IDLE;
        endcase
    end
    always @(posedge clk) begin
        if (reset) hit_st <= H_IDLE;
        else hit_st <= hit_nst;
    end

    // ========== Output信号 ==========
    assign addr_ok = (main_st == M_IDLE && !wbuf_vld && !rd_conflict) ||
                     (main_st == M_LOOKUP && (main_nst == M_LOOKUP) && !is_cacop_1d);
    assign data_ok = main_st == M_LOOKUP && req_hit && !is_cacop_1d ||
                     main_st == M_LOOKUP && op_1d && !is_cacop_1d ||
                     main_st == M_REFILL && !op_1d && ret_valid &&
                    (access_type_1d ? (return_cnt == offset_1d[3:2]) : 1'b1) ||
                     main_st == M_LOOKUP && is_cacop_1d && cacop_is_hit_op && !req_hit ||
                     main_st == M_REFILL && is_cacop_1d;
    assign rdata = (main_st == M_LOOKUP && req_hit) ? local_rdata : ret_data;

endmodule
