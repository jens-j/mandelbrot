library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity mandelbrot_kernel_tb is
end entity ; -- mandelbrot_kernel_tb


architecture behavioural of mandelbrot_kernel_tb is

  	signal clk_s 			: std_logic := '0';

  	signal inc_s,valid_s 	: std_logic := '0';
  	signal cx_s,cy_s 		: std_logic_vector(63 downto 0);
  	signal pix_n_s			: integer range 0 to DISPLAY_HEIGHT-1 := 0;

  	signal done_s 			: std_logic := '0';
  	signal pix_out_n_s 		: std_logic_vector(9 downto 0);
  	signal result_s 		: line_vector_t;
  	signal ack_s 			: std_logic;
	
	signal in_p_s 			: std_logic_vector(63 downto 0);

begin

	kernel : entity work.mandelbrot_kernel  
	port map (
      	clk   		=> clk_s,
      	max_iter 	=> 255,

		in_valid 	=> valid_s,
		c0_real 	=> cx_s,
		c0_imag 	=> cy_s,
		in_p 		=> in_p_s,
		in_line_n 	=> pix_n_s,
		in_req 		=> inc_s,

		ack 		=> ack_s,
		done 		=> done_s,
		out_line_n 	=> pix_out_n_s,
		result 		=> result_s
    );


end architecture ; -- behavioural