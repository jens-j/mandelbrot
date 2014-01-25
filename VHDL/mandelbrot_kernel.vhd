library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity mandelbrot_kernel is
  port (
	clock 		: in  std_logic;
	z0_real		: in  kernel_data_t;
	z0_imag		: in  kernel_data_t;
	start 		: in  std_logic_vector(KERNEL_N-1 downto 0);
	done 		: out std_logic_vector(KERNEL_N-1 downto 0);
	result 		: out kernel_output_t
	);
end entity ; -- mandelbrot_kernel


architecture arch of mandelbrot_kernel is

	type state_t is (s00,s01,s02,s10,s11,s12,s20,s21,s22,s30,s31,s32,s40,s41,s42,s50,s51,s52);
	type iteration_t is array (5 downto 0) of integer in range 0 to 65525;

	type kernel_reg is record
		z_real 		: kernel_data_t;
		z_imag 		: kernel_data_t;
		result 		: kernel_output_t;
		iteration	: iteration_t; 
	end record;

	signal r, r_in 		: kernel_reg;
	signal mult_op1_s 	: std_logic_vector(63 downto 0);
	signal mult_op2_s 	: std_logic_vector(63 downto 0);
	signal mult_res_s 	: std_logic_vector(63 downto 0);


begin
	multiplier : entity work.mult64x64
    port map (
      clk   => clk,
      a     => mult_op1,
      b     => mult_op2,
      p 	=> mult_res);


	comb_prov : process(r,z0_imag,z0_real,start) 
		variable v 			: kernel_reg;

	begin
		v := r;

		case( r.state ) is
		
			when s00 =>
				mult_op1_s <= z0_real(0);
				mult_op2_s <= z0_real(0);

		
			when others =>
		
		end case ;

		r_in <= v;
	end process;


	reg_proc : process(clk)
	begin
		if rising_edge(clk) then 
		 	r <= r_in;
		end if;
	end process;

end architecture ; -- arch