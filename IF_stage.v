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
    input  wire                        pre_IF_PIF,
    input  wire                        pre_IF_PPI,
    input  wire                        pre_IF_TLBR,
    // ICache interface
    output wire                        inst_req,
    output wire [                 4:0] inst_op,
    output wire [                 2:0] inst_access_size,
    output wire [                31:0] inst_vaddr,
    output wire [                 3:0] inst_wstrb,
    output wire [                31:0] inst_wdata,
    input  wire                        inst_addr_ok,
    input  wire                        inst_data_ok,
    input  wire [                31:0] inst_rdata,
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

    reg                         inst_data_ok_pending;
    reg  [                31:0] inst_rdata_buffered;

    assign flush = |exception | ereturn | refetch | bj_flush;
    assign bj_flush = bj_taken & ~bj_stall;

    assign pre_IF_done = (inst_req & inst_addr_ok) | |pre_IF_exception;
    assign pre_IF_to_IF_valid = pre_IF_done;

    assign pre_IF_PC = IF_next_PC_is_PC ? IF_PC : IF_PC + 32'h4;
    assign pre_IF_ADEF = |pre_IF_PC[1:0];
    assign pre_IF_exception = {
        1'b0, pre_IF_TLBR, 6'b0, pre_IF_ADEF, 1'b0, pre_IF_PPI, 1'b0, pre_IF_PIF, 3'b0
    };

    assign IF_ready = ~IF_valid | (IF_done & ID_ready);
    assign IF_done = (IF_valid & inst_data_ok) | inst_data_ok_pending | |IF_exception;
    assign IF_to_ID_valid = IF_valid & IF_done & ~bj_flush;

    always @(posedge clk) begin
        if (reset) begin
            IF_valid <= 1'b0;
            IF_PC <= `PC_INIT - 32'h4;  // trick: to make next PC be 0x1c000000 during reset
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
            inst_data_ok_pending <= 1'b0;
            inst_rdata_buffered  <= 32'h0;
        end else if (flush) begin
            inst_data_ok_pending <= 1'b0;
        end else if (IF_valid & inst_data_ok & ~ID_ready & ~bj_flush) begin
            inst_data_ok_pending <= 1'b1;
            inst_rdata_buffered  <= inst_rdata;
        end else if (ID_ready | bj_flush) begin
            inst_data_ok_pending <= 1'b0;
        end
    end

    assign inst_req   = ~flush & (~IF_valid | IF_ready);
    assign inst_op    = 5'b00001;
    assign inst_access_size  = 3'b010;
    assign inst_vaddr = pre_IF_PC;
    assign inst_wstrb = 4'b0000;
    assign inst_wdata = 32'h0;

    assign PC         = IF_PC;
    assign inst       = inst_data_ok_pending ? inst_rdata_buffered : inst_rdata;
    assign PIF        = IF_PIF;
    assign PPI        = IF_PPI;
    assign ADEF       = IF_ADEF;
    assign TLBR       = IF_TLBR;
endmodule
