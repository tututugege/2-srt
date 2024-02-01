module lzd_16 (
    input [15:0] in,
    output [3:0] out,
    output       zero
);

    wire [3:0] z;
    wire [1:0] out_2 [3:0];

    lzd_4 lzd_4_0(in[15:12], out_2[0], z[0]);
    lzd_4 lzd_4_1(in[11: 8], out_2[1], z[1]);
    lzd_4 lzd_4_2(in[ 7: 4], out_2[2], z[2]);
    lzd_4 lzd_4_3(in[ 3: 0], out_2[3], z[3]);

    assign out[2] = z[0] & (~z[1] | z[2] & ~z[3]);
    assign out[3] = z[0] & z[1] & (~z[2] | ~z[3]);
    assign out[1:0] = {2{~out[3] & ~out[2]}} & out_2[0]
                    | {2{~out[3] &  out[2]}} & out_2[1]
                    | {2{ out[3] & ~out[2]}} & out_2[2]
                    | {2{ out[3] &  out[2]}} & out_2[3];
    assign zero = &z;

endmodule
