`include "../macros.vh"

module CSRF (
    input  wire                         clk,
    input  wire                         reset,
    // data signals
    input  wire [`CSR_NUMBER_WIDTH-1:0] number,
    input  wire                         write_enable,
    input  wire [                 31:0] write_mask,
    input  wire [                 31:0] write_data,
    output wire [                 31:0] read_data,
    // control signals
    input  wire [                  7:0] hw_int,
    input  wire                         ip_int,
    input  wire [ `EXCEPTION_WIDTH-1:0] exception,
    input  wire                         __return,
    input  wire [                 31:0] PC,
    input  wire [                 31:0] vaddr,
    output wire                         interupt,
    output wire                         enter,
    output wire [                 31:0] entry,
    output wire [                 31:0] raddr
);

    reg [31:0] CRMD;
    reg [31:0] PRMD;
    reg [31:0] ECFG;
    reg [31:0] ESTAT;
    reg [31:0] ERA;
    reg [31:0] BADV;
    reg [31:0] EENTRY;
    reg [31:0] SAVE[3:0];
    reg [31:0] TID;
    reg [31:0] TCFG;
    reg [31:0] TVAL;
    wire [31:0] TICLR;

    wire [12:0] ECFG_LIE = {ECFG[`CSR_ECFG_LIE_12_11], ECFG[`CSR_ECFG_LIE_9_0]};
    wire [12:0] ESTAT_IS = {ESTAT[12:11], ESTAT[9:0]};

    wire [`ECODE_WIDTH-1:0] ecode;
    wire [`ESUBCODE_WIDTH-1:0] esubcode;

    assign ecode    = exception[`EXCEPTION_INT] ? `ECODE_INT :
                      exception[`EXCEPTION_ADEF] ? `ECODE_ADEF :
                      exception[`EXCEPTION_SYS] ? `ECODE_SYS  :
                      exception[`EXCEPTION_BRK] ? `ECODE_BRK  :
                      exception[`EXCEPTION_INE] ? `ECODE_INE  :
                      exception[`EXCEPTION_ALE] ? `ECODE_ALE  : `ECODE_WIDTH'b0;
    assign esubcode = {8'b0, exception[`EXCEPTION_ADEM]};

    assign enter = |exception;

    always @(posedge clk) begin
        if (reset) begin
            CRMD[`CSR_CRMD_PLV]  <= 2'b0;
            CRMD[`CSR_CRMD_IE]   <= 1'b0;
            CRMD[`CSR_CRMD_DA]   <= 1'b1;  // not implemented
            CRMD[`CSR_CRMD_PG]   <= 1'b0;  // not implemented
            CRMD[`CSR_CRMD_DATF] <= 2'b0;  // not implemented
            CRMD[`CSR_CRMD_DATM] <= 2'b0;  // not implemented
        end else if (enter) begin
            CRMD[`CSR_CRMD_PLV] <= 2'b0;
            CRMD[`CSR_CRMD_IE]  <= 1'b0;
        end else if (__return) begin
            CRMD[`CSR_CRMD_PLV] <= PRMD[`CSR_PRMD_PPLV];
            CRMD[`CSR_CRMD_IE]  <= PRMD[`CSR_PRMD_PIE];
        end else if (write_enable & number == `CSR_CRMD) begin
            CRMD[`CSR_CRMD_PLV] <= write_mask[`CSR_CRMD_PLV] & write_data[`CSR_CRMD_PLV] |
                                  ~write_mask[`CSR_CRMD_PLV] & CRMD[`CSR_CRMD_PLV];
            CRMD[`CSR_CRMD_IE]  <= write_mask[`CSR_CRMD_IE] & write_data[`CSR_CRMD_IE]  |
                                  ~write_mask[`CSR_CRMD_IE] & CRMD[`CSR_CRMD_IE];
        end
        CRMD[`CSR_CRMD_0] <= `CSR_CRMD_0_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (enter) begin
            PRMD[`CSR_PRMD_PPLV] <= CRMD[`CSR_CRMD_PLV];
            PRMD[`CSR_PRMD_PIE]  <= CRMD[`CSR_CRMD_IE];
        end else if (write_enable & number == `CSR_PRMD) begin
            PRMD[`CSR_PRMD_PPLV] <= write_mask[`CSR_PRMD_PPLV] & write_data[`CSR_PRMD_PPLV] |
                                   ~write_mask[`CSR_PRMD_PPLV] & PRMD[`CSR_PRMD_PPLV];
            PRMD[`CSR_PRMD_PIE] <= write_mask[`CSR_PRMD_PIE] & write_data[`CSR_PRMD_PIE] |
                                  ~write_mask[`CSR_PRMD_PIE] & PRMD[`CSR_PRMD_PIE];
        end
        PRMD[`CSR_PRMD_0] <= `CSR_PRMD_0_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (reset) begin
            ECFG[`CSR_ECFG_LIE_9_0]   <= 10'b0;
            ECFG[`CSR_ECFG_LIE_12_11] <= 2'b0;
        end else if (write_enable & number == `CSR_ECFG) begin
            ECFG[12:0] <= write_mask[12:0] & 13'h1bff & write_data[12:0] |
                         ~write_mask[12:0] & 13'h1bff & ECFG[12:0];
        end
        ECFG[`CSR_ECFG_0_LOW]  <= `CSR_ECFG_0_LOW_WIDTH'b0;
        ECFG[`CSR_ECFG_0_HIGH] <= `CSR_ECFG_0_HIGH_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (reset) begin
            ESTAT[`CSR_ESTAT_IS_1_0] <= 2'b0;
        end else if (write_enable & number == `CSR_ESTAT) begin
            ESTAT[`CSR_ESTAT_IS_1_0] <= write_mask[`CSR_ESTAT_IS_1_0] &
                                        write_data[`CSR_ESTAT_IS_1_0] |
                                       ~write_mask[`CSR_ESTAT_IS_1_0] &
                                        ESTAT[`CSR_ESTAT_IS_1_0];
        end
        ESTAT[`CSR_ESTAT_IS_9_2] <= hw_int;
        if (TCFG[`CSR_TCFG_EN] & ~|TVAL[`CSR_TVAL_TVAL]) begin
            ESTAT[`CSR_ESTAT_IS_11] <= 1'b1;
        end
        else if (write_enable & number == `CSR_TICLR &
                 write_mask[`CSR_TICLR_CLR] & write_data[`CSR_TICLR_CLR]) begin
            ESTAT[`CSR_ESTAT_IS_11] <= 1'b0;
        end
        ESTAT[`CSR_ESTAT_IS_12] <= ip_int;
        if (enter) begin
            ESTAT[`CSR_ESTAT_ECODE]    <= ecode;
            ESTAT[`CSR_ESTAT_ESUBCODE] <= esubcode;
        end
        ESTAT[`CSR_ESTAT_0_LOW]  <= `CSR_ESTAT_0_LOW_WIDTH'b0;
        ESTAT[`CSR_ESTAT_0_MID]  <= `CSR_ESTAT_0_MID_WIDTH'b0;
        ESTAT[`CSR_ESTAT_0_HIGH] <= `CSR_ESTAT_0_HIGH_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (enter) begin
            ERA[`CSR_ERA_PC] <= PC;
        end else if (write_enable & number == `CSR_ERA) begin
            ERA[`CSR_ERA_PC] <= write_mask[`CSR_ERA_PC] & write_data[`CSR_ERA_PC] |
                               ~write_mask[`CSR_ERA_PC] & ERA[`CSR_ERA_PC];
        end
    end

    always @(posedge clk) begin
        if (exception[`EXCEPTION_ADEF] | exception[`EXCEPTION_ALE]) begin
            BADV[`CSR_BADV_VADDR] <= exception[`EXCEPTION_ADEF] ? PC : vaddr;
        end
    end

    always @(posedge clk) begin
        if (write_enable & number == `CSR_EENTRY) begin
            EENTRY[`CSR_EENTRY_VA] <= write_mask[`CSR_EENTRY_VA] & write_data[`CSR_EENTRY_VA] |
                                     ~write_mask[`CSR_EENTRY_VA] & EENTRY[`CSR_EENTRY_VA];
        end
        EENTRY[`CSR_EENTRY_0] <= `CSR_EENTRY_0_WIDTH'b0;
    end

    always @(posedge clk) begin
        if (write_enable & number == `CSR_SAVE0) begin
            SAVE[0][`CSR_SAVE_DATA] <= write_mask[`CSR_SAVE_DATA] & write_data[`CSR_SAVE_DATA] |
                                      ~write_mask[`CSR_SAVE_DATA] & SAVE[0][`CSR_SAVE_DATA];
        end
        if (write_enable & number == `CSR_SAVE1) begin
            SAVE[1][`CSR_SAVE_DATA] <= write_mask[`CSR_SAVE_DATA] & write_data[`CSR_SAVE_DATA] |
                                      ~write_mask[`CSR_SAVE_DATA] & SAVE[1][`CSR_SAVE_DATA];
        end
        if (write_enable & number == `CSR_SAVE2) begin
            SAVE[2][`CSR_SAVE_DATA] <= write_mask[`CSR_SAVE_DATA] & write_data[`CSR_SAVE_DATA] |
                                      ~write_mask[`CSR_SAVE_DATA] & SAVE[2][`CSR_SAVE_DATA];
        end
        if (write_enable & number == `CSR_SAVE3) begin
            SAVE[3][`CSR_SAVE_DATA] <= write_mask[`CSR_SAVE_DATA] & write_data[`CSR_SAVE_DATA] |
                                      ~write_mask[`CSR_SAVE_DATA] & SAVE[3][`CSR_SAVE_DATA];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            TID[`CSR_TID_TID] <= {22'b0, `COREID};
        end else if (write_enable & number == `CSR_TID) begin
            TID[`CSR_TID_TID] <= write_mask[`CSR_TID_TID] & write_data[`CSR_TID_TID] |
                                ~write_mask[`CSR_TID_TID] & TID[`CSR_TID_TID];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            TCFG[`CSR_TCFG_EN] <= 1'b0;
        end else if (write_enable & number == `CSR_TCFG) begin
            TCFG[`CSR_TCFG_EN] <= write_mask[`CSR_TCFG_EN] & write_data[`CSR_TCFG_EN] |
                                 ~write_mask[`CSR_TCFG_EN] & TCFG[`CSR_TCFG_EN];
        end
        if (write_enable & number == `CSR_TCFG) begin
            TCFG[`CSR_TCFG_PERIODIC] <= write_mask[`CSR_TCFG_PERIODIC] &
                                        write_data[`CSR_TCFG_PERIODIC] |
                                       ~write_mask[`CSR_TCFG_PERIODIC] &
                                        TCFG[`CSR_TCFG_PERIODIC];
            TCFG[`CSR_TCFG_INITVAL] <= write_mask[`CSR_TCFG_INITVAL] &
                                       write_data[`CSR_TCFG_INITVAL] |
                                      ~write_mask[`CSR_TCFG_INITVAL] &
                                       TCFG[`CSR_TCFG_INITVAL];
        end
    end

    assign TICLR = 32'b0;

    wire [31:0] TVAL_TVAL_next = write_mask[31:0] & write_data[31:0] |
                                ~write_mask[31:0] & {TCFG[`CSR_TCFG_INITVAL],
                                TCFG[`CSR_TCFG_PERIODIC],TCFG[`CSR_TCFG_EN]};
    always @(posedge clk) begin
        if (reset) begin
            TVAL[`CSR_TVAL_TVAL] <= `CSR_TVAL_TVAL_INIT;
        end else if (write_enable & number == `CSR_TCFG && TVAL_TVAL_next[`CSR_TCFG_EN]) begin
            TVAL[`CSR_TVAL_TVAL] <= {TVAL_TVAL_next[`CSR_TCFG_INITVAL], 2'b0};
        end else if (TCFG[`CSR_TCFG_EN] & ~&TVAL[`CSR_TVAL_TVAL]) begin
            if (~|TVAL[`CSR_TVAL_TVAL] & TCFG[`CSR_TCFG_PERIODIC]) begin
                TVAL[`CSR_TVAL_TVAL] <= {TCFG[`CSR_TCFG_INITVAL], 2'b0};
            end else begin
                TVAL[`CSR_TVAL_TVAL] <= TVAL[`CSR_TVAL_TVAL] - 32'd1;
            end
        end
    end

    assign read_data = {32{number == `CSR_CRMD}} & CRMD |
                       {32{number == `CSR_PRMD}} & PRMD |
                       {32{number == `CSR_ECFG}} & ECFG |
                       {32{number == `CSR_ESTAT}} & ESTAT |
                       {32{number == `CSR_ERA}} & ERA |
                       {32{number == `CSR_BADV}} & BADV |
                       {32{number == `CSR_EENTRY}} & EENTRY |
                       {32{number == `CSR_SAVE0}} & SAVE[0] |
                       {32{number == `CSR_SAVE1}} & SAVE[1] |
                       {32{number == `CSR_SAVE2}} & SAVE[2] |
                       {32{number == `CSR_SAVE3}} & SAVE[3] |
                       {32{number == `CSR_TID}} & TID |
                       {32{number == `CSR_TCFG}} & TCFG |
                       {32{number == `CSR_TVAL}} & TVAL |
                       {32{number == `CSR_TICLR}} & TICLR;

    assign interupt = |(ESTAT_IS & ECFG_LIE) & CRMD[`CSR_CRMD_IE];

    assign entry = EENTRY;
    assign raddr = ERA;
endmodule
