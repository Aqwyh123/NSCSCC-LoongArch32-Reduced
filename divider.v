`include "macros.h"

module divider (
    input  wire        clk,
    input  wire        reset,
    input  wire        valid,
    input  wire        ready,
    input  wire        div_unsigned,
    input  wire [31:0] dividend,
    input  wire [31:0] divisor,
    output wire [31:0] quotient,
    output wire [31:0] remainder,
    output wire        done
);
    wire [32:0] dividend_u;
    wire [32:0] divisor_u;
    reg  [32:0] quotient_u;
    reg  [32:0] remainder_u;
    reg  [ 7:0] count;

    wire [32:0] sub_result;
    wire [32:0] remainder_next;

    wire [32:0] quotient_r;
    wire [32:0] remainder_r;

    assign dividend_u = {
        1'b0, div_unsigned ? dividend : (dividend[31] ? (~dividend + 1'b1) : dividend)
    };
    assign divisor_u = {1'b0, div_unsigned ? divisor : (divisor[31] ? (~divisor + 1'b1) : divisor)};

    assign remainder_next = {remainder_u[31:0], dividend_u[count]};
    assign sub_result = remainder_next - divisor_u;

    always @(posedge clk) begin
        if (reset) begin
            count       <= 8'd32;
            quotient_u  <= 33'b0;
            remainder_u <= 33'b0;
        end else if (~valid) begin
            count       <= 8'd32;
            quotient_u  <= 33'b0;
            remainder_u <= 33'b0;
        end else if (~(count[7])) begin
            count <= count - 1'b1;
            if (sub_result[32]) begin
                quotient_u  <= {quotient_u[31:0], 1'b0};
                remainder_u <= remainder_next;
            end else begin
                quotient_u  <= {quotient_u[31:0], 1'b1};
                remainder_u <= sub_result;
            end
        end else if (ready) begin
            count       <= 8'd32;
            quotient_u  <= 33'b0;
            remainder_u <= 33'b0;
        end
    end

    assign done = count == 8'hff;

    assign quotient_r = div_unsigned ? quotient_u  : (dividend[31] == divisor[31] ?
                        quotient_u : ~(quotient_u - 1'b1));
    assign remainder_r = div_unsigned ? remainder_u : (dividend[31] ?
                       ~(remainder_u - 1'b1) : remainder_u);

    assign quotient = quotient_r[31:0];
    assign remainder = remainder_r[31:0];
endmodule
