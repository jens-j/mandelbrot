library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;

entity user_input_controller is
	port (
		clk 		: in  std_logic;
		reset 		: in  std_logic;
		buttons 	: in  std_logic_vector(11 downto 0);
		p 			: out std_logic_vector(63 downto 0);
		center_x 	: out std_logic_vector(63 downto 0);
		center_y 	: out std_logic_vector(63 downto 0);
		iterations  : out integer range 0 to 65535;
		color_set 	: out integer range 0 to COLOR_SET_N-1
	) ;
end entity ; -- user_input_controller


architecture arch of user_input_controller is

	type user_input_reg is record
		center_x 		: std_logic_vector(63 downto 0);
		center_y 		: std_logic_vector(63 downto 0);
		p_frac 			: std_logic_vector(70 downto 0);
		clk_count 		: integer range 0 to 999999;
		iterations 		: integer range 0 to 65535;
		prev_buttons 	: std_logic_vector(11 downto 0);
		color_set 		: integer range 0 to COLOR_SET_N-1;
	end record;

	constant R_INIT : user_input_reg := (x"F800000000000000", (others => '0'), x"0019999999999999"&"0000000", 0, 200, (others => '0'),0);

	signal r, r_in : user_input_reg := R_INIT;


begin

	p 			<= r.p_frac(70 downto 7);
	center_x 	<= r.center_x;
	center_y 	<= r.center_y;
	iterations 	<= r.iterations;
	color_set 	<= r.color_set;

	comb_proc : process(r,buttons)
		variable p_int : std_logic_vector(63 downto 0);
		variable p_sub : std_logic_vector(70 downto 0);
	begin
		r_in <= r;
		p_int := r.p_frac(70 downto 7);

		if r.clk_count = 999999 then
			r_in.clk_count <= 0;

			r_in.prev_buttons <= buttons;

			if buttons(3) = '1' then -- zooming 
				r_in.p_frac <= std_logic_vector(unsigned(r.p_frac) + shift_right(unsigned(r.p_frac),7));
			elsif buttons(11) = '1' then
				p_sub := std_logic_vector(unsigned(r.p_frac) - shift_right(unsigned(r.p_frac),7));
				if not (p_sub(70 downto 7) = (63 downto 0 => '0')) then
					r_in.p_frac <= p_sub;
				end if ;
			end if;

			if buttons(4) = '1' then -- pan x
				r_in.center_x <= std_logic_vector(signed(r.center_x) + signed(p_int));
			elsif buttons(5) = '1' then
				r_in.center_x <= std_logic_vector(signed(r.center_x) - signed(p_int));
			end if;

			if buttons(7) = '1' then -- pan y
				r_in.center_y <= std_logic_vector(signed(r.center_y) + signed(p_int));
			elsif buttons(6) = '1' then
				r_in.center_y <= std_logic_vector(signed(r.center_y) - signed(p_int));
			end if;

			if r.prev_buttons(10) = '0' and buttons(10) = '1' then
				r_in.iterations <= r.iterations + 100;
			elsif r.prev_buttons(2) = '0' and buttons(2) = '1' then
				r_in.iterations <= r.iterations - 100;
			end if ;

			if r.prev_buttons(0) = '0' and buttons(0) = '1' then
				if r.color_set = COLOR_SET_N-1 then
					r_in.color_set <= 0;
				else
					r_in.color_set <= r.color_set + 1; 
				end if ;
			end if ;
		else
			r_in.clk_count <= r.clk_count + 1;
		end if;
	end process;

	clk_proc : process( clk )
	begin
		if rising_edge(clk) then
			if reset = '1' then
				r <= R_INIT;
			else
				r <= r_in;				
			end if ;
		end if ;
	end process ; -- clk_proc

end architecture ; -- arch