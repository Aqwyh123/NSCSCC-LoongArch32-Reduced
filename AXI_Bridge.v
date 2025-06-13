`include "macros.h"

module AXI_Bridge (
    input  wire aclk,
    input  wire aresetn,
    output wire clk,
    output reg  reset,

    input  wire        inst_sram_req,
    input  wire [ 2:0] inst_sram_rd_type,
    input  wire [31:0] inst_sram_addr,
    output reg         inst_sram_addr_ok,
    output wire        inst_sram_data_ok,
    output wire [31:0] inst_sram_rdata,
    output wire        inst_sram_ret_last,

    input  wire        data_sram_rd_req,
    input  wire [ 2:0] data_sram_rd_type,
    input  wire [31:0] data_sram_rd_addr,
    output reg         data_sram_rd_addr_ok,

    input  wire         data_sram_wr_req,
    input  wire [  2:0] data_sram_wr_type,
    input  wire [ 31:0] data_sram_wr_addr,
    input  wire [  3:0] data_sram_wr_wstrb,
    input  wire [127:0] data_sram_wr_data,
    output wire         data_sram_wr_addr_ok,
    output reg          data_sram_wr_resp,

    output wire        data_sram_ret_valid,
    output wire [31:0] data_sram_rdata,
    output wire        data_sram_ret_last,

    input wire inst_sram_access_type,
    input wire data_sram_access_type,

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

    input  wire [ 3:0] rid,
    input  wire [31:0] rdata,
    input  wire [ 1:0] rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,

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

    output wire [ 3:0] wid,
    output reg  [31:0] wdata,
    output reg  [ 3:0] wstrb,
    output reg         wvalid,
    output reg         wlast,
    input  wire        wready,

    input  wire [3:0] bid,
    input  wire [1:0] bresp,
    input  wire       bvalid,
    output reg        bready
);
    assign clk = aclk;
    always @(posedge aclk) reset <= ~aresetn;

    assign arburst = 2'b01;
    assign arlock  = 2'b00;
    assign arcache = 4'b0000;
    assign arprot  = 3'b000;
    assign awid    = 4'b0001;
    assign awburst = 2'b01;
    assign awlock  = 2'b00;
    assign awcache = 4'b0000;
    assign awprot  = 3'b000;
    assign wid     = 4'b0001;
    assign rready  = 1'b1;

    wire cpu_rd_req = data_sram_rd_req | inst_sram_req;
    wire rd_from_data = data_sram_rd_req;
    wire rd_from_inst = ~data_sram_rd_req & inst_sram_req;

    wire [2:0] curr_rd_type = rd_from_data ? data_sram_rd_type : inst_sram_rd_type;
    wire [31:0] curr_rd_addr = rd_from_data ? data_sram_rd_addr : inst_sram_addr;
    wire is_burst_rd = (curr_rd_type == 3'b100);

    reg write_pending;
    reg [3:0] write_id;

    wire curr_rd_access_type = rd_from_data ? data_sram_access_type : inst_sram_access_type;

    wire write_block = (write_pending && ((inst_sram_req && !inst_sram_access_type) || (data_sram_rd_req && !data_sram_access_type) || (data_sram_wr_req && !data_sram_access_type)));

    localparam WR_IDLE = 3'd0;
    localparam WR_LATCH = 3'd1;
    localparam WR_AW_WAIT = 3'd2;
    localparam WR_WDATA = 3'd3;
    localparam WR_BRESP = 3'd4;

    reg [  2:0] wr_state;
    reg [  2:0] burst_num_wr;
    reg [127:0] burst_wr_buf;
    reg [ 31:0] wr_addr_buf;
    reg [  2:0] wr_type_buf;
    reg [  3:0] wr_strb_buf;
    reg         wr_is_burst;
    reg         wr_req_buf;
    reg         wr_access_type_buf;
    reg         data_sram_wr_req_d;
    assign data_sram_wr_addr_ok = !wr_req_buf && !write_block;

    localparam RD_IDLE = 2'd0;
    localparam RD_AR_WAIT = 2'd1;
    localparam RD_RDATA = 2'd2;

    reg [ 1:0] rd_state;
    reg [ 1:0] burst_cnt_rd;

    reg        cur_rd_is_data;
    reg [ 3:0] cur_rd_id;
    reg [31:0] _cache_rdata;
    reg        cache_rvalid;
    reg        cache_rlast;

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
                    if (cpu_rd_req && !write_block) begin
                        arvalid <= 1;
                        araddr <= curr_rd_addr;
                        arlen <= (curr_rd_access_type) ? (is_burst_rd ? 8'd3 : 8'd0) : 8'd0;
                        arsize <= (curr_rd_access_type) ? 3'b010 : curr_rd_type[1:0];
                        arid <= rd_from_data ? `DATA_ARID : `INST_ARID;
                        cur_rd_is_data <= rd_from_data;
                        cur_rd_id <= rd_from_data ? `DATA_ARID : `INST_ARID;
                        rd_state <= RD_AR_WAIT;
                    end
                end
                RD_AR_WAIT: begin
                    if (arvalid && arready) begin
                        arvalid      <= 0;
                        rd_state     <= RD_RDATA;
                        burst_cnt_rd <= 0;
                        if (cur_rd_is_data) data_sram_rd_addr_ok <= 1;
                        else inst_sram_addr_ok <= 1;
                    end
                end
                RD_RDATA: begin
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

    always @(posedge clk) begin
        if (reset) begin
            _cache_rdata <= 32'b0;
        end else if (rvalid && (rid == cur_rd_id)) begin
            _cache_rdata <= rdata;
        end
        cache_rvalid <= rvalid & (rid == cur_rd_id);
        cache_rlast  <= rvalid & rlast & (rid == cur_rd_id);
    end

    wire [31:0] suc_selected_wdata = wr_addr_buf[3:2] == 2'b00 ? burst_wr_buf[31:0] :
                                     wr_addr_buf[3:2] == 2'b01 ? burst_wr_buf[63:32] :
                                     wr_addr_buf[3:2] == 2'b10 ? burst_wr_buf[95:64] :
                                     burst_wr_buf[127:96];

    always @(posedge clk) begin
        if (reset) begin
            awvalid            <= 0;
            awaddr             <= 0;
            awlen              <= 0;
            awsize             <= 0;
            wvalid             <= 0;
            wdata              <= 0;
            wstrb              <= 0;
            wlast              <= 0;
            bready             <= 0;
            burst_num_wr       <= 0;
            data_sram_wr_resp  <= 0;
            wr_state           <= WR_IDLE;
            wr_req_buf         <= 0;
            burst_wr_buf       <= 128'b0;
            wr_addr_buf        <= 32'b0;
            wr_type_buf        <= 3'b0;
            wr_strb_buf        <= 4'b0;
            wr_is_burst        <= 1'b0;
            wr_access_type_buf <= 1'b0;
            write_pending      <= 0;
            write_id           <= 0;
        end else begin
            if (bvalid && (bid == write_id)) begin
                write_pending <= 0;
            end
            data_sram_wr_resp  <= 0;
            data_sram_wr_req_d <= data_sram_wr_req;
            case (wr_state)
                WR_IDLE: begin
                    if (data_sram_wr_req && !write_block) begin
                        wr_is_burst        <= (data_sram_wr_type == 3'b100);
                        burst_wr_buf       <= data_sram_wr_data;
                        wr_addr_buf        <= data_sram_wr_addr;
                        wr_type_buf        <= data_sram_wr_type;
                        wr_strb_buf        <= data_sram_wr_wstrb;
                        wr_access_type_buf <= data_sram_access_type;
                        wr_req_buf         <= 1;
                        wr_state           <= WR_LATCH;
                    end
                end
                WR_LATCH: begin
                    awvalid  <= 1;
                    awaddr   <= wr_addr_buf;
                    awlen    <= wr_is_burst ? 8'd3 : 8'd0;
                    awsize   <= wr_is_burst ? 3'b010 : wr_type_buf;
                    wr_state <= WR_AW_WAIT;
                    if (!wr_access_type_buf) begin
                        write_pending <= 1;
                        write_id      <= 4'b0001;
                    end
                end
                WR_AW_WAIT: begin
                    if (awvalid && awready) begin
                        awvalid <= 0;
                        wvalid <= 1;
                        wdata <= wr_is_burst ? burst_wr_buf[31:0] :
                                 wr_access_type_buf ? burst_wr_buf[31:0] : suc_selected_wdata;
                        wstrb <= wr_is_burst ? 4'b1111 : wr_strb_buf;
                        if (wr_is_burst) begin
                            burst_num_wr <= 3'd3;
                            wlast        <= 1'b0;
                        end else begin
                            burst_num_wr <= 3'd0;
                            wlast        <= 1'b1;
                        end
                        wr_state <= WR_WDATA;
                    end
                end
                WR_WDATA: begin
                    if (wvalid && wready) begin
                        if (wlast) begin
                            wvalid   <= 1'b0;
                            wlast    <= 1'b0;
                            bready   <= 1;
                            wr_state <= WR_BRESP;
                        end else begin
                            wdata        <= burst_wr_buf[31:0];
                            burst_wr_buf <= {32'b0, burst_wr_buf[127:32]};
                            burst_num_wr <= burst_num_wr - 1;
                            if (burst_num_wr == 3'd1) begin
                                wlast <= 1'b1;
                            end
                        end
                    end
                end
                WR_BRESP: begin
                    if (bvalid && bready) begin
                        bready            <= 0;
                        data_sram_wr_resp <= 1;
                        wr_req_buf        <= 0;
                        wr_state          <= WR_IDLE;
                    end
                end
                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    assign data_sram_rdata     = _cache_rdata;
    assign data_sram_ret_valid = cache_rvalid & cur_rd_is_data;
    assign data_sram_ret_last  = cache_rlast & cur_rd_is_data;
    assign inst_sram_rdata     = _cache_rdata;
    assign inst_sram_data_ok   = cache_rvalid & ~cur_rd_is_data;
    assign inst_sram_ret_last  = cache_rlast & ~cur_rd_is_data;

endmodule
