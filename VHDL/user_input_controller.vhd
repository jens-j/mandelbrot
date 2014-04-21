library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity user_input_controller is
	port (
		clk 		: in  std_logic;
		buttons 	: in  std_logic_vector(11 downto 0);
		p 			: out std_logic_vector(63 downto 0);
		center_x 	: out std_logic_vector(63 downto 0);
		center_y 	: out std_logic_vector(63 downto 0)
	) ;
end entity ; -- user_input_controller


architecture arch of user_input_controller is

	type user_input_reg is record
		center_x 	: std_logic_vector(63 downto 0);
		center_y 	: std_logic_vector(63 downto 0);
		p_frac 		: std_logic_vector(70 downto 0);
		clk_count 	: integer range 0 to 999999;
	end record;

	signal r, r_in : user_input_reg := (x"F800000000000000", (others => '0'), x"0019999999999999"&"0000000", 0);


begin

	p 			<= r.p_frac(70 downto 7);
	center_x 	<= r.center_x;
	center_y 	<= r.center_y;

	comb_proc : process(r,buttons)
		variable p_int : std_logic_vector(63 downto 0);
	begin
		r_in <= r;
		p_int := r.p_frac(70 downto 7);

		if r.clk_count = 999999 then
			r_in.clk_count <= 0;

			if buttons(3) = '1' then
				r_in.p_frac <= std_logic_vector(unsigned(r.p_frac) + shift_right(unsigned(r.p_frac),7));
			elsif buttons(11) = '1' then
				r_in.p_frac <= std_logic_vector(unsigned(r.p_frac) - shift_right(unsigned(r.p_frac),7));
			end if;

			if buttons(4) = '1' then
				r_in.center_x <= std_logic_vector(signed(r.center_x) + signed(p_int));
			elsif buttons(5) = '1' then
				r_in.center_x <= std_logic_vector(signed(r.center_x) - signed(p_int));
			end if;

			if buttons(7) = '1' then
				r_in.center_y <= std_logic_vector(signed(r.center_y) + signed(p_int));
			elsif buttons(6) = '1' then
				r_in.center_y <= std_logic_vector(signed(r.center_y) - signed(p_int));
			end if;

		else
			r_in.clk_count <= r.clk_count + 1;
		end if;
	end process;

	clk_proc : process( clk )
	begin
		if rising_edge(clk) then
			r <= r_in;
		end if ;
	end process ; -- clk_proc

end architecture ; -- arch