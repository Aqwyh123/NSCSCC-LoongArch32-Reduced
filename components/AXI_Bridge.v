`include "../macros.vh"

module AXI_Bridge (
    input  wire        aclk,
    input  wire        aresetn,
    output wire        clk,
    output reg         reset,
    // inst sram slave interface
    input  wire        inst_sram_req,
    input  wire        inst_sram_wr,
    input  wire [ 1:0] inst_sram_size,
    input  wire [31:0] inst_sram_addr,
    input  wire [ 3:0] inst_sram_wstrb,
    input  wire [31:0] inst_sram_wdata,
    output wire        inst_sram_addr_ok,
    output wire        inst_sram_data_ok,
    output wire [31:0] inst_sram_rdata,
    // data sram slave interface
    input  wire        data_sram_req,
    input  wire        data_sram_wr,
    input  wire [ 1:0] data_sram_size,
    input  wire [31:0] data_sram_addr,
    input  wire [ 3:0] data_sram_wstrb,
    input  wire [31:0] data_sram_wdata,
    output wire        data_sram_addr_ok,
    output wire        data_sram_data_ok,
    output wire [31:0] data_sram_rdata,
    // read requast channel
    output reg  [ 3:0] arid,
    output reg  [31:0] araddr,
    output wire [ 7:0] arlen,              // fixed to 8'h00
    output reg  [ 2:0] arsize,
    output wire [ 1:0] arburst,            // fixed to 2'b01
    output wire [ 1:0] arlock,             // fixed to 2'b00
    output wire [ 3:0] arcache,            // fixed to 4'b0000
    output wire [ 2:0] arprot,             // fixed to 3'b000
    output reg         arvalid,
    input  wire        arready,
    // read response channel
    input  wire [ 3:0] rid,
    input  wire [31:0] rdata,
    input  wire [ 1:0] rresp,              // ignored
    input  wire        rlast,              // ignored
    input  wire        rvalid,
    output reg         rready,
    // write requast channel
    output wire [ 3:0] awid,               // fixed to 4'b0001
    output reg  [31:0] awaddr,
    output wire [ 7:0] awlen,              // fixed to 8'h00
    output reg  [ 2:0] awsize,
    output wire [ 1:0] awburst,            // fixed to 2'b01
    output wire [ 1:0] awlock,             // fixed to 2'b00
    output wire [ 3:0] awcache,            // fixed to 4'b0000
    output wire [ 2:0] awprot,             // fixed to 3'b000
    output reg         awvalid,
    input  wire        awready,
    // write data channel
    output wire [ 3:0] wid,                // fixed to 4'b0001
    output reg  [31:0] wdata,
    output reg  [ 3:0] wstrb,
    output wire        wlast,              // fixed to 1'b1
    output reg         wvalid,
    input  wire        wready,
    // write response channel
    input  wire [ 3:0] bid,                // ignored
    input  wire [ 1:0] bresp,              // ignored
    input  wire        bvalid,
    output reg         bready
);
    localparam ReadRequestIdle = 1'b0;
    localparam ReadRequestBusy = 1'b1;
    localparam WriteRequestIdle = 2'b00;
    localparam WriteRequestBusy = 2'b01;
    localparam WriteRequestWait = 2'b10;

    reg        read_request_state;
    reg  [1:0] write_request_state;

    wire       read_addr_ok;
    wire       write_addr_ok;

    assign clk = aclk;
    always @(posedge aclk) begin
        reset <= ~aresetn;
    end

    assign arlen = 8'h00;
    assign arburst = 2'b01;
    assign arlock = 2'b00;
    assign arcache = 4'b0000;
    assign arprot = 3'b000;

    assign awid = `DATA_AWID;
    assign awlen = 8'h00;
    assign awburst = 2'b01;
    assign awlock = 2'b00;
    assign awcache = 4'b0000;
    assign awprot = 3'b000;

    assign wid = `DATA_WID;
    assign wlast = 1'b1;

    assign read_addr_ok = read_request_state == ReadRequestIdle &
                         (write_request_state == WriteRequestIdle | bvalid & bready);
    assign write_addr_ok = write_request_state == WriteRequestIdle;
    assign inst_sram_addr_ok = ~data_sram_req & read_addr_ok;
    assign data_sram_addr_ok = data_sram_wr ? write_addr_ok : read_addr_ok;
    assign inst_sram_data_ok = rid == `INST_ARID & rvalid & rready;
    assign data_sram_data_ok = rid == `DATA_ARID & rvalid & rready | bvalid & bready;
    assign inst_sram_rdata = rdata;
    assign data_sram_rdata = rdata;

    always @(posedge clk) begin
        if (reset) begin
            read_request_state <= ReadRequestIdle;
            arvalid            <= 1'b0;
        end else begin
            case (read_request_state)
                ReadRequestIdle: begin
                    if (data_sram_req & ~data_sram_wr) begin
                        if (write_request_state == WriteRequestIdle | bvalid & bready) begin
                            read_request_state <= ReadRequestBusy;
                            arid               <= `DATA_ARID;
                            araddr             <= data_sram_addr;
                            arsize             <= data_sram_size;
                            arvalid            <= 1'b1;
                        end
                    end else if (inst_sram_req & ~inst_sram_wr) begin
                        if (write_request_state == WriteRequestIdle | bvalid & bready) begin
                            read_request_state <= ReadRequestBusy;
                            arid               <= `INST_ARID;
                            araddr             <= inst_sram_addr;
                            arsize             <= inst_sram_size;
                            arvalid            <= 1'b1;
                        end
                    end
                end
                ReadRequestBusy: begin
                    if (arready) begin
                        read_request_state <= ReadRequestIdle;
                        arvalid            <= 1'b0;
                    end
                end
                default: begin
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            rready <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            write_request_state <= WriteRequestIdle;
            awaddr              <= 32'h0;
            awsize              <= 2'b00;
            awvalid             <= 1'b0;
            wdata               <= 32'h0;
            wstrb               <= 4'h0;
            wvalid              <= 1'b0;
            bready              <= 1'b0;
        end else begin
            case (write_request_state)
                WriteRequestIdle: begin
                    if (data_sram_req & data_sram_wr) begin
                        write_request_state <= WriteRequestBusy;
                        awaddr              <= data_sram_addr;
                        awsize              <= data_sram_size;
                        awvalid             <= 1'b1;
                        wdata               <= data_sram_wdata;
                        wstrb               <= data_sram_wstrb;
                        wvalid              <= 1'b1;
                    end
                end
                WriteRequestBusy: begin
                    write_request_state <= awready & wready | ~awvalid & wready | ~wvalid & wready ?
                                           WriteRequestWait : WriteRequestBusy;
                    if (awready) begin
                        awvalid <= 1'b0;
                    end
                    if (wready) begin
                        wvalid <= 1'b0;
                    end
                    bready <= awready & wready | ~awvalid & wready | ~wvalid & wready;
                end
                WriteRequestWait: begin
                    if (bvalid & bready) begin
                        write_request_state <= WriteRequestIdle;
                        bready              <= 1'b0;
                    end
                end
                default: begin
                end
            endcase
        end
    end
endmodule
