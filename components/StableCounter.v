`include "../macros.vh"

module StableCounter (
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] high,
    output wire [31:0] low
);
    reg [63:0] counter;

    always @(posedge clk) begin
        if (reset) begin
            counter <= 64'b0;
        end else begin
            counter <= counter + 64'd1;
        end
    end

    assign high = counter[63:32];
    assign low  = counter[31:0];
endmodule
