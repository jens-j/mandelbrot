library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity line_feeder is
	port (
		clk 		: in  std_logic;
		reset 		: in  std_logic;
		rinc 		: in  std_logic;
		center_x 	: in  std_logic_vector(63 downto 0);
		center_y 	: in  std_logic_vector(63 downto 0);
		p_in		: in  std_logic_vector(63 downto 0);
		line_valid 	: out std_logic;
		p_out 		: out std_logic_vector(63 downto 0);
		line_x 		: out std_logic_vector(63 downto 0);
		line_y 		: out std_logic_vector(63 downto 0);
		line_n 		: out integer range 0 to DISPLAY_HEIGHT-1
	) ;
end entity ; -- line_feeder


architecture arch of line_feeder is

	type state_t is (init0,init1,up,down);

	type line_feeder_reg is record
		state 			: state_t;
		line_y0 		: std_logic_vector(63 downto 0);
		line_y 	 		: std_logic_vector(63 downto 0);
		line_x 			: std_logic_vector(63 downto 0);
		line_n 			: integer range 0 to DISPLAY_HEIGHT-1;
		p 				: std_logic_vector(63 downto 0);
		line_valid 		: std_logic;
	end record;

	signal r,r_in : line_feeder_reg := (init0,(others=>'0'),(others=>'0'),(others=>'0'),0,(others=>'0'),'0');

begin

	line_x <= r.line_x;
	line_y <= r.line_y;
	line_n <= r.line_n;
	line_valid <= r.line_valid;
	p_out <= r.p;

	comb_proc : process(r, center_x, center_y, p_in, rinc)
		variable temp : std_logic_vector(63 downto 0);
	begin
		r_in <= r;
		case( r.state ) is
			when init0 =>
				r_in.line_n <= 240;
				r_in.p <= p_in;
				r_in.line_y0 <= center_y;
				r_in.line_y <= center_y;
				temp := p_in(55 downto 0)&(7 downto 0 => '0');
				r_in.line_x <= std_logic_vector(signed(center_x) - signed(temp));
				r_in.state <= init1;	

			when init1 =>
				temp := r.p(57 downto 0)&(5 downto 0 => '0');
				r_in.line_x <= std_logic_vector(signed(r.line_x) - signed(temp));
				r_in.line_valid <= '1';	
				r_in.state <= up;
			
			when up =>
				if rinc = '1' then
					if r.line_n = 0 then
						r_in.line_n <= 241;
						r_in.line_y <= std_logic_vector(signed(r.line_y0) - signed(r.p));
						r_in.state <= down;
					else
						r_in.line_y <= std_logic_vector(signed(r.line_y) + signed(r.p));
						r_in.line_n <= r.line_n - 1;
					end if ;
				end if ;

			when down =>
				if rinc = '1' then
					if r.line_n = 479 then
						r_in.line_valid <= '0';
						r_in.state <= init0;
					else
						r_in.line_y <= std_logic_vector(signed(r.line_y) - signed(r.p));		
						r_in.line_n <= r.line_n + 1;			
					end if ;
				end if ;

		end case ;
	end process;

	clk_proc : process( clk )
	begin
		if rising_edge(clk) then
			r <= r_in;
		end if ;
	end process ; -- clk_proc

end architecture ; -- arch