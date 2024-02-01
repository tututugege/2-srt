// 32-bit leading zero counter
// Reference: https://digitalsystemdesign.in/leading-zero-counter/
module lzd_32 (
    input [31:0] in,
    output [4:0] out,
    output       zero
);
    wire [1:0] z;
    wire [3:0] out_3_0 [1:0];
    lzd_16 lzd_16_0(in[31:16], out_3_0[0], z[0]);
    lzd_16 lzd_16_1(in[15: 0], out_3_0[1], z[1]);

    assign out[4] = z[0];
    assign out[3:0] = {4{~z[0]}} & out_3_0[0] |
                      {4{ z[0]}} & out_3_0[1];
    assign zero = z[0] & z[1];

endmodule
