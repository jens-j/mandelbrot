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
  	signal pix_n_s			: integer range 0 to DISPLAY_SIZE-1 := 0;

  	signal done_s 			: std_logic := '0';
  	signal pix_out_n_s 		: integer range 0 to DISPLAY_SIZE-1 := 0;
  	signal result_s 		: std_logic_vector(15 downto 0);	


begin

	kernel : entity work.mandelbrot_kernel  
	port map (
      	clk   		=> clk_s,
      	max_iter 	=> 255,

		next_valid 	=> valid_s,
		next_cx 	=> cx_s,
		next_cy 	=> cy_s,
		next_pix_n 	=> pix_n_s,
		next_inc 	=> inc_s,

		done 		=> done_s,
		pix_out_n 	=> pix_out_n_s,
		result 		=> result_s
    );

	scheduler : entity work.scheduler
	port map(
		clk 		=> clk_s,
		inc 		=> inc_s,
		valid 		=> valid_s,
		cx 			=> cx_s,
		cy 			=> cy_s,
		pix_n 		=> pix_n_s
	);

	collector : entity work.collector
	port map(
		clk 		=> clk_s,
		done 		=> done_s,
		data 		=> result_s,
		pix_n 		=> pix_out_n_s
	);
    
  	clk_s <= not clk_s after 5 ns;

end architecture ; -- behavioural