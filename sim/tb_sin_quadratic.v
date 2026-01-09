
// ============================================================
// tb_sincos_quad_mid.v
// ============================================================
`timescale 1ns/1ps

module tb_sin_quadratic;

localparam PHASE_BITS = 47;
localparam TEST_BITS = 14;


GSRA GSR_INST  (.GSR_N(1'b1));
    reg clk = 0;
    wire resetn;
    reg [3:0] rst_cnt = 3'b001;
    assign resetn = rst_cnt[3];
    always #5 clk = ~clk;   // 100 MHz
    always @(posedge clk) if(!resetn) rst_cnt<=rst_cnt <<< 1;

reg [31:0] randA;
reg [31:0] randB;
wire [63:0] rand = {randA, randB};

always @(posedge clk or negedge resetn) begin
	if(!resetn) begin
		randA <= 0;
		randB <= 0;
	end
	else begin
		randA <= $random;
		randB <= $random;
	end
end

    reg                  valid_i;
    reg [PHASE_BITS-1:0] phase;
    wire                 valid_o;
    wire [55:0]          y_out;


    sin_quadratic dut (
        .clk(clk),
        .resetn(resetn),
        .valid_i(valid_i),
        .phase(phase),
        .valid_o(valid_o),
        .y_out(y_out)
    );

    reg [31:0] cycle = 0;

    // FIFO to align inputs with outputs regardless of DUT latency
    localparam integer FIFO_DEPTH = 16;
    reg [PHASE_BITS-1:0] fifo_phase  [0:FIFO_DEPTH-1];
    reg [31:0] fifo_idx    [0:FIFO_DEPTH-1];
    reg [3:0] fifo_waddr;
    reg [3:0] fifo_raddr;
    wire [PHASE_BITS-1:0] w_fifo_phase = fifo_phase[fifo_raddr];
    wire [31:0] w_fifo_idx = fifo_idx[fifo_raddr];
    
    always @(posedge clk or negedge resetn) begin
    	if(!resetn) begin
    		fifo_waddr <= 0;
    	end
    	else if(valid_i) begin
    		fifo_phase[fifo_waddr] <= phase;
    		fifo_idx  [fifo_waddr] <= cycle;
    		fifo_waddr <= fifo_waddr + 1;
    	end
    end
    always @(posedge clk or negedge resetn) begin
    	if(!resetn) begin
    		fifo_raddr <= 0;
    	end
    	else if(valid_o) begin
    		fifo_raddr <= fifo_raddr + 1;
    	end
    end



    integer fd;
    initial begin
        fd = $fopen("sincos_out.csv", "w");
        $fwrite(fd, "cycle,phase,y_out\n");
    end
    always @(posedge clk or negedge resetn) begin
          if(!resetn) begin
          	cycle <= 0;
          	valid_i <= 0;
          	phase <= 0;
          end
          else if(&phase[PHASE_BITS-1: PHASE_BITS-TEST_BITS]) begin
      		$fclose(fd);
          	valid_i <= 0;
          	$stop;
          end
          else begin
          	cycle <= cycle + 1;
          	valid_i <= 1;
          	phase[PHASE_BITS-1: PHASE_BITS-TEST_BITS] <= phase[PHASE_BITS-1: PHASE_BITS-TEST_BITS] + 1;
		phase[PHASE_BITS-TEST_BITS-1 : 0] = rand[PHASE_BITS-TEST_BITS-1 : 0];
        	if (valid_o) begin
        	    $fwrite(fd, "%0d,%h,%h\n", fifo_idx[fifo_raddr], fifo_phase[fifo_raddr] , y_out);
        	end
          end
    end


endmodule

