`include "../../macros.vh"

module IF_stage (
    input  wire        clk,
    input  wire        reset,
    // control signals
    input  wire        exception,
    input  wire        ereturn,
    input  wire [31:0] eentry,
    input  wire [31:0] eraddr,
    input  wire        bj_taken,
    input  wire        bj_stall,
    input  wire [31:0] bj_target,
    // handshaking signals
    input  wire        ID_ready,
    output wire        IF_to_ID_valid,
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
    output wire [31:0] PC,
    output wire [31:0] link,
    output wire [31:0] inst,
    output wire        ADEF
);
    wire        flush;
    wire        bj_flush;
    wire        bj_enable;

    wire        pre_IF_done;
    wire        pre_IF_to_IF_valid;
    reg         pre_IF_PC_is_IF_PC;
    wire [31:0] pre_IF_PC;
    wire        pre_IF_ADEF;

    reg         IF_valid;
    wire        IF_ready;
    wire        IF_done;
    reg  [31:0] IF_PC;
    wire        IF_ADEF;
    wire [31:0] IF_seq_PC;

    reg         inst_sram_data_ok_valid;
    reg         inst_sram_data_ok_temp;
    reg  [31:0] inst_sram_rdata_temp;

    assign flush              = exception | ereturn | bj_flush;
    assign bj_enable          = bj_taken & ~bj_stall;
    assign bj_flush           = bj_enable & bj_target != IF_PC;

    assign pre_IF_done        = inst_sram_req & inst_sram_addr_ok | pre_IF_ADEF;
    assign pre_IF_to_IF_valid = pre_IF_done;

    always @(posedge clk) begin
        if (reset) begin
            pre_IF_PC_is_IF_PC <= 1'b0;
        end else if (flush & ~(pre_IF_to_IF_valid & IF_ready)) begin
            pre_IF_PC_is_IF_PC <= 1'b1;
        end else if (pre_IF_to_IF_valid & IF_ready) begin
            pre_IF_PC_is_IF_PC <= 1'b0;
        end
    end

    assign pre_IF_PC = exception ? eentry :
                       ereturn ? eraddr :
                       bj_enable ? bj_target :
                       pre_IF_PC_is_IF_PC ? IF_PC :
                       IF_seq_PC;
    assign pre_IF_ADEF = |pre_IF_PC[1:0];

    assign IF_ready = ~IF_valid | (IF_done & ID_ready);
    assign IF_done = inst_sram_data_ok_valid & inst_sram_data_ok | inst_sram_data_ok_temp | IF_ADEF;
    assign IF_to_ID_valid = IF_valid & IF_done & ~bj_flush;

    always @(posedge clk) begin
        if (reset) begin
            IF_valid <= 1'b0;
            IF_PC    <= `PC_INIT - 3'h4;  // trick: to make next PC be 0x1c000000 during reset
        end else begin
            if (IF_ready) begin
                IF_valid <= pre_IF_to_IF_valid;
            end else if (flush) begin
                IF_valid <= 1'b0;
            end
            if (exception) begin
                IF_PC <= eentry;
            end else if (ereturn) begin
                IF_PC <= eraddr;
            end else if (bj_enable) begin
                IF_PC <= bj_target;
            end else if (pre_IF_to_IF_valid & IF_ready) begin
                IF_PC <= pre_IF_PC_is_IF_PC ? IF_PC : IF_seq_PC;
            end
        end
    end

    assign IF_ADEF   = |IF_PC[1:0];
    assign IF_seq_PC = IF_PC + 3'h4;

    always @(posedge clk) begin
        if (reset) begin
            inst_sram_data_ok_valid <= 1'b1;
        end else if (flush & IF_valid & ~IF_done) begin
            inst_sram_data_ok_valid <= 1'b0;
        end else if (~flush & inst_sram_data_ok) begin
            inst_sram_data_ok_valid <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            inst_sram_data_ok_temp <= 1'b0;
            inst_sram_rdata_temp   <= 32'h0;
        end else if (flush) begin
            inst_sram_data_ok_temp <= 1'b0;
        end else if (inst_sram_data_ok_valid & inst_sram_data_ok & ~ID_ready) begin
            inst_sram_data_ok_temp <= 1'b1;
            inst_sram_rdata_temp   <= inst_sram_rdata;
        end else if (ID_ready) begin
            inst_sram_data_ok_temp <= 1'b0;
        end
    end

    assign inst_sram_req   = ~bj_stall & ~pre_IF_ADEF & IF_ready;
    assign inst_sram_wr    = 1'b0;
    assign inst_sram_size  = 2'b10;
    assign inst_sram_addr  = pre_IF_PC;
    assign inst_sram_wstrb = 4'b0000;
    assign inst_sram_wdata = 32'h0;

    assign PC              = IF_PC;
    assign link            = IF_seq_PC;
    assign inst            = inst_sram_data_ok_temp ? inst_sram_rdata_temp : inst_sram_rdata;
    assign ADEF            = IF_ADEF;
endmodule
