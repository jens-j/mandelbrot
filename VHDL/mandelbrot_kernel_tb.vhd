library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity mandelbrot_kernel_tb is
  port (
	clk 	: in  std_logic;
	SW		: in  std_logic_vector(15 downto 0);
	LED 	: out std_logic_vector(15 downto 0)
  ) ;
end entity ; -- mandelbrot_kernel_tb


architecture behavioural of mandelbrot_kernel_tb is

	component mandelbrot_kernel is
	  port (
		clk 		: in  std_logic;
		orig_real	: in  std_logic_vector(63 downto 0);
		orig_imag 	: in  std_logic_vector(63 downto 0);
		pix_size 	: in  std_logic_vector(63 downto 0);
		max_iter 	: in  integer range 0 to 65535;
		start 		: in  std_logic;
		done 		: out std_logic;
		result 		: out kernel_output_t
		);
	end component ; -- mandelbrot_kernel

  	signal clk_s 			: std_logic := '0';
	signal done_s, start_s 	: std_logic;
	signal result_s		   	: kernel_output_t;


begin

	kernel0 : mandelbrot_kernel  port map (
      	clk   		=> clk_s,
		orig_real	=> x"D800000000000000", -- -2.5
		orig_imag 	=> x"0000000000000000", -- 0
		pix_size 	=> x"0019999999999999", -- 0.00625
		max_iter 	=> 255,
		start 		=> start_s,
		done 		=> done_s,
		result 		=> result_s
    );
    
  	clk_s <= not clk_s after 5 ns;

	output_sel : process(result_s, SW)
	begin
		if SW(0) = '0' then
			LED <= (others => '1');
			start_s <= '0';
		else
			LED <= result_s(100)(15 downto 0);
			start_s <= '1';
		end if ;
	end process;

end architecture ; -- behavioural