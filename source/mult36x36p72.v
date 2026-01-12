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
	parameter SIGNED = "SIGNED",
	parameter REGINPUTA	=	"BYPASS", // REGISTER, BYPASS 
	parameter REGINPUTB	=	"BYPASS", // REGISTER, BYPASS 
	parameter REGINPUTC	=	"BYPASS", // REGISTER, BYPASS 
	parameter REGPIPE	=	"BYPASS", // REGISTER, BYPASS
	parameter REGOUTPUT	=	"BYPASS", // REGISTER, BYPASS
	parameter REGOUTPUT2	=	"BYPASS" // REGISTER, BYPASS
)
(
	input wire clk,
	input wire resetn,
	input wire signed [35:0] A,
	input wire signed [35:0] B,
	input wire signed [71:0] C,
	output [72:0] result
);

wire [107:0] c_int;
wire [107:0] result_m;
wire         w_signed = (SIGNED == "SIGNED") ? 1'b1 : 1'b0;

assign result = result_m[72:0];


generate if(REGPIPE=="REGISTER") begin
	reg [107:0] c_reg;
	assign c_int = c_reg;
	always @(posedge clk or negedge resetn)  begin
		if(!resetn) begin
			c_reg <= 108'b0;
		end
		else begin
			c_reg <= (SIGNED == "SIGNED") ? {{(108-72){C[71]}},C[71:0]} : {36'b0, C[71:0]};
		end
	end
end
else begin
	assign c_int = (SIGNED == "SIGNED") ? {{(108-72){C[71]}},C[71:0]} : {36'b0, C[71:0]};
end
endgenerate


	MULTADDSUB36X36 #(
		.REGINPUTA		(REGINPUTA),
		.REGINPUTB		(REGINPUTB),
		.REGINPUTC		(REGINPUTC),
		.REGADDSUB		("BYPASS"), // REGISTER, BYPASS
		.REGLOADC2		("BYPASS"), // REGISTER, BYPASS
		.REGCIN			("BYPASS"),
		.REGPIPELINE		(REGPIPE),
		.REGOUTPUT		(REGOUTPUT),
		.RESETMODE		("ASYNC"),
		.GSR			("ENABLED")

	) mult_m0 (
		.A			(A[35:0]),
		.B			(B[35:0]),
		.C			(c_int),
		.CLK			(clk),

		.CEA			(1'b1),
		.CEB			(1'b1),
		.CEC			(1'b1),
		.CEPIPE			(1'b1),
		.CEOUT			(1'b1),
		.RSTA			(~resetn),
		.RSTB			(~resetn),
		.RSTC			(~resetn),
		.RSTCTRL		(~resetn),
		.CECTRL			(1'b1),
		.RSTCIN			(1'b1),
		.CECIN			(1'b0),
		.SIGNED			(w_signed), // for all ports
		.RSTPIPE		(~resetn),
		.RSTOUT			(~resetn),
		.LOADC			(1'b1),
		.ADDSUB			(1'b0),
		.CIN			(1'b0),

		.Z			(result_m)
	);

endmodule


