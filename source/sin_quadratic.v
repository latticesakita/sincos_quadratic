// ============================================================
// sincos_quad_mid.v  (Verilog-2001)
// Golden model: sin_fpga_quad_mid_fixed()
// ============================================================
module sin_quadratic
#(
)
(
    input  wire         clk,
    input  wire         resetn,
    input  wire         valid_i,

    input  wire [46:0]  phase,     // PHASE_BITS = 47

    output reg          valid_o,
    output reg  [55:0]  y_out       // Q2.54
);

    // -------------------------------------------------
    // parameters (fixed)
    // -------------------------------------------------
    localparam GRID      = 1024;
    localparam ADDR_BITS = $clog2(GRID);
    localparam FRAC_BITS = 35;
    localparam PHASE_BITS = ADDR_BITS + FRAC_BITS + 2;

    localparam LUT_BITS  = 36;
    localparam LUT_Q     = 34;

    localparam OUT_BITS  = 56;
    localparam OUT_Q     = 54;

    // -------------------------------------------------
    // phase decode (combinational)
    // -------------------------------------------------
    wire [1:0] quad = phase[PHASE_BITS-1:PHASE_BITS-2];
    wire       neg  = quad[1];
    wire [ADDR_BITS-1:0] addr = quad[0] ? ~phase[PHASE_BITS-3          :PHASE_BITS-2-ADDR_BITS]           : phase[PHASE_BITS-3          :PHASE_BITS-2-ADDR_BITS];
    wire [FRAC_BITS-1:0] frac = quad[0] ? ~phase[PHASE_BITS-3-ADDR_BITS:PHASE_BITS-2-ADDR_BITS-FRAC_BITS] : phase[PHASE_BITS-3-ADDR_BITS:PHASE_BITS-2-ADDR_BITS-FRAC_BITS];

    // -------------------------------------------------
    // LUTs (EBR), registered output, total 2 clocks
    // -------------------------------------------------
    wire [LUT_BITS-1:0] y0_r, dy_r, ddy_r;

    sin_lut_y0 lut_y0 (
        .rst_i	(~resetn),
        .rd_clk_i    (clk),
        .rd_clk_en_i (1'b1),
        .rd_en_i  (1'b1),
        .rd_addr_i   (addr),
        .rd_data_o   (y0_r)
    );

    sin_lut_dy lut_dy (
        .rst_i	(~resetn),
        .rd_clk_i    (clk),
        .rd_clk_en_i (1'b1),
        .rd_en_i  (1'b1),
        .rd_addr_i   (addr),
        .rd_data_o   (dy_r)
    );

    sin_lut_ddy lut_ddy (
        .rst_i	(~resetn),
        .rd_clk_i    (clk),
        .rd_clk_en_i (1'b1),
        .rd_en_i  (1'b1),
        .rd_addr_i   (addr),
        .rd_data_o   (ddy_r)
    );

    // -------------------------------------------------
    // pipeline stage 1,2 : LUT read, t,tt calc
    // -------------------------------------------------
    reg [FRAC_BITS:0] t1    ;
    reg [FRAC_BITS:0] t2    ;
    reg [FRAC_BITS:0] t     ; // = {1'b0, frac};
    //wire signed [FRAC_BITS:0] t_m1  = {1'b1, frac};

    // tt and tt_full are registered output from the DSP
    wire signed [2*FRAC_BITS+1:0] tt_full;
    wire [35:0] tt = tt_full[2*FRAC_BITS : 2*FRAC_BITS - 35];

    mult36x36p72 #(
        .SIGNED("SIGNED"),
	.REGINPUTA("REGISTER"), // REGISTER, BYPASS 
	.REGINPUTB("REGISTER"), // REGISTER, BYPASS 
	.REGINPUTC("REGISTER"), // REGISTER, BYPASS 
        //.REGPIPE     ("REGISTER"),// REGISTER, BYPASS
        .REGOUTPUT   ("REGISTER") // REGISTER, BYPASS
    )  mult_tt_full (
        .clk(clk),
        .resetn(resetn),
        .A({1'b0, frac}),
        .B({1'b1, frac}),
        .C(72'd0),
        .result(tt_full)
    );

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            t1 <= 0;
            t2 <= 0;
            t  <= 0;
        end else begin
            t1        <= {1'b0, frac};
            t2        <= t1;
            t         <= t1;
        end
    end

    // -------------------------------------------------
    // fixed-point math (stage 3,4)
    // -------------------------------------------------
    wire [LUT_BITS-1:0] y0_s  = y0_r;
    wire [LUT_BITS-1:0] dy_s  = dy_r;
    wire signed [LUT_BITS-1:0] ddy_s = ddy_r;

    wire signed [71:0] term1; // = dy_s  * t + y0_s;
    wire signed [71:0] term2; // = ddy_s * tt;
    mult36x36p72 #(
        .SIGNED("UNSIGNED"),
	.REGINPUTA("REGISTER"), // REGISTERED_ONCE, REGISTERED_TWICE, BYPASSED 
	.REGINPUTB("REGISTER"), // REGISTERED_ONCE, REGISTERED_TWICE, BYPASSED 
	.REGINPUTC("REGISTER"), // REGISTERED_ONCE, REGISTERED_TWICE, BYPASSED 
	//.REGPIPE("REGISTER"),
	.REGOUTPUT ("REGISTER")
    ) mult_term1 (
        .clk(clk),
        .resetn(resetn),
        .A(dy_s),
        .B(t), 
        .C({{(72-FRAC_BITS-LUT_BITS){1'b0}}, y0_s, {FRAC_BITS{1'b0}}}),
        .result(term1)
    );
    mult36x36p72 #(
        .SIGNED("SIGNED"),
	.REGINPUTA("REGISTER"), // REGISTER, BYPASS
	.REGINPUTB("REGISTER"), // REGISTER, BYPASS
	.REGINPUTC("REGISTER"), // REGISTER, BYPASS
	//.REGPIPE  ("REGISTER"),
	.REGOUTPUT ("REGISTER")
    ) mult_term2 (
        .clk(clk),
        .resetn(resetn),
        .A(ddy_s),
        .B(tt),
        .C(72'd0),
        .result(term2)
    );


    // -------------------------------------------------
    // accumulate 
    // -------------------------------------------------
    wire [71:0] acc_r = term1 + (term2 >>> 1);
    //wire [71:0] acc_shifted = (acc_r >>> (FRAC_BITS - (OUT_Q - LUT_Q)));

    // -------------------------------------------------
    // timing adjust of neg and valid
    // -------------------------------------------------
    reg [5:0] neg_r;
    reg [5:0] valid_r;
    always @(posedge clk or negedge resetn) begin
        if(!resetn) begin
            neg_r <= 0;
            valid_r <= 0;
        end
        else begin
            neg_r <= (neg_r <<< 1) | neg;
            valid_r <= (valid_r <<< 1) | valid_i;
        end
    end
    // -------------------------------------------------
    // output stage
    // -------------------------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            y_out   <= {OUT_BITS{1'b0}};
            valid_o <= 0;
        end else begin
            valid_o <= valid_r[3];
            y_out   <= neg_r  [3] ? -(acc_r >>> (FRAC_BITS - (OUT_Q - LUT_Q)))
                                  :  (acc_r >>> (FRAC_BITS - (OUT_Q - LUT_Q)));
        end
    end

endmodule

