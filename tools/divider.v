`include "../macros.vh"

module divider (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire        div_signed,
    input  wire [31:0] dividend,
    input  wire [31:0] divisor,
    output wire [31:0] quotient,
    output wire [31:0] remainder,
    output wire        done
);
    reg         signed_source_valid;
    wire        signed_dividend_ready;
    wire        signed_divisor_ready;
    wire        signed_result_valid;
    wire [63:0] signed_result;
    reg         unsigned_source_valid;
    wire        unsigned_dividend_ready;
    wire        unsigned_divisor_ready;
    wire        unsigned_result_valid;
    wire [63:0] unsigned_result;

    reg         busy;
    reg  [31:0] __dividend;
    reg  [31:0] __divisor;

    always @(posedge clk) begin
        if (reset) begin
            signed_source_valid   <= 1'b0;
            unsigned_source_valid <= 1'b0;
            busy                  <= 1'b0;
            __dividend            <= 32'b0;
            __divisor             <= 32'b0;
        end else if (~busy) begin
            signed_source_valid   <= start & div_signed;
            unsigned_source_valid <= start & ~div_signed;
            busy                  <= start;
            __dividend            <= dividend;
            __divisor             <= divisor;
        end else begin
            signed_source_valid   <= signed_source_valid &
                                    ~(signed_divisor_ready & signed_dividend_ready);
            unsigned_source_valid <= unsigned_source_valid &
                                    ~(unsigned_divisor_ready & unsigned_dividend_ready);
            busy <= ~done;
        end
    end

    divider_signed div_s (
        .aclk                  (clk),
        .s_axis_divisor_tvalid (signed_source_valid),
        .s_axis_divisor_tready (signed_divisor_ready),
        .s_axis_divisor_tdata  (__divisor),
        .s_axis_dividend_tvalid(signed_source_valid),
        .s_axis_dividend_tready(signed_dividend_ready),
        .s_axis_dividend_tdata (__dividend),
        .m_axis_dout_tvalid    (signed_result_valid),
        .m_axis_dout_tdata     (signed_result)
    );

    divider_unsigned div_u (
        .aclk                  (clk),
        .s_axis_divisor_tvalid (unsigned_source_valid),
        .s_axis_divisor_tready (unsigned_divisor_ready),
        .s_axis_divisor_tdata  (__divisor),
        .s_axis_dividend_tvalid(unsigned_source_valid),
        .s_axis_dividend_tready(unsigned_dividend_ready),
        .s_axis_dividend_tdata (__dividend),
        .m_axis_dout_tvalid    (unsigned_result_valid),
        .m_axis_dout_tdata     (unsigned_result)
    );

    assign quotient  = div_signed ? signed_result[63:32] : unsigned_result[63:32];
    assign remainder = div_signed ? signed_result[31:0] : unsigned_result[31:0];
    assign done      = div_signed ? signed_result_valid : unsigned_result_valid;
endmodule

