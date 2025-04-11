`include "../macros.h"

module GPRF (
    input  wire        clk,
    // READ PORT 1
    input  wire [ 4:0] read_num1,
    output wire [31:0] read_data1,
    // READ PORT 2
    input  wire [ 4:0] read_num2,
    output wire [31:0] read_data2,
    // WRITE PORT
    input  wire        write_enable,
    input  wire [ 4:0] write_num,
    input  wire [31:0] write_data
);
    reg [31:0] regfile[31:0];

    always @(posedge clk) begin
        if (write_enable) regfile[write_num] <= write_data;
    end

    assign read_data1 = |read_num1 ? (write_enable & read_num1 == write_num ? write_data :
                         regfile[read_num1]) : 32'h0;
    assign read_data2 = |read_num2 ? (write_enable & read_num2 == write_num ? write_data :
                         regfile[read_num2]) : 32'h0;
endmodule

