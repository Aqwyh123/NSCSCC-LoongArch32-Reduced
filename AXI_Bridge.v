`include "macros.h"

// 支持burst的AXI Bridge（含cache接口，verilog-2005）

module AXI_Bridge (
    input  wire aclk,
    input  wire aresetn,
    output wire clk,
    output reg  reset,

    // ICache接口（仅读，带type用于判断burst）
    input  wire        inst_sram_req,
    input  wire [ 2:0] inst_sram_rd_type,  // 3'b100: burst line; 其他: 单次
    input  wire [31:0] inst_sram_addr,
    output reg         inst_sram_addr_ok,
    output wire        inst_sram_data_ok,
    output wire [31:0] inst_sram_rdata,
    output wire        inst_sram_ret_last, // burst最后一拍标志

    // DCache接口（可读写，带type用于判断burst）
    input  wire        data_sram_rd_req,     // dcache读请求
    input  wire [ 2:0] data_sram_rd_type,
    input  wire [31:0] data_sram_rd_addr,
    output reg         data_sram_rd_addr_ok,

    input  wire         data_sram_wr_req,      // dcache写请求
    input  wire [  2:0] data_sram_wr_type,
    input  wire [ 31:0] data_sram_wr_addr,
    input  wire [  3:0] data_sram_wr_wstrb,
    input  wire [127:0] data_sram_wr_data,     // 支持128位burst数据
    output reg          data_sram_wr_addr_ok,
    output reg          data_sram_wr_resp,     // bvalid for write ok

    output wire        data_sram_ret_valid,  // dcache读返回有效
    output wire [31:0] data_sram_rdata,      // dcache读返回数据
    output wire        data_sram_ret_last,   // dcache burst读最后一拍

    // AXI读地址通道
    output reg  [ 3:0] arid,
    output reg  [31:0] araddr,
    output reg  [ 7:0] arlen,
    output reg  [ 2:0] arsize,
    output wire [ 1:0] arburst,
    output wire [ 1:0] arlock,
    output wire [ 3:0] arcache,
    output wire [ 2:0] arprot,
    output reg         arvalid,
    input  wire        arready,
    // AXI读数据通道
    input  wire [ 3:0] rid,
    input  wire [31:0] rdata,
    input  wire [ 1:0] rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,
    // AXI写地址通道
    output wire [ 3:0] awid,
    output reg  [31:0] awaddr,
    output reg  [ 7:0] awlen,
    output reg  [ 2:0] awsize,
    output wire [ 1:0] awburst,
    output wire [ 1:0] awlock,
    output wire [ 3:0] awcache,
    output wire [ 2:0] awprot,
    output reg         awvalid,
    input  wire        awready,
    // AXI写数据通道
    output wire [ 3:0] wid,
    output reg  [31:0] wdata,
    output reg  [ 3:0] wstrb,
    output reg         wvalid,
    output reg         wlast,
    input  wire        wready,
    // AXI写响应通道
    input  wire [ 3:0] bid,
    input  wire [ 1:0] bresp,
    input  wire        bvalid,
    output reg         bready
);
    assign clk = aclk;
    always @(posedge aclk) reset <= ~aresetn;

    // AXI固定信号
    assign arburst = 2'b01;
    assign arlock  = 2'b00;
    assign arcache = 4'b0000;
    assign arprot  = 3'b000;
    assign awid    = 4'b0001;  // data  写id
    assign awburst = 2'b01;
    assign awlock  = 2'b00;
    assign awcache = 4'b0000;
    assign awprot  = 3'b000;
    assign wid     = 4'b0001;  // AXI4不再用wid，本接口兼容AXI3
    assign rready  = 1'b1;  // always ready，因dcache/cache流控已处理

    // --------------- 仲裁: D优先再I ---------------
    wire        cpu_rd_req = data_sram_rd_req | inst_sram_req;
    wire        rd_from_data = data_sram_rd_req;
    wire        rd_from_inst = ~data_sram_rd_req & inst_sram_req;

    wire [ 2:0] curr_rd_type = rd_from_data ? data_sram_rd_type : inst_sram_rd_type;
    wire [31:0] curr_rd_addr = rd_from_data ? data_sram_rd_addr : inst_sram_addr;
    wire        is_burst_rd = (curr_rd_type == 3'b100);

    // --------------- 读通道状态机 ---------------
    localparam RD_IDLE = 2'd0;
    localparam RD_AR_WAIT = 2'd1;
    localparam RD_RDATA = 2'd2;

    reg [ 1:0] rd_state;
    reg [ 1:0] burst_cnt_rd;  // 0~3，管控burst n拍

    reg        cur_rd_is_data;  // 当前burst以及数据输出属于哪个cache
    reg [ 3:0] cur_rd_id;  // AXI区分读ID（防出错）
    reg [31:0] _cache_rdata;
    reg        cache_rvalid;
    reg        cache_rlast;

    // addr_ok发出策略：burst在arvalid和arready握手后立刻给（只发一次）
    always @(posedge clk) begin
        if (reset) begin
            arvalid              <= 0;
            araddr               <= 0;
            arlen                <= 0;
            arsize               <= 0;
            arid                 <= 0;
            inst_sram_addr_ok    <= 0;
            data_sram_rd_addr_ok <= 0;
            rd_state             <= RD_IDLE;
            cur_rd_is_data       <= 1'b0;
            cur_rd_id            <= 4'b0;
            burst_cnt_rd         <= 2'b0;
        end else begin
            inst_sram_addr_ok    <= 0;
            data_sram_rd_addr_ok <= 0;
            case (rd_state)
                RD_IDLE: begin
                    // 优先data，再inst
                    if (cpu_rd_req) begin
                        // 发AR
                        arvalid        <= 1;
                        araddr         <= curr_rd_addr;
                        arlen          <= is_burst_rd ? 8'd3 : 8'd0;
                        arsize         <= 3'b010;  // always 32-bit
                        arid           <= rd_from_data ? `DATA_ARID : `INST_ARID;
                        cur_rd_is_data <= rd_from_data;
                        cur_rd_id      <= rd_from_data ? `DATA_ARID : `INST_ARID;
                        rd_state       <= RD_AR_WAIT;
                    end
                end
                RD_AR_WAIT: begin
                    if (arvalid && arready) begin
                        arvalid      <= 0;
                        rd_state     <= RD_RDATA;
                        burst_cnt_rd <= 0;
                        // 发addr_ok，只发一次
                        if (cur_rd_is_data) data_sram_rd_addr_ok <= 1;
                        else inst_sram_addr_ok <= 1;
                    end
                end
                RD_RDATA: begin
                    // 进入读数据流，直到rlast为止，_cache_rvalid/_cache_rlast由下方同步产生
                    if (rvalid) begin
                        if (rlast) begin
                            rd_state <= RD_IDLE;
                        end
                    end
                end
                default: rd_state <= RD_IDLE;
            endcase
        end
    end

    // 供cache的数据输出/ret_last/valid，期间识别是谁发起
    always @(posedge clk) begin
        if (rvalid && (rid == cur_rd_id)) begin
            _cache_rdata <= rdata;
        end
        cache_rvalid <= rvalid & (rid == cur_rd_id);
        cache_rlast  <= rvalid & rlast & (rid == cur_rd_id);
    end

    // --------------- 写通道状态机（支持burst write-back） ---------------
    localparam WR_IDLE = 3'd0;
    localparam WR_LATCH = 3'd1;
    localparam WR_AW_WAIT = 3'd2;
    localparam WR_WDATA = 3'd3;
    localparam WR_BRESP = 3'd4;

    reg [  2:0] wr_state;
    reg [  1:0] burst_cnt_wr;  // 0~3, for burst
    reg [127:0] burst_wr_buf;  // 用于写回整行
    reg [ 31:0] wr_addr_buf;
    reg [  2:0] wr_type_buf;
    reg [  3:0] wr_strb_buf;
    reg         wr_is_burst;
    reg         wr_req_buf;  // 正在处理某次请求
    reg         data_sram_wr_req_d;  // 处理写握手用

    // wr_data_ok 只有收到B响应才拉高
    always @(posedge clk) begin
        if (reset) begin
            awvalid              <= 0;
            awaddr               <= 0;
            awlen                <= 0;
            awsize               <= 0;
            wvalid               <= 0;
            wdata                <= 0;
            wstrb                <= 0;
            wlast                <= 0;
            bready               <= 0;
            burst_cnt_wr         <= 0;
            data_sram_wr_addr_ok <= 1'b1;
            data_sram_wr_resp    <= 0;
            wr_state             <= WR_IDLE;
            wr_req_buf           <= 0;
            burst_wr_buf         <= 128'b0;
            wr_addr_buf          <= 32'b0;
            wr_type_buf          <= 3'b0;
            wr_strb_buf          <= 4'b0;
            wr_is_burst          <= 1'b0;
        end else begin
            data_sram_wr_addr_ok <= !wr_req_buf;
            data_sram_wr_resp    <= 0;
            data_sram_wr_req_d   <= data_sram_wr_req;
            case (wr_state)
                WR_IDLE: begin
                    if (data_sram_wr_req) begin
                        // latch所有缓存接口的相关内容
                        wr_is_burst  <= (data_sram_wr_type == 3'b100);
                        burst_wr_buf <= data_sram_wr_data;
                        wr_addr_buf  <= data_sram_wr_addr;
                        wr_type_buf  <= data_sram_wr_type;
                        wr_strb_buf  <= data_sram_wr_wstrb;
                        wr_req_buf   <= 1;
                        wr_state     <= WR_LATCH;
                    end
                end
                WR_LATCH: begin
                    // 完全锁存准备就绪，准备发地址
                    awvalid              <= 1;
                    awaddr               <= wr_addr_buf;
                    awlen                <= wr_is_burst ? 8'd3 : 8'd0;  // burst4 or single
                    awsize               <= 3'b010;
                    // 数据通道初始化
                    burst_cnt_wr         <= 0;
                    wr_state             <= WR_AW_WAIT;
                end
                WR_AW_WAIT: begin
                    if (awvalid && awready) begin
                        awvalid  <= 0;
                        wvalid   <= 1;
                        // 真 burst 写
                        wdata    <= burst_wr_buf[31:0];
                        wstrb    <= wr_is_burst ? 4'b1111 : wr_strb_buf;
                        wlast    <= wr_is_burst ? 0 : 1;
                        wr_state <= WR_WDATA;
                    end
                end
                WR_WDATA: begin
                    if (wvalid && wready) begin
                        if (wr_is_burst) begin
                            burst_cnt_wr <= burst_cnt_wr + 1;
                            if (burst_cnt_wr == 2'd2) begin
                                // 下一拍将是最后一拍
                                wdata  <= burst_wr_buf[127:96];
                                wvalid <= 1;
                                wstrb  <= 4'b1111;
                                wlast  <= 1;
                            end else if (burst_cnt_wr == 2'd3) begin
                                // 最后一个beat
                                wvalid       <= 0;
                                wlast        <= 0;
                                wr_state     <= WR_BRESP;
                                burst_cnt_wr <= 0;
                            end else begin
                                // next beat
                                case (burst_cnt_wr)
                                    2'd0:    wdata <= burst_wr_buf[63:32];
                                    2'd1:    wdata <= burst_wr_buf[95:64];
                                    default: ;
                                endcase
                                wvalid <= 1;
                                wstrb  <= 4'b1111;
                                wlast  <= 0;
                            end
                        end else begin
                            // 单字写结束
                            wvalid   <= 0;
                            wlast    <= 0;
                            wr_state <= WR_BRESP;
                        end
                    end
                end
                WR_BRESP: begin
                    bready <= 1;
                    if (bvalid) begin
                        bready            <= 0;
                        // 表示本次bursted写完成，通知cache
                        data_sram_wr_resp <= 1;
                        wr_req_buf        <= 0;
                        wr_state          <= WR_IDLE;
                    end
                end
                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // ----------- cache输出信号分流 -------------
    // 读通道（分给icache和dcache），各自以id区分
    assign data_sram_rdata     = _cache_rdata;
    assign data_sram_ret_valid = cache_rvalid & cur_rd_is_data;
    assign data_sram_ret_last  = cache_rlast & cur_rd_is_data;
    assign inst_sram_rdata     = _cache_rdata;
    assign inst_sram_data_ok   = cache_rvalid & ~cur_rd_is_data;
    assign inst_sram_ret_last  = cache_rlast & ~cur_rd_is_data;

endmodule
