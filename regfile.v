`include "macros.vh"

module regfile (
    input  wire        clk,
    // READ PORT 1
    input  wire [ 4:0] raddr1,
    output wire [31:0] rdata1,
    // READ PORT 2
    input  wire [ 4:0] raddr2,
    output wire [31:0] rdata2,
    // WRITE PORT
    input  wire        we,      //write enable, HIGH valid
    input  wire [ 4:0] waddr,
    input  wire [31:0] wdata
);
    reg [31:0] rf[31:0];

    //WRITE
    always @(posedge clk) begin
        if (we & |waddr) rf[waddr] <= wdata;
    end

    //READ OUT 1
    assign rdata1 = rf[raddr1];

    //READ OUT 2
    assign rdata2 = rf[raddr2];

endmodule
