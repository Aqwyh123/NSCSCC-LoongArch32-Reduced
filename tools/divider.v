`include "../macros.vh"

module divider (
    input  wire        clk,
    input  wire        reset,
    input  wire        valid,
    input  wire        div_signed,
    input  wire [31:0] dividend,
    input  wire [31:0] divisor,
    output reg  [31:0] quotient,
    output reg  [31:0] remainder,
    output reg         done
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

    always @(posedge clk) begin
        if (reset | ~valid) begin
            signed_source_valid   <= 1'b0;
            unsigned_source_valid <= 1'b0;
            busy                  <= 1'b0;
            done                  <= 1'b0;
        end else if (~busy & ~done) begin
            signed_source_valid   <= div_signed;
            unsigned_source_valid <= ~div_signed;
            busy                  <= 1'b1;
            done                  <= 1'b0;
        end else if (~done) begin
            if (signed_source_valid) begin
                signed_source_valid <= ~(signed_divisor_ready & signed_dividend_ready);
            end
            if (unsigned_source_valid) begin
                unsigned_source_valid <= ~(unsigned_divisor_ready & unsigned_dividend_ready);
            end
            busy      <= div_signed ? ~signed_result_valid : ~unsigned_result_valid;
            done      <= div_signed ? signed_result_valid : unsigned_result_valid;
            quotient  <= div_signed ? signed_result[63:32] : unsigned_result[63:32];
            remainder <= div_signed ? signed_result[31:0] : unsigned_result[31:0];
        end else begin
            done <= 1'b0;
        end
    end

    divider_signed div_s (
        .aclk                  (clk),
        .s_axis_divisor_tvalid (signed_source_valid),
        .s_axis_divisor_tready (signed_divisor_ready),
        .s_axis_divisor_tdata  (divisor),
        .s_axis_dividend_tvalid(signed_source_valid),
        .s_axis_dividend_tready(signed_dividend_ready),
        .s_axis_dividend_tdata (dividend),
        .m_axis_dout_tvalid    (signed_result_valid),
        .m_axis_dout_tdata     (signed_result)
    );

    divider_unsigned div_u (
        .aclk                  (clk),
        .s_axis_divisor_tvalid (unsigned_source_valid),
        .s_axis_divisor_tready (unsigned_divisor_ready),
        .s_axis_divisor_tdata  (divisor),
        .s_axis_dividend_tvalid(unsigned_source_valid),
        .s_axis_dividend_tready(unsigned_dividend_ready),
        .s_axis_dividend_tdata (dividend),
        .m_axis_dout_tvalid    (unsigned_result_valid),
        .m_axis_dout_tdata     (unsigned_result)
    );
endmodule

