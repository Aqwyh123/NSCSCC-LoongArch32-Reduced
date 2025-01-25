`include "macros.vh"

module regfile (
    input  wire        clk,
    // READ PORT 1
    input  wire [ 4:0] read_num1,
    output wire [31:0] read_data1,
    // READ PORT 2
    input  wire [ 4:0] read_num2,
    output wire [31:0] read_data2,
    // WRITE PORT
    input  wire        write_enable,  // HIGH valid
    input  wire [ 4:0] write_num,
    input  wire [31:0] write_data
);
    reg [31:0] rf[31:0];

    always @(posedge clk) begin
        if (write_enable) rf[write_num] <= write_data;
    end

    assign read_data1 = |read_num1 ? rf[read_num1] : 32'h0;
    assign read_data2 = |read_num2 ? rf[read_num2] : 32'h0;

endmodule
