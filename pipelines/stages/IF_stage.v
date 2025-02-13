`include "../../macros.vh"

module IF_stage (
    input  wire        clk,
    input  wire        reset,
    // control signals
    input  wire        flush,
    input  wire        IF_valid,
    input  wire        IF_ready,
    input  wire        ID_ready,
    // handshaking signals
    output wire        pre_IF_to_IF_valid,
    output wire        IF_done,
    // SRAM-like Bus
    output wire        inst_sram_req,
    output wire        inst_sram_wr,
    output wire [ 1:0] inst_sram_size,
    output wire [31:0] inst_sram_addr,
    output wire [ 3:0] inst_sram_wstrb,
    output wire [31:0] inst_sram_wdata,
    input  wire        inst_sram_addr_ok,
    input  wire        inst_sram_data_ok,
    input  wire [31:0] inst_sram_rdata,
    // data signals
    input  wire [31:0] PC,
    output wire [31:0] pre_IF_PC,
    output wire [31:0] inst,
    output wire        ADEF
);
    wire        inst_sram_req_valid;
    reg         inst_sram_data_ok_valid;
    reg         inst_sram_temp_ok;
    reg  [31:0] inst_temp;

    adder #(
        .ADDEND1_WIDTH(32),
        .ADDEND2_WIDTH(3),
        .CARRY        (0)
    ) pre_IF_PC_adder (
        .addend1(PC),
        .addend2(3'h4),
        .sum    (pre_IF_PC)
    );

    assign inst_sram_req_valid = IF_ready & ~flush & ~|pre_IF_PC[1:0];

    assign inst_sram_req       = ~reset & inst_sram_req_valid;
    assign inst_sram_wr        = 1'b0;
    assign inst_sram_size      = 2'b10;
    assign inst_sram_addr      = pre_IF_PC;
    assign inst_sram_wstrb     = 4'b0000;
    assign inst_sram_wdata     = 32'h0;

    assign pre_IF_to_IF_valid  = inst_sram_req_valid & inst_sram_addr_ok | |pre_IF_PC[1:0];

    always @(posedge clk) begin
        if (reset) begin
            inst_sram_data_ok_valid <= 1'b1;
        end else if (flush & IF_valid & ~ADEF & ~inst_sram_data_ok & ~inst_sram_temp_ok) begin
            inst_sram_data_ok_valid <= 1'b0;
        end else if (~flush & inst_sram_data_ok) begin
            inst_sram_data_ok_valid <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            inst_sram_temp_ok <= 1'b0;
        end else if (flush) begin
            inst_sram_temp_ok <= 1'b0;
        end else if (inst_sram_data_ok_valid & inst_sram_data_ok & ~ID_ready) begin
            inst_sram_temp_ok <= 1'b1;
            inst_temp         <= inst_sram_rdata;
        end else if (ID_ready) begin
            inst_sram_temp_ok <= 1'b0;
        end
    end

    assign inst    = inst_sram_temp_ok ? inst_temp : inst_sram_rdata;

    assign IF_done = inst_sram_data_ok_valid & inst_sram_data_ok | inst_sram_temp_ok | ADEF;

    assign ADEF    = |PC[1:0];
endmodule
