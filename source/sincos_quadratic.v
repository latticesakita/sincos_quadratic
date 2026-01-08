// this is wrapping module

module sincos_quadratic
(
	input clk,
	input resetn,
	input mode_cos,
	input [46:0] phase_i,
	input        valid_i,
	output [55:0] result_o,
	output        valid_o
);

// cos(x) = sin(x+pi/2)
// this is phase input, upper 2 bits are quadrant.
wire   [46:0] phase;
assign phase [46:45] = phase_i[46:45] + {1'b0,mode_cos};
assign phase [44: 0] = phase_i[44: 0];


sin_quadratic sin_quad_i (
	.clk		(clk),
	.resetn		(resetn),
	.phase		(phase),
	.y_out		(result_o),
	.valid_i	(valid_i),
	.valid_o	(valid_o)
);

endmodule


