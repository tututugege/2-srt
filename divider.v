// 基2srt除法器

module divider (
    input div_clk,
    input resetn,
    input div,
    input div_signed,
    input [31:0] x,
    input [31:0] y,
    output [31:0] s,
    output [31:0] r,
    output complete
);
    (*MAX_FANOUT = 50*) reg [64:0] rem;
    reg [31:0] quot;
    reg [31:0] quotM;
    reg [32:0] divisor;
    reg [ 5:0] cout;
    (*MAX_FANOUT = 50*) reg [ 4:0] current_state;
    reg [ 4:0] next_state;

    reg [31:0] x_abs_reg;
    reg [31:0] y_abs_reg;

    wire [31:0] s_abs;
    wire [31:0] r_abs;
    wire s_sign;
    wire r_sign;
    wire [31:0] x_abs;
    wire [31:0] y_abs;

    oppo oppo1(x, x[31] & div_signed, x_abs);
    oppo oppo2(y, y[31] & div_signed, y_abs);

    assign s_sign = x[31] ^ y[31];
    assign r_sign = x[31];

    always @(posedge div_clk) begin
        if (~resetn) begin
            x_abs_reg <= 0;
            y_abs_reg <= 0;
        end
        else if (current_state[0] & div)
            x_abs_reg <= x_abs;
            y_abs_reg <= y_abs;
    end

    wire [31:0] lzd_in;
    wire [ 4:0] lzd_out;
    wire [ 5:0] shft_amt;
    
    wire long_shft;
    wire short_shft;
    wire [ 5:0] lzd_shamt;
    wire [ 5:0] min_shamt;

    wire quot_one;
    wire [32:0] result;  
    wire zero;
    wire [64:0] shft_src;
    wire [64:0] shft_out;

    wire [32:0] add_A;
    wire [32:0] add_B;
    wire cin;
    wire [32:0] add_out;


    wire final_shift;
    reg  [5:0] first_shft;

    always @(posedge div_clk) begin
        if (~resetn)
            first_shft <= 6'b0;
        else if (current_state[1])
            first_shft <= shft_amt;
    end

    assign final_shift = cout <= lzd_shamt;

    assign shft_src = (current_state[1]) ? {33'b0, x_abs_reg}
                                         : rem;
    assign shft_out = shft_src << shft_amt;
    assign long_shft = ~(rem[64] ^ rem[63]);
    assign short_shft = rem[64] ^ rem[63];
    assign quot_one = shft_out[64] ^ shft_out[63];
    assign lzd_shamt = {zero, {5{~zero}} & lzd_out};
    assign min_shamt  = (~final_shift) ? lzd_shamt : cout;

    assign shft_amt = {6{short_shft}} & 6'b1
                    | {6{long_shft }} & min_shamt;

    assign lzd_in = (current_state[1]) ? y_abs_reg : rem[63:32] ^ {32{rem[64]}};
    assign add_A = shft_out[64:32];
    assign add_B = {33{~rem[64]}} ^ divisor;
    assign cin   = ~rem[64];
    assign add_out = add_A + add_B + $unsigned(cin);

    assign result = (quot_one) ? add_out
                               : shft_out[64:32];

    // leading zero detector
    lzd_32 lzd(lzd_in, lzd_out, zero);

    always @(posedge div_clk) begin
        if (~resetn)
            divisor <= 33'b0;
        else if (current_state[1])
            divisor <= {1'b0, y_abs_reg << lzd_out};
    end

    always @(posedge div_clk) begin
        if (~resetn)
            rem <= 65'b0;
        else if (current_state[1])
            rem <= shft_out;
        else if (current_state[2])
            rem <= {result, rem[30:0], 1'b0};
    end

    wire [31:0] shft_quot = quot << shft_amt[4:0];
    wire [31:0] shft_quotM = ~(~quotM << shft_amt[4:0]);
    always @(posedge div_clk) begin
        if (~resetn | current_state[0]) begin
            quot  <= 32'b0;
            quotM <= 32'b0;
        end
        else if (current_state[2]) begin
            if (~shft_out[64] | shft_out[64] & shft_out[63]) 
                quot <= {shft_quot[31:1], ~shft_out[64] & shft_out[63]};
            else 
                quot <= {shft_quotM[31:1], 1'b1};

            if (~shft_out[64] & shft_out[63])
                quotM <= {shft_quot[31:1], 1'b0};
            else
                quotM <= {shft_quotM[31:1], ~(shft_out[64] & ~shft_out[63])};
        end
    end

    always @(posedge div_clk) begin
        if (~resetn | current_state[0])
            cout <= 6'b100000;
        else if (current_state[2])
            cout <= cout - shft_amt;
    end

    localparam IDLE = 5'b00001,
               INIT = 5'b00010,
               QUOT = 5'b00100,
               FIX  = 5'b01000,
               DONE = 5'b10000;

    always @(posedge div_clk) begin
        if (~resetn)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        case (current_state)
            IDLE: begin
                if (~resetn) 
                    next_state = IDLE;
                else if (div)
                    next_state = INIT;
                else
                    next_state = IDLE;
            end
            INIT: next_state = QUOT;
            QUOT: begin
                if (final_shift)
                    next_state = FIX;
                else 
                    next_state = QUOT;
            end
            FIX  :next_state = DONE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    reg [31:0] s_abs_reg;
    reg [31:0] r_abs_reg;

    assign s_abs = (rem[64]) ? quotM : quot;
    assign r_abs = ((rem[64]) ? rem[63:32] + divisor[31:0] : rem[63:32]) >> first_shft;

    always @(posedge div_clk) begin
        if (~resetn) begin
            s_abs_reg <= 0;
            r_abs_reg <= 0;
        end
        else if (current_state[3])
            s_abs_reg <= s_abs;
            r_abs_reg <= r_abs;
    end

    oppo oppo3(s_abs_reg, s_sign & div_signed, s);
    oppo oppo4(r_abs_reg, r_sign & div_signed, r);

    assign complete = current_state[4];

endmodule
