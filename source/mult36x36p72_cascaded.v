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
	parameter REGOUTPUT	=	"BYPASSED" // REGISTERED, BYPASSED
)
(
	input wire clk,
	input wire resetn,
	input wire signed [35:0] A,
	input wire signed [35:0] B,
	input wire signed [71:0] C,
	output wire signed [72:0] result
);

wire [72:0] c_int;
wire [17:0] AL = A[17: 0];
wire [17:0] BL = B[17: 0];
wire [17:0] AH = A[35:18];
wire [17:0] BH = B[35:18];
wire [47:0] C_m0 = {30'b0,c_int[17:0]};
wire [47:0] C_m2 = {30'b0,c_int[35:18]};
wire [47:0] C_m3 = {11'b0,c_int[72:36]};

wire signed [47:0] result_m0;
wire signed [47:0] result_m0_CAS;
wire signed [47:0] result_m1_CAS;
wire signed [47:0] result_m2;
wire signed [47:0] result_m2_CAS;
wire signed [47:0] result_m3;

assign c_int = (CSIGNED == "SIGNED") ? {C[71],C[71:0]} : {1'b0, C[71:0]};
assign	result [17: 0] = result_m0[17:0];
assign	result [35:18] = result_m2[17:0];
assign	result [72:36] = result_m3[36:0];


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
		.CAS_ZOUT_RSHIFT	("ENABLED"), // ("DISABLED"),
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
		.CAS_ZOUT		(result_m0_CAS), // 18bits shifted
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
		.ACCUM_C_EN		("DISABLED"),
		.CAS_ZIN_EN		("ENABLED"),// ("ENABLED")
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
		.CAS_ZIN		(result_m0_CAS), // *****
		.CAS_CIN		(1'b0),
		.SELC_N			(1'b0),
		.SELCAS_ZIN_N		(1'b0),
		.SELCARRY		(1'b0),
		.ADDSUBPRE		(1'b0),
		.ADDSUBACCUM		(1'b0),
		.ASHIFTOUT		(),
		.BSHIFTOUT		(),
		.CSHIFTOUT		(),
		.ZOUT			(),
		.COUT			(),
		.OVERFLOW		(),
		.CAS_ZOUT		(result_m1_CAS), // No Shift
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
		.CAS_ZOUT_RSHIFT	("ENABLED"), // ("DISABLED"),
		.PREADD_EN		("DISABLED"),
		.REGADDSUBPRE		("BYPASSED"),
		.ACCUM_C_EN		("ENABLED"), // ("DISABLED"),
		.CAS_ZIN_EN		("ENABLED"),// ("ENABLED")
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
		.CAS_ZIN		(result_m1_CAS), // *****
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
		.CAS_ZOUT		(result_m2_CAS), // 18bits shifted
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
		.CAS_ZOUT_RSHIFT	("ENABLED"), // ("DISABLED"),
		.PREADD_EN		("DISABLED"),
		.REGADDSUBPRE		("BYPASSED"),
		.ACCUM_C_EN		("ENABLED"), // ("DISABLED"),
		.CAS_ZIN_EN		("ENABLED"),// ("ENABLED")
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
		.CAS_ZIN		(result_m2_CAS), // *****
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

