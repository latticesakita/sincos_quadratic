// =============================================================================
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// -----------------------------------------------------------------------------
//   Copyright (c) 2017 by Lattice Semiconductor Corporation
//   ALL RIGHTS RESERVED 
// -----------------------------------------------------------------------------
//
//   Permission:
//
//      Lattice SG Pte. Ltd. grants permission to use this code
//      pursuant to the terms of the Lattice Reference Design License Agreement. 
//
//
//   Disclaimer:
//
//      This VHDL or Verilog source code is intended as a design reference
//      which illustrates how these types of functions can be implemented.
//      It is the user's responsibility to verify their design for
//      consistency and functionality through the use of formal
//      verification methods.  Lattice provides no warranty
//      regarding the use or functionality of this code.
//
// -----------------------------------------------------------------------------
//
//                  Lattice SG Pte. Ltd.
//                  101 Thomson Road, United Square #07-02 
//                  Singapore 307591
//
//
//                  TEL: 1-800-Lattice (USA and Canada)
//                       +65-6631-2000 (Singapore)
//                       +1-503-268-8001 (other locations)
//
//                  web: http://www.latticesemi.com/
//                  email: techsupport@latticesemi.com
//
// -----------------------------------------------------------------------------

module mult36x36p72
#(
	parameter ASIGNED = "SIGNED",
	parameter BSIGNED = "SIGNED",
	parameter CSIGNED = "SIGNED",
	parameter REGINPUTA	=	"BYPASSED", // REGISTERED_ONCE, REGISTERED_TWICE, BYPASSED 
	parameter REGINPUTB	=	"BYPASSED", // REGISTERED_ONCE, REGISTERED_TWICE, BYPASSED 
	parameter REGINPUTC	=	"BYPASSED", // REGISTERED_ONCE, REGISTERED_TWICE, BYPASSED 
	parameter REGPIPE	=	"BYPASSED", // REGISTERED, BYPASSED
	parameter REGOUTPUT	=	"BYPASSED", // REGISTERED, BYPASSED
	parameter REGOUTPUT2	=	"BYPASSED"  // REGISTERED, BYPASSED
)
(
	input wire clk,
	input wire resetn,
	input wire signed [35:0] A,
	input wire signed [35:0] B,
	input wire signed [71:0] C,
	output reg signed [72:0] result
);

wire signed [47:0] result_m0;
wire signed [47:0] result_m1;
wire signed [47:0] result_m2;
wire signed [47:0] result_m3;
wire [72:0] c_int;

assign c_int = (CSIGNED == "SIGNED") ? {C[71],C[71:0]} : {1'b0, C[71:0]};

wire [37:0] result_add0; // upper bits of m0+m3, shifted 36bits
wire [37:0] result_add1; //       bits of m1+m2
wire [54:0] result_add2; // upper bits of add0+add2, shifted 18bits

addr38 add0 (
	.data_a_re_i({37'b0,result_m0[36]}),
	.data_b_re_i({result_m3[36],result_m3[36: 0]}),
	.result_re_o(result_add0[37:0])
);
addr38 add1 (
	.data_a_re_i({result_m1[36],result_m1[36: 0]}),
	.data_b_re_i({result_m2[36],result_m2[36: 0]}),
	.result_re_o(result_add1[37:0])
);
addr55 add2 (
	.data_a_re_i({{18{result_add1[37]}},result_add1[36:0]}),
	.data_b_re_i({result_add0[36:0],result_m0[35:18]}),
	.result_re_o(result_add2[54:0])
);
generate if(REGOUTPUT2 == "BYPASSED") begin
	always @(*)
	begin
		result[17: 0] = result_m0  [17:0];
		result[72:18] = result_add2[54:0];
	end
end else begin
	always @(posedge clk or negedge resetn) begin
		if(!resetn) begin
			result[72: 0] <= 73'b0;
		end
		else begin
			result[17: 0] <= result_m0  [17:0];
			result[72:18] <= result_add2[54:0];
		end
	end
end
endgenerate



	MULTADDSUB18X18A #(
		.ASIGNED		("UNSIGNED"),
		.BSIGNED		("UNSIGNED"),
		.REGINPUTA		(REGINPUTA),
		.REGINPUTB		(REGINPUTB),
		.REGINPUTC		(REGINPUTC),
		.REGSHIFTOUTA		("BYPASSED"),
		.REGSHIFTOUTB		("BYPASSED"),
		.REGSHIFTOUTC		("BYPASSED"),
		.SHIFTINPUTA		("DISABLED"),
		.SHIFTINPUTB		("DISABLED"),
		.SHIFTINPUTC		("DISABLED"),
		.REGPREPIPE		("BYPASSED"),
		.REGPIPE		(REGPIPE),
		.REGOUTPUT		(REGOUTPUT),
		.REGCAS_ZOUT		("BYPASSED"),
		.REGACCUMCONTROLS	("BYPASSED"),
		.RESETMODE		("ASYNC"),
		.ACCUM_EN		("ENABLED"), // ("DISABLED"),
		.CAS_ZOUT_RSHIFT	("DISABLED"),
		.PREADD_EN		("DISABLED"),
		.REGADDSUBPRE		("BYPASSED"),
		.ACCUM_C_EN		("ENABLED"), // ("DISABLED"),
		.CAS_ZIN_EN		("DISABLED"),// ("ENABLED")
		.CAS_CIN_EN		("DISABLED"),
		.ROUNDMODE		("ROUND_TO_ZERO"),
		.SATURATION		("DISABLED"),
		.SATURATION_BITS	("48"),
		.GSR			("ENABLED")

	) mult_m0 (
		.A			(A[17:0]),
		.B			(B[17:0]),
		.C			({30'b0,c_int[17:0]}),
		.CLK			(clk),
		.RST			(~resetn),
		.CEA1			(1'b1),
		.CEA2			(1'b1),
		.CEB1			(1'b1),
		.CEB2			(1'b1),
		.CEOUTPIPE		(1'b1),
		.CEC1			(1'b1),
		.CEC2			(1'b1),
		.ASHIFTIN		(18'd0),
		.BSHIFTIN		(18'd0),
		.CSHIFTIN		(18'd0),
		.CIN			(1'b0),
		.CAS_ZIN		(48'd0), // *****
		.CAS_CIN		(1'b0),
		.SELC_N			(1'b0),
		.SELCAS_ZIN_N		(1'b0),
		.SELCARRY		(1'b0),
		.ADDSUBPRE		(1'b0),
		.ADDSUBACCUM		(1'b0),
		.ASHIFTOUT		(),
		.BSHIFTOUT		(),
		.CSHIFTOUT		(),
		.ZOUT			(result_m0),
		.COUT			(),
		.OVERFLOW		(),
		.CAS_ZOUT		(), // 18bits shifted
		.CAS_COUT		()
	);
	MULTADDSUB18X18A #(
		.ASIGNED		(ASIGNED),
		.BSIGNED		("UNSIGNED"),
		.REGINPUTA		(REGINPUTA),
		.REGINPUTB		(REGINPUTB),
		.REGINPUTC		(REGINPUTC),
		.REGSHIFTOUTA		("BYPASSED"),
		.REGSHIFTOUTB		("BYPASSED"),
		.REGSHIFTOUTC		("BYPASSED"),
		.SHIFTINPUTA		("DISABLED"),
		.SHIFTINPUTB		("DISABLED"),
		.SHIFTINPUTC		("DISABLED"),
		.REGPREPIPE		("BYPASSED"),
		.REGPIPE		(REGPIPE),
		.REGOUTPUT		(REGOUTPUT),
		.REGCAS_ZOUT		("BYPASSED"),
		.REGACCUMCONTROLS	("BYPASSED"),
		.RESETMODE		("ASYNC"),
		.ACCUM_EN		("ENABLED"), // ("DISABLED"),
		.CAS_ZOUT_RSHIFT	("DISABLED"), // ("DISABLED"),
		.PREADD_EN		("DISABLED"),
		.REGADDSUBPRE		("BYPASSED"),
		.ACCUM_C_EN		("ENABLED"), // ("DISABLED"),
		.CAS_ZIN_EN		("DISABLED"),// ("ENABLED")
		.CAS_CIN_EN		("DISABLED"),
		.ROUNDMODE		("ROUND_TO_ZERO"),
		.SATURATION		("DISABLED"),
		.SATURATION_BITS	("48"),
		.GSR			("ENABLED")

	) mult_m1 (
		.A			(A[35:18]),
		.B			(B[17: 0]),
		.C			(48'd0),
		.CLK			(clk),
		.RST			(~resetn),
		.CEA1			(1'b1),
		.CEA2			(1'b1),
		.CEB1			(1'b1),
		.CEB2			(1'b1),
		.CEOUTPIPE		(1'b1),
		.CEC1			(1'b1),
		.CEC2			(1'b1),
		.ASHIFTIN		(18'd0),
		.BSHIFTIN		(18'd0),
		.CSHIFTIN		(18'd0),
		.CIN			(1'b0),
		.CAS_ZIN		(48'd0), // *****
		.CAS_CIN		(1'b0),
		.SELC_N			(1'b0),
		.SELCAS_ZIN_N		(1'b0),
		.SELCARRY		(1'b0),
		.ADDSUBPRE		(1'b0),
		.ADDSUBACCUM		(1'b0),
		.ASHIFTOUT		(),
		.BSHIFTOUT		(),
		.CSHIFTOUT		(),
		.ZOUT			(result_m1),
		.COUT			(),
		.OVERFLOW		(),
		.CAS_ZOUT		(), // No Shift
		.CAS_COUT		()
	);
	MULTADDSUB18X18A #(
		.ASIGNED		("UNSIGNED"),
		.BSIGNED		(BSIGNED),
		.REGINPUTA		(REGINPUTA),
		.REGINPUTB		(REGINPUTB),
		.REGINPUTC		(REGINPUTC),
		.REGSHIFTOUTA		("BYPASSED"),
		.REGSHIFTOUTB		("BYPASSED"),
		.REGSHIFTOUTC		("BYPASSED"),
		.SHIFTINPUTA		("DISABLED"),
		.SHIFTINPUTB		("DISABLED"),
		.SHIFTINPUTC		("DISABLED"),
		.REGPREPIPE		("BYPASSED"),
		.REGPIPE		(REGPIPE),
		.REGOUTPUT		(REGOUTPUT),
		.REGCAS_ZOUT		("BYPASSED"),
		.REGACCUMCONTROLS	("BYPASSED"),
		.RESETMODE		("ASYNC"),
		.ACCUM_EN		("ENABLED"), // ("DISABLED"),
		.CAS_ZOUT_RSHIFT	("DISABLED"),
		.PREADD_EN		("DISABLED"),
		.REGADDSUBPRE		("BYPASSED"),
		.ACCUM_C_EN		("ENABLED"), // ("DISABLED"),
		.CAS_ZIN_EN		("DISABLED"),// ("ENABLED")
		.CAS_CIN_EN		("DISABLED"),
		.ROUNDMODE		("ROUND_TO_ZERO"),
		.SATURATION		("DISABLED"),
		.SATURATION_BITS	("48"),
		.GSR			("ENABLED")

	) mult_m2 (
		.A			(A[17: 0]),
		.B			(B[35:18]),
		.C			({30'b0,c_int[35:18]}),
		.CLK			(clk),
		.RST			(~resetn),
		.CEA1			(1'b1),
		.CEA2			(1'b1),
		.CEB1			(1'b1),
		.CEB2			(1'b1),
		.CEOUTPIPE		(1'b1),
		.CEC1			(1'b1),
		.CEC2			(1'b1),
		.ASHIFTIN		(18'd0),
		.BSHIFTIN		(18'd0),
		.CSHIFTIN		(18'd0),
		.CIN			(1'b0),
		.CAS_ZIN		(48'd0), // *****
		.CAS_CIN		(1'b0),
		.SELC_N			(1'b0),
		.SELCAS_ZIN_N		(1'b0),
		.SELCARRY		(1'b0),
		.ADDSUBPRE		(1'b0),
		.ADDSUBACCUM		(1'b0),
		.ASHIFTOUT		(),
		.BSHIFTOUT		(),
		.CSHIFTOUT		(),
		.ZOUT			(result_m2), // *****
		.COUT			(),
		.OVERFLOW		(),
		.CAS_ZOUT		(), // 18bits shifted
		.CAS_COUT		()
	);
	MULTADDSUB18X18A #(
		.ASIGNED		(ASIGNED),
		.BSIGNED		(BSIGNED),
		.REGINPUTA		(REGINPUTA),
		.REGINPUTB		(REGINPUTB),
		.REGINPUTC		(REGINPUTC),
		.REGSHIFTOUTA		("BYPASSED"),
		.REGSHIFTOUTB		("BYPASSED"),
		.REGSHIFTOUTC		("BYPASSED"),
		.SHIFTINPUTA		("DISABLED"),
		.SHIFTINPUTB		("DISABLED"),
		.SHIFTINPUTC		("DISABLED"),
		.REGPREPIPE		("BYPASSED"),
		.REGPIPE		(REGPIPE),
		.REGOUTPUT		(REGOUTPUT),
		.REGCAS_ZOUT		("BYPASSED"),
		.REGACCUMCONTROLS	("BYPASSED"),
		.RESETMODE		("ASYNC"),
		.ACCUM_EN		("ENABLED"), // ("DISABLED"),
		.CAS_ZOUT_RSHIFT	("DISABLED"),
		.PREADD_EN		("DISABLED"),
		.REGADDSUBPRE		("BYPASSED"),
		.ACCUM_C_EN		("ENABLED"), // ("DISABLED"),
		.CAS_ZIN_EN		("DISABLED"),// ("ENABLED")
		.CAS_CIN_EN		("DISABLED"),
		.ROUNDMODE		("ROUND_TO_ZERO"),
		.SATURATION		("DISABLED"),
		.SATURATION_BITS	("48"),
		.GSR			("ENABLED")

	) mult_m3 (
		.A			(A[35:18]),
		.B			(B[35:18]),
		.C			({11'b0,c_int[72:36]}),
		.CLK			(clk),
		.RST			(~resetn),
		.CEA1			(1'b1),
		.CEA2			(1'b1),
		.CEB1			(1'b1),
		.CEB2			(1'b1),
		.CEOUTPIPE		(1'b1),
		.CEC1			(1'b1),
		.CEC2			(1'b1),
		.ASHIFTIN		(18'd0),
		.BSHIFTIN		(18'd0),
		.CSHIFTIN		(18'd0),
		.CIN			(1'b0),
		.CAS_ZIN		(48'd0), // *****
		.CAS_CIN		(1'b0),
		.SELC_N			(1'b0),
		.SELCAS_ZIN_N		(1'b0),
		.SELCARRY		(1'b0),
		.ADDSUBPRE		(1'b0),
		.ADDSUBACCUM		(1'b0),
		.ASHIFTOUT		(),
		.BSHIFTOUT		(),
		.CSHIFTOUT		(),
		.ZOUT			(result_m3), // *****
		.COUT			(),
		.OVERFLOW		(),
		.CAS_ZOUT		(),
		.CAS_COUT		()
	);

endmodule

