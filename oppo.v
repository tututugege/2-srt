module oppo (
    input [31:0] in,
    input        cin,
    output [31:0] in_abs
);

    assign in_abs = ({32{cin}} ^ in) + $unsigned(cin);
    
endmodule