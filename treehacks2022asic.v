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
	
//----------------------------------------------
	
		localparam SHA224_H0_0 = 32'hc1059ed8;
		localparam SHA224_H0_1 = 32'h367cd507;
		localparam SHA224_H0_2 = 32'h3070dd17;
		localparam SHA224_H0_3 = 32'hf70e5939;
		localparam SHA224_H0_4 = 32'hffc00b31;
		localparam SHA224_H0_5 = 32'h68581511;
		localparam SHA224_H0_6 = 32'h64f98fa7;
		localparam SHA224_H0_7 = 32'hbefa4fa4;

		localparam SHA256_H0_0 = 32'h6a09e667;
		localparam SHA256_H0_1 = 32'hbb67ae85;
		localparam SHA256_H0_2 = 32'h3c6ef372;
		localparam SHA256_H0_3 = 32'ha54ff53a;
		localparam SHA256_H0_4 = 32'h510e527f;
		localparam SHA256_H0_5 = 32'h9b05688c;
		localparam SHA256_H0_6 = 32'h1f83d9ab;
		localparam SHA256_H0_7 = 32'h5be0cd19;

		localparam SHA256_ROUNDS = 63;

		localparam CTRL_IDLE   = 0;
		localparam CTRL_ROUNDS = 1;
		localparam CTRL_DONE   = 2;
		

//----------------------------------------------
	
	
		reg [31 : 0] a_reg;
		reg [31 : 0] a_new;
		reg [31 : 0] b_reg;
		reg [31 : 0] b_new;
		reg [31 : 0] c_reg;
		reg [31 : 0] c_new;
		reg [31 : 0] d_reg;
		reg [31 : 0] d_new;
		reg [31 : 0] e_reg;
		reg [31 : 0] e_new;
		reg [31 : 0] f_reg;
		reg [31 : 0] f_new;
		reg [31 : 0] g_reg;
      reg [31 : 0] g_new;
      reg [31 : 0] h_reg;
      reg [31 : 0] h_new;
		
		reg [31 : 0] H0_reg;
		reg [31 : 0] H0_new;
		reg [31 : 0] H1_reg;
		reg [31 : 0] H1_new;
		reg [31 : 0] H2_reg;
		reg [31 : 0] H2_new;
		reg [31 : 0] H3_reg;
		reg [31 : 0] H3_new;
		reg [31 : 0] H4_reg;
		reg [31 : 0] H4_new;
		reg [31 : 0] H5_reg;
		reg [31 : 0] H5_new;
		reg [31 : 0] H6_reg;
		reg [31 : 0] H6_new;
		reg [31 : 0] H7_reg;
		reg [31 : 0] H7_new;
		reg          H_we;

		reg [5 : 0] t_ctr_reg;
		reg [5 : 0] t_ctr_new;
		reg         t_ctr_we;
		reg         t_ctr_inc;
		reg         t_ctr_rst;

		reg digest_valid_reg;
		reg digest_valid_new;
		reg digest_valid_we;

		reg [1 : 0] sha256_ctrl_reg;
		reg [1 : 0] sha256_ctrl_new;
		reg         sha256_ctrl_we;
		
		reg          a_h_we;  
		reg digest_init;
      reg digest_update;
		
//----------------------------------------------

	
	always @ (posedge clk or negedge reset_n)
    begin : reg_update
      if (!reset_n)
        begin
          a_reg            <= 32'h0;
          b_reg            <= 32'h0;
          c_reg            <= 32'h0;
          d_reg            <= 32'h0;
          e_reg            <= 32'h0;
          f_reg            <= 32'h0;
          g_reg            <= 32'h0;
          h_reg            <= 32'h0;
          H0_reg           <= 32'h0;
          H1_reg           <= 32'h0;
          H2_reg           <= 32'h0;
          H3_reg           <= 32'h0;
          H4_reg           <= 32'h0;
          H5_reg           <= 32'h0;
          H6_reg           <= 32'h0;
          H7_reg           <= 32'h0;
          digest_valid_reg <= 0;
          t_ctr_reg        <= 6'h0;
          sha256_ctrl_reg  <= CTRL_IDLE;
        end
      else
        begin

          if (a_h_we)
            begin
              a_reg <= a_new;
              b_reg <= b_new;
              c_reg <= c_new;
              d_reg <= d_new;
              e_reg <= e_new;
              f_reg <= f_new;
              g_reg <= g_new;
              h_reg <= h_new;
            end

          if (H_we)
            begin
              H0_reg <= H0_new;
              H1_reg <= H1_new;
              H2_reg <= H2_new;
              H3_reg <= H3_new;
              H4_reg <= H4_new;
              H5_reg <= H5_new;
              H6_reg <= H6_new;
              H7_reg <= H7_new;
            end

          if (t_ctr_we)
            t_ctr_reg <= t_ctr_new;

          if (digest_valid_we)
            digest_valid_reg <= digest_valid_new;

          if (sha256_ctrl_we)
            sha256_ctrl_reg <= sha256_ctrl_new;
        end
    end

  always @*
    begin : digest_logic
      H0_new = 32'h0;
      H1_new = 32'h0;
      H2_new = 32'h0;
      H3_new = 32'h0;
      H4_new = 32'h0;
      H5_new = 32'h0;
      H6_new = 32'h0;
      H7_new = 32'h0;
      H_we = 0;

      if (digest_init)
        begin
          H_we = 1;
          if (mode)
            begin
              H0_new = SHA256_H0_0;
              H1_new = SHA256_H0_1;
              H2_new = SHA256_H0_2;
              H3_new = SHA256_H0_3;
              H4_new = SHA256_H0_4;
              H5_new = SHA256_H0_5;
              H6_new = SHA256_H0_6;
              H7_new = SHA256_H0_7;
            end
          else
            begin
              H0_new = SHA224_H0_0;
              H1_new = SHA224_H0_1;
              H2_new = SHA224_H0_2;
              H3_new = SHA224_H0_3;
              H4_new = SHA224_H0_4;
              H5_new = SHA224_H0_5;
              H6_new = SHA224_H0_6;
              H7_new = SHA224_H0_7;
            end
        end

      if (digest_update)
        begin
          H0_new = H0_reg + a_reg;
          H1_new = H1_reg + b_reg;
          H2_new = H2_reg + c_reg;
          H3_new = H3_reg + d_reg;
          H4_new = H4_reg + e_reg;
          H5_new = H5_reg + f_reg;
          H6_new = H6_reg + g_reg;
          H7_new = H7_reg + h_reg;
          H_we = 1;
        end
    end
						
endmodule