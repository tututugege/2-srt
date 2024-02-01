// leading zero detector/counter
module lzd_4 (
    input [3:0] in,
    output [1:0] out,
    output       zero
);

    assign zero = ~(|in); 
    assign out[0] = (in[2] | ~in[1]) & ~in[3];
    assign out[1] = ~(in[3] | in[2]);

endmodule
