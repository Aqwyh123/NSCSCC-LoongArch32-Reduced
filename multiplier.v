`include "macros.h"

module YDecoder (
    input  wire [2:0] y,
    output wire       sub_x,
    output wire       add_x,
    output wire       sub_2x,
    output wire       add_2x
);
    // y[2] -> i+1; y[1] -> i; y[0] -> i-1
    assign sub_x  = y[2] & y[1] & ~y[0] | y[2] & ~y[1] & y[0];
    assign add_x  = ~y[2] & ~y[1] & y[0] | ~y[2] & y[1] & ~y[0];
    assign sub_2x = y[2] & ~y[1] & ~y[0];
    assign add_2x = ~y[2] & y[1] & y[0];
endmodule

module BoothBase (
    input  wire sub_x,
    input  wire add_x,
    input  wire sub_2x,
    input  wire add_2x,
    input  wire InX,
    input  wire PosLastX,
    input  wire NegLastX,
    output wire PosNextX,
    output wire NegNextX,
    output wire OutX
);
    assign OutX     = (sub_x & ~InX) | (add_x & InX) | (sub_2x & NegLastX) | (add_2x & PosLastX);
    assign PosNextX = InX;
    assign NegNextX = ~InX;
endmodule

module BoothInterBase (
    input  wire [ 2:0] y,
    input  wire [63:0] InX,
    output wire [63:0] OutX,
    output wire        Carry
);
    wire sub_x, add_x, sub_2x, add_2x;
    wire [1:0] CarrySig[64:0];

    YDecoder ydecoder (
        .y     (y),
        .sub_x (sub_x),
        .add_x (add_x),
        .sub_2x(sub_2x),
        .add_2x(add_2x)
    );

    generate
        genvar i;
        for (i = 0; i < 64; i = i + 1) begin : gen_boothbase
            BoothBase boothbase (
                .sub_x   (sub_x),
                .add_x   (add_x),
                .sub_2x  (sub_2x),
                .add_2x  (add_2x),
                .InX     (InX[i]),
                .PosLastX(i == 0 ? 1'b0 : CarrySig[i][0]),
                .NegLastX(i == 0 ? 1'b1 : CarrySig[i][1]),
                .PosNextX(CarrySig[i+1][0]),
                .NegNextX(CarrySig[i+1][1]),
                .OutX    (OutX[i])
            );
        end
    endgenerate

    assign Carry = sub_x || sub_2x;
endmodule

module CSA (
    input  wire a,
    input  wire b,
    input  wire c,
    output wire cout,
    output wire sum
);
    assign sum  = ~a & ~b & c | ~a & b & ~c | a & ~b & ~c | a & b & c;
    assign cout = a & b | a & c | b & c;
endmodule

module WallaceTreeBase (
    input  wire [16:0] InData,
    input  wire [13:0] CIn,
    output wire [13:0] COut,
    output wire        C,
    output wire        S
);
    // first stage
    wire [4:0] FirSig;
    CSA first1 (
        .a   (InData[4]),
        .b   (InData[3]),
        .c   (InData[2]),
        .cout(COut[0]),
        .sum (FirSig[0])
    );
    CSA first2 (
        .a   (InData[7]),
        .b   (InData[6]),
        .c   (InData[5]),
        .cout(COut[1]),
        .sum (FirSig[1])
    );
    CSA first3 (
        .a   (InData[10]),
        .b   (InData[9]),
        .c   (InData[8]),
        .cout(COut[2]),
        .sum (FirSig[2])
    );
    CSA first4 (
        .a   (InData[13]),
        .b   (InData[12]),
        .c   (InData[11]),
        .cout(COut[3]),
        .sum (FirSig[3])
    );
    CSA first5 (
        .a   (InData[16]),
        .b   (InData[15]),
        .c   (InData[14]),
        .cout(COut[4]),
        .sum (FirSig[4])
    );

    // second stage
    wire [3:0] SecSig;
    CSA second1 (
        .a   (CIn[2]),
        .b   (CIn[1]),
        .c   (CIn[0]),
        .cout(COut[5]),
        .sum (SecSig[0])
    );
    CSA second2 (
        .a   (InData[0]),
        .b   (CIn[4]),
        .c   (CIn[3]),
        .cout(COut[6]),
        .sum (SecSig[1])
    );
    CSA second3 (
        .a   (FirSig[1]),
        .b   (FirSig[0]),
        .c   (InData[1]),
        .cout(COut[7]),
        .sum (SecSig[2])
    );
    CSA second4 (
        .a   (FirSig[4]),
        .b   (FirSig[3]),
        .c   (FirSig[2]),
        .cout(COut[8]),
        .sum (SecSig[3])
    );

    // third stage
    wire [1:0] ThiSig;
    CSA third1 (
        .a   (SecSig[0]),
        .b   (CIn[6]),
        .c   (CIn[5]),
        .cout(COut[9]),
        .sum (ThiSig[0])
    );
    CSA third2 (
        .a   (SecSig[3]),
        .b   (SecSig[2]),
        .c   (SecSig[1]),
        .cout(COut[10]),
        .sum (ThiSig[1])
    );

    // fourth stage
    wire [1:0] ForSig;
    CSA fourth1 (
        .a   (CIn[9]),
        .b   (CIn[8]),
        .c   (CIn[7]),
        .cout(COut[11]),
        .sum (ForSig[0])
    );
    CSA fourth2 (
        .a   (ThiSig[1]),
        .b   (ThiSig[0]),
        .c   (CIn[10]),
        .cout(COut[12]),
        .sum (ForSig[1])
    );

    // fifth stage
    wire FifSig;
    CSA fifth1 (
        .a   (ForSig[1]),
        .b   (ForSig[0]),
        .c   (CIn[11]),
        .cout(COut[13]),
        .sum (FifSig)
    );

    // sixth stage
    CSA sixth1 (
        .a   (FifSig),
        .b   (CIn[13]),
        .c   (CIn[12]),
        .cout(C),
        .sum (S)
    );
endmodule

module multiplier (
    input  wire        clk,
    input  wire        mul_unsigned,
    input  wire [31:0] factor1,
    input  wire [31:0] factor2,
    output wire [63:0] product
);
    // x 扩展至 64 位, y 扩展至 33 位, 区别有无符号
    wire [63:0] __factor1 = mul_unsigned ? {32'b0, factor1} : {{32{factor1[31]}}, factor1};
    wire [32:0] __factor2 = mul_unsigned ? {1'b0, factor2} : {factor2[31], factor2};

    // booth
    wire [16:0] Carry;  // booth 计算进位
    wire [63:0] BoothRes[16:0];  // booth 计算结果
    BoothInterBase first_boothinterbase (
        .y    ({__factor2[1], __factor2[0], 1'b0}),
        .InX  (__factor1),
        .OutX (BoothRes[0]),
        .Carry(Carry[0])
    );

    generate
        genvar i;
        for (i = 2; i < 32; i = i + 2) begin : gen_boothinterbase
            BoothInterBase boothinterbase (
                .y    (__factor2[i+1:i-1]),
                .InX  (__factor1 << i),
                .OutX (BoothRes[i>>1]),
                .Carry(Carry[i>>1])
            );
        end
    endgenerate

    BoothInterBase last_boothinterbase (
        .y    ({__factor2[32], __factor2[32], __factor2[31]}),
        .InX  (__factor1 << 32),
        .OutX (BoothRes[16]),
        .Carry(Carry[16])
    );

    reg     [16:0] SecStageCarry;
    reg     [63:0] SecStageBoothRes[16:0];

    integer        j;
    always @(posedge clk) begin
        SecStageCarry <= Carry;
        for (j = 0; j < 17; j = j + 1) begin
            SecStageBoothRes[j] <= BoothRes[j];
        end
    end

    // Wallace
    wire [13:0] WallaceInter[64:0];
    wire [63:0] COut, SOut;

    generate
        genvar k;
        for (k = 0; k < 64; k = k + 1) begin : gen_wallacetreebase
            WallaceTreeBase bi (
                .InData({
                    SecStageBoothRes[0][k],
                    SecStageBoothRes[1][k],
                    SecStageBoothRes[2][k],
                    SecStageBoothRes[3][k],
                    SecStageBoothRes[4][k],
                    SecStageBoothRes[5][k],
                    SecStageBoothRes[6][k],
                    SecStageBoothRes[7][k],
                    SecStageBoothRes[8][k],
                    SecStageBoothRes[9][k],
                    SecStageBoothRes[10][k],
                    SecStageBoothRes[11][k],
                    SecStageBoothRes[12][k],
                    SecStageBoothRes[13][k],
                    SecStageBoothRes[14][k],
                    SecStageBoothRes[15][k],
                    SecStageBoothRes[16][k]
                }),
                .CIn(k == 0 ? SecStageCarry[13:0] : WallaceInter[k]),
                .COut(WallaceInter[k+1]),
                .C(COut[k]),
                .S(SOut[k])
            );
        end
    endgenerate

    assign product = SOut + {COut[62:0], SecStageCarry[14]} + SecStageCarry[15];
endmodule
