module treehacks2022asic2(clk, reset_n, init, next, mode, block, ready, digest, digest_valid);
	
	input wire            clk;
	input wire            reset_n;

	input wire            init;
	input wire            next;
	input wire            mode;

	input wire [511 : 0]  block;

	output wire           ready;
	output wire [255 : 0] digest;
	output wire           digest_valid;
						
endmodule