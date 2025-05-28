`include "macros.h"

module IF_stage (
    input  wire                        clk,
    input  wire                        reset,
    // control signals
    input  wire [`EXCEPTION_WIDTH-1:0] exception,
    input  wire                        ereturn,
    input  wire                        refetch,
    input  wire [                31:0] eentry,
    input  wire [                31:0] rentry,
    input  wire [                31:0] eraddr,
    input  wire [                31:0] rsource,
    input  wire                        bj_taken,
    input  wire                        bj_stall,
    input  wire [                31:0] bj_target,
    // handshaking signals
    input  wire                        ID_ready,
    output wire                        IF_to_ID_valid,
    // MMU signals
    output wire                        inst_fetch,
    output wire [                31:0] inst_vaddr,
    input  wire [                31:0] inst_paddr,
    input  wire                        pre_IF_PIF,
    input  wire                        pre_IF_PPI,
    input  wire                        pre_IF_TLBR,
    // ICache interface
    output wire                        icache_req_valid,
    output wire [                31:0] icache_vaddr,
    input  wire                        icache_addr_ok,
    input  wire                        icache_data_ok,
    input  wire [                31:0] icache_rdata,
    // data signals
    output wire [                31:0] PC,
    output wire [                31:0] inst,
    output wire                        PIF,
    output wire                        PPI,
    output wire                        ADEF,
    output wire                        TLBR
);
    wire                        flush;
    wire                        bj_flush;

    wire                        pre_IF_done;
    wire                        pre_IF_to_IF_valid;
    reg                         IF_next_PC_is_PC;
    wire [                31:0] pre_IF_PC;
    wire                        pre_IF_ADEF;
    wire [`EXCEPTION_WIDTH-1:0] pre_IF_exception;

    reg                         IF_valid;
    wire                        IF_ready;
    wire                        IF_done;
    reg  [                31:0] IF_PC;
    reg                         IF_PIF;
    reg                         IF_PPI;
    reg                         IF_ADEF;
    reg                         IF_TLBR;
    wire [`EXCEPTION_WIDTH-1:0] IF_exception;

    reg                         icache_data_ok_pending;
    reg  [                31:0] icache_rdata_buffered;

    assign flush              = |exception | ereturn | refetch | bj_flush;
    assign bj_flush           = bj_taken & ~bj_stall;

    assign pre_IF_done        = (icache_req_valid & icache_addr_ok) | |pre_IF_exception;
    assign pre_IF_to_IF_valid = pre_IF_done;

    assign pre_IF_PC          = IF_next_PC_is_PC ? IF_PC : IF_PC + 32'h4;
    assign pre_IF_ADEF        = |pre_IF_PC[1:0];
    assign pre_IF_exception   = {1'b0, pre_IF_TLBR, 6'b0, pre_IF_ADEF, 1'b0, pre_IF_PPI, 1'b0, pre_IF_PIF, 3'b0};

    assign IF_ready           = ~IF_valid | (IF_done & ID_ready);
    assign IF_done            = (IF_valid & icache_data_ok) | icache_data_ok_pending | |IF_exception;
    assign IF_to_ID_valid     = IF_valid & IF_done & ~bj_flush;

    always @(posedge clk) begin
        if (reset) begin
            IF_valid         <= 1'b0;
            IF_PC            <= `PC_INIT - 32'h4;  // trick: to make next PC be 0x1c000000 during reset
            IF_next_PC_is_PC <= 1'b0;
        end else begin
            if (flush) begin
                IF_valid <= 1'b0;
            end else if (IF_ready) begin
                IF_valid <= pre_IF_to_IF_valid;
            end
            if (|exception[`EXCEPTION_IPE:`EXCEPTION_INT]) begin
                IF_PC            <= eentry;
                IF_next_PC_is_PC <= 1'b1;
            end else if (|exception[`EXCEPTION_TLBR]) begin
                IF_PC            <= rentry;
                IF_next_PC_is_PC <= 1'b1;
            end else if (ereturn) begin
                IF_PC            <= eraddr;
                IF_next_PC_is_PC <= 1'b1;
            end else if (refetch) begin
                IF_PC            <= rsource;
                IF_next_PC_is_PC <= 1'b0;
            end else if (bj_flush) begin
                IF_PC            <= bj_target;
                IF_next_PC_is_PC <= 1'b1;
            end else if (pre_IF_to_IF_valid & IF_ready) begin
                IF_PC            <= pre_IF_PC;
                IF_next_PC_is_PC <= 1'b0;
                IF_PIF           <= pre_IF_PIF;
                IF_PPI           <= pre_IF_PPI;
                IF_ADEF          <= pre_IF_ADEF;
                IF_TLBR          <= pre_IF_TLBR;
            end
        end
    end

    assign IF_exception = {1'b0, IF_TLBR, 6'b0, IF_ADEF, 1'b0, IF_PPI, 1'b0, IF_PIF, 3'b0};

    always @(posedge clk) begin
        if (reset) begin
            icache_data_ok_pending <= 1'b0;
            icache_rdata_buffered  <= 32'h0;
        end else if (flush) begin
            icache_data_ok_pending <= 1'b0;
        end else if (IF_valid & icache_data_ok & ~ID_ready & ~bj_flush) begin
            icache_data_ok_pending <= 1'b1;
            icache_rdata_buffered  <= icache_rdata;
        end else if (ID_ready | bj_flush) begin
            icache_data_ok_pending <= 1'b0;
        end
    end

    assign inst_vaddr       = pre_IF_PC;

    assign icache_vaddr     = pre_IF_PC;
    assign inst_fetch       = ~flush & ~|pre_IF_exception & (~IF_valid | IF_ready);

    assign icache_req_valid = inst_fetch;

    assign PC               = IF_PC;
    assign inst             = icache_data_ok_pending ? icache_rdata_buffered : icache_rdata;
    assign PIF              = IF_PIF;
    assign PPI              = IF_PPI;
    assign ADEF             = IF_ADEF;
    assign TLBR             = IF_TLBR;
endmodule
