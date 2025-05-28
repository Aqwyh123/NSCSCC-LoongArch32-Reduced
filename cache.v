`include "macros.h"

module cache (
    input  wire                           clk,
    input  wire                           resetn,
    // CPU接口
    input  wire                           valid,
    input  wire                           op,
    input  wire [ `CACHE_INDEX_WIDTH-1:0] index,
    input  wire [   `CACHE_TAG_WIDTH-1:0] tag,
    input  wire [`CACHE_OFFSET_WIDTH-1:0] offset,
    input  wire [  `CACHE_STRB_WIDTH-1:0] wstrb,
    input  wire [  `CACHE_DATA_WIDTH-1:0] wdata,
    output wire                           addr_ok,
    output wire                           data_ok,
    output wire [  `CACHE_DATA_WIDTH-1:0] rdata,
    // AXI-like Mem接口
    output wire                           rd_req,
    output wire [                    2:0] rd_type,
    output wire [                   31:0] rd_addr,
    input  wire                           rd_rdy,
    input  wire                           ret_valid,
    input  wire [                    1:0] ret_last,
    input  wire [                   31:0] ret_data,
    output wire                           wr_req,
    output wire [                    2:0] wr_type,
    output wire [                   31:0] wr_addr,
    output wire [                    3:0] wr_wstrb,
    output wire [                  127:0] wr_data,
    input  wire                           wr_rdy
);

    localparam CACHE_AW = `CACHE_AW;
    localparam CACHE_DATA_NUM = `CACHE_DATA_NUM;
    localparam CACHE_WAY_NUM = `CACHE_WAY_NUM;
    localparam CACHE_LINE_BANKS = `CACHE_LINE_BANKS;
    localparam CACHE_TAG_WIDTH = `CACHE_TAG_WIDTH;
    localparam CACHE_INDEX_WIDTH = `CACHE_INDEX_WIDTH;
    localparam CACHE_OFFSET_WIDTH = `CACHE_OFFSET_WIDTH;
    localparam CACHE_DATA_WIDTH = `CACHE_DATA_WIDTH;
    localparam CACHE_STRB_WIDTH = `CACHE_STRB_WIDTH;

    // ========== 状态机定义 ==========
    localparam M_IDLE = 3'd0;
    localparam M_LOOKUP = 3'd1;
    localparam M_MISS = 3'd2;
    localparam M_REPLACE = 3'd3;
    localparam M_REFILL = 3'd4;
    localparam H_IDLE = 1'b0;
    localparam H_WRITE = 1'b1;

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
    reg                           dirty_flag;

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
    reg  [                  68:0] request_buf;
    wire                          req_buf_up_en;
    wire                          op_1d;
    wire [ CACHE_INDEX_WIDTH-1:0] index_1d;
    wire [   CACHE_TAG_WIDTH-1:0] tag_1d;
    wire [CACHE_OFFSET_WIDTH-1:0] offset_1d;
    wire [  CACHE_STRB_WIDTH-1:0] wstrb_1d;
    wire [  CACHE_DATA_WIDTH-1:0] wdata_1d;
    reg  [  CACHE_DATA_WIDTH-1:0] local_rdata;

    // 读出请求Buffer分配
    assign op_1d     = request_buf[68];
    assign index_1d  = request_buf[67:60];
    assign tag_1d    = request_buf[59:40];
    assign offset_1d = request_buf[39:36];
    assign wstrb_1d  = request_buf[35:32];
    assign wdata_1d  = request_buf[31:0];

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
    reg  [  CACHE_DATA_NUM-1:0] d_table        [CACHE_WAY_NUM-1:0];

    // 伪随机替换
    reg                         rand_data;

    // ------ SRAM读写信号 ------
    wire [CACHE_DATA_WIDTH-1:0] sram_data_q    [CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];
    wire                        sram_data_rd   [CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];
    wire                        sram_data_wr   [CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];
    wire [CACHE_STRB_WIDTH-1:0] sram_data_wstrb[CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];
    wire [        CACHE_AW-1:0] sram_data_index[CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];
    wire [CACHE_DATA_WIDTH-1:0] sram_data_d    [CACHE_WAY_NUM-1:0] [CACHE_LINE_BANKS-1:0];

    wire [   CACHE_TAG_WIDTH:0] sram_tagv_q    [CACHE_WAY_NUM-1:0];
    wire                        sram_tagv_rd   [CACHE_WAY_NUM-1:0];
    wire                        sram_tagv_wr   [CACHE_WAY_NUM-1:0];
    wire [        CACHE_AW-1:0] sram_tagv_index[CACHE_WAY_NUM-1:0];
    wire [   CACHE_TAG_WIDTH:0] sram_tagv_d    [CACHE_WAY_NUM-1:0];

    // ===== 命中相关信号 =====
    wire [ CACHE_TAG_WIDTH-1:0] tag_sel        [CACHE_WAY_NUM-1:0];
    wire [   CACHE_WAY_NUM-1:0] valid_sel;
    wire [   CACHE_WAY_NUM-1:0] tag_hit;
    wire                        req_hit;

    // 状态机控制
    assign wr_op           = valid & op;
    assign rd_op           = valid & !op;
    assign rdreq_lookup_rd = (main_nst == M_LOOKUP) && rd_op;
    assign lookup_rd       = (main_nst == M_LOOKUP);
    assign hitwrite_wr     = wbuf_vld;

    // 替换相关信号
    assign replace_rd      = (main_nst == M_REPLACE) && (main_st == M_MISS);
    assign replace_index   = index_1d;
    assign replace_tag     = sram_tagv_q[replace_way][CACHE_TAG_WIDTH:1];

    // refill信号
    wire                         refill_wr;
    wire [CACHE_INDEX_WIDTH-1:0] refill_index;
    wire [  CACHE_TAG_WIDTH-1:0] refill_tag;
    wire [                  1:0] refill_bank;
    wire [ CACHE_STRB_WIDTH-1:0] refill_wstrb;
    wire [ CACHE_DATA_WIDTH-1:0] refill_data;
    wire [    CACHE_WAY_NUM-1:0] refill_way;

    assign refill_wr     = ret_valid;
    assign refill_index  = replace_index;
    assign refill_tag    = tag_1d;
    assign refill_bank   = return_cnt;
    assign refill_wstrb  = wstrb_1d;
    assign refill_data   = (op_1d && (refill_bank == offset_1d[3:2])) ? wdata_1d : ret_data;
    assign refill_way    = (replace_way) ? {{(CACHE_WAY_NUM - 1) {1'b0}}, 1'b1} : {1'b1, {(CACHE_WAY_NUM - 1) {1'b0}}};

    // tagv信号
    assign tagv_rd       = lookup_rd | replace_rd;
    assign tagv_wr       = refill_wr;
    assign tagv_index    = lookup_rd ? index : replace_rd ? replace_index : refill_index;
    assign tagv_way      = lookup_rd ? {CACHE_WAY_NUM{1'b1}} : replace_rd ? (1'b1 << replace_way) : refill_way;
    assign tagv_d        = {tag_1d, 1'b1};

    // data信号
    assign data_rd       = rdreq_lookup_rd | replace_rd;
    assign data_wr       = refill_wr | hitwrite_wr;
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
        if (!resetn) request_buf <= 69'b0;
        else if (req_buf_up_en) request_buf <= {op, index, tag, offset, wstrb, wdata};
    end

    // 写命中buffer逻辑
    always @(posedge clk) begin
        if (hit_nst == H_WRITE) write_buf <= {wdata_1d, index_1d, offset_1d, wstrb_1d, tag_hit};
    end

    always @(posedge clk) begin
        if (!resetn) wbuf_vld <= 1'b0;
        else if (hit_nst == H_WRITE) wbuf_vld <= 1'b1;
        else if (hit_nst == H_IDLE) wbuf_vld <= 1'b0;
    end

    // 随机替换
    always @(posedge clk) begin
        if (!resetn) rand_data <= 1'b0;
        else rand_data <= $random;
    end

    // miss/replace/dirty记录
    always @(posedge clk) begin
        if (!resetn) replace_way <= 1'b0;
        else if ((main_st == M_LOOKUP) && (main_nst == M_MISS)) begin
            replace_way <= rand_data;
            dirty_flag  <= d_table[rand_data][index_1d];
        end
    end

    // refill计数
    always @(posedge clk) begin
        if (!resetn) return_cnt <= 0;
        else if (ret_valid && ret_last[0]) return_cnt <= 0;
        else if (ret_valid && !ret_last[0]) return_cnt <= return_cnt + 1'b1;
    end

    // 写回及读出AXI接口相关
    reg [                127:0] wr_data_reg;
    reg [                 31:0] wr_addr_reg;
    reg [                  2:0] wr_type_reg;
    reg [                  3:0] wr_wstrb_reg;
    reg                         wr_req_reg;

    reg [  CACHE_TAG_WIDTH-1:0] replace_tag_reg;
    reg [CACHE_INDEX_WIDTH-1:0] replace_index_reg;
    reg [                127:0] replace_data_reg;
    reg                         replace_tagval_vld;

    always @(posedge clk) begin
        if (!resetn) begin
            replace_tag_reg    <= 0;
            replace_index_reg  <= 0;
            replace_data_reg   <= 0;
            replace_tagval_vld <= 1'b0;
        end else begin
            // M_MISS进入M_MISS的那个周期采样
            if ((main_st == M_MISS) && (main_nst == M_MISS)) begin
                replace_tag_reg    <= sram_tagv_q[rand_data][CACHE_TAG_WIDTH:1];
                replace_index_reg  <= index_1d;
                replace_data_reg   <= {sram_data_q[rand_data][3], sram_data_q[rand_data][2], sram_data_q[rand_data][1], sram_data_q[rand_data][0]};
                replace_tagval_vld <= 1'b1;
            end else begin
                replace_tagval_vld <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (!resetn) wr_req_reg <= 1'b0;
        else if ((main_st == M_MISS) && (main_nst == M_REPLACE)) begin
            wr_data_reg  <= replace_data_reg;
            wr_addr_reg  <= {replace_tag_reg, replace_index_reg, 4'b0};
            wr_type_reg  <= 3'b100;
            wr_wstrb_reg <= 4'b1111;
            wr_req_reg   <= 1'b1;
        end else if (wr_rdy && wr_req_reg) begin
            wr_req_reg <= 1'b0;
        end
    end

    assign wr_req   = wr_req_reg;
    assign wr_data  = wr_data_reg;
    assign wr_addr  = wr_addr_reg;
    assign wr_type  = wr_type_reg;
    assign wr_wstrb = wr_wstrb_reg;

    // refill读AXI信号
    assign rd_addr  = {refill_tag, refill_index, 4'b0};
    assign rd_type  = 3'b100;

    reg rd_req_r;
    always @(posedge clk) begin
        if (!resetn) rd_req_r <= 1'b0;
        else if ((main_st == M_MISS) && (!dirty_flag)) rd_req_r <= 1'b1;
        else if (main_st == M_REPLACE) rd_req_r <= 1'b1;
        else rd_req_r <= 1'b0;
    end
    assign rd_req = rd_req_r;

    // ========== Dirty表时序维护 ==========
    genvar i;
    generate
        for (i = 0; i < CACHE_WAY_NUM; i = i + 1) begin : DIRTY
            always @(posedge clk) begin
                if (!resetn) d_table[i] <= 0;
                else if (wbuf_vld && (wbuf_way == (1'b1 << i))) d_table[i][wbuf_index] <= 1'b1;
                else if ((main_st == M_REFILL) && (replace_way == i) && op_1d) d_table[i][refill_index] <= 1'b1;
                else if ((main_st == M_REFILL) && (replace_way == i) && !op_1d) d_table[i][refill_index] <= 1'b0;
            end
        end
    endgenerate

    // ========== SRAM 交互(generate块) ==========
    genvar j;
    generate
        for (i = 0; i < CACHE_WAY_NUM; i = i + 1) begin : SRAM_WAY
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
            for (j = 0; j < CACHE_LINE_BANKS; j = j + 1) begin : SRAM_BANK
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

    wire                        sram_data_ena[CACHE_WAY_NUM-1:0][CACHE_LINE_BANKS-1:0];
    wire [CACHE_STRB_WIDTH-1:0] sram_data_wea[CACHE_WAY_NUM-1:0][CACHE_LINE_BANKS-1:0];

    // ========= 命中判定逻辑 =========
    generate
        for (i = 0; i < CACHE_WAY_NUM; i = i + 1) begin : HIT_TAG
            assign tag_sel[i]   = sram_tagv_q[i][CACHE_TAG_WIDTH:1];
            assign valid_sel[i] = sram_tagv_q[i][0];
            assign tag_hit[i]   = (tag_1d == tag_sel[i]) && valid_sel[i];
        end
    endgenerate
    assign req_hit = |tag_hit;

    // ========== 主状态机 ==========
    always @(*) begin
        case (main_st)
            M_IDLE:    main_nst = (wr_op || (rd_op && !rd_conflict)) ? M_LOOKUP : M_IDLE;
            M_LOOKUP:  main_nst = (!req_hit) ? M_MISS : (!valid || (rd_op && rd_conflict)) ? M_IDLE : M_LOOKUP;
            M_MISS:    main_nst = (!dirty_flag) ? (rd_rdy ? M_REFILL : M_MISS) : (wr_rdy ? M_REPLACE : M_MISS);
            M_REPLACE: main_nst = (rd_rdy ? M_REFILL : M_REPLACE);
            M_REFILL:  main_nst = ((ret_valid && ret_last[0]) ? M_IDLE : M_REFILL);
            default:   main_nst = M_IDLE;
        endcase
    end
    always @(posedge clk) begin
        if (!resetn) main_st <= M_IDLE;
        else main_st <= main_nst;
    end

    // 命中状态机
    always @(*) begin
        case (hit_st)
            H_IDLE:  hit_nst = (main_st == M_LOOKUP && req_hit && op_1d) ? H_WRITE : H_IDLE;
            H_WRITE: hit_nst = (main_st == M_LOOKUP && req_hit && op_1d) ? H_WRITE : H_IDLE;
        endcase
    end
    always @(posedge clk) begin
        if (!resetn) hit_st <= H_IDLE;
        else hit_st <= hit_nst;
    end

    // ========== Output信号 ==========
    assign addr_ok = ((main_st == M_IDLE) && !wbuf_vld && !rd_conflict) || ((main_st == M_LOOKUP) && (main_nst == M_LOOKUP));

    assign data_ok = (main_st == M_LOOKUP && req_hit) || (main_st == M_LOOKUP && op_1d) || (main_st == M_REFILL && !op_1d && ret_valid && (return_cnt == offset_1d[3:2]));

    assign rdata   = (main_st == M_LOOKUP && req_hit) ? local_rdata : ret_data;

endmodule
