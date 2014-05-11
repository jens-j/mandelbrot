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
		chunk_valid : out std_logic;
		p_out 		: out std_logic_vector(63 downto 0);
		chunk_x 	: out std_logic_vector(63 downto 0);
		chunk_y 	: out std_logic_vector(63 downto 0);
		chunk_n 	: out integer range 0 to (DISPLAY_SIZE/CHUNK_SIZE)
	) ;
end entity ; -- line_feeder


architecture arch of line_feeder is

	type state_t is (init0,init1,up,down);

	type line_feeder_reg is record
		state 			: state_t;
		line_y0 		: std_logic_vector(63 downto 0);
		chunk_x0 		: std_logic_vector(63 downto 0);
		line_y 	 		: std_logic_vector(63 downto 0);
		chunk_x 		: std_logic_vector(63 downto 0);
		chunk_n 		: integer range 0 to (DISPLAY_SIZE/CHUNK_SIZE);
		line_n 			: integer range 0 to DISPLAY_HEIGHT-1;
		p 				: std_logic_vector(63 downto 0);
		chunk_valid 	: std_logic;
		count 			: integer range 0 to (DISPLAY_WIDTH/CHUNK_SIZE)-1;
	end record;

	constant R_INIT : line_feeder_reg := (init0,(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),0,0,(others=>'0'),'0',0);

	signal r,r_in : line_feeder_reg := R_INIT;

begin

	chunk_x <= r.chunk_x;
	chunk_y <= r.line_y;
	chunk_n <= r.chunk_n;
	chunk_valid <= r.chunk_valid;
	p_out <= r.p;

	comb_proc : process(r, center_x, center_y, p_in, rinc)
		variable temp1,temp2,temp3,temp4 : std_logic_vector(63 downto 0);

	begin
		r_in <= r;
		case( r.state ) is
			when init0 =>
				r_in.line_n <= 240;
				r_in.chunk_n <= 0;
				r_in.count <= 0;
				r_in.p <= p_in;
				r_in.line_y0 <= center_y;
				r_in.line_y <= center_y;
				temp1 := p_in(55 downto 0)&(7 downto 0 => '0');
				r_in.chunk_x0 <= std_logic_vector(signed(center_x) - signed(temp1));
				r_in.state <= init1;	

			when init1 =>
				temp2 := r.p(57 downto 0)&(5 downto 0 => '0');
				temp3 := std_logic_vector(signed(r.chunk_x0) - signed(temp2));
				r_in.chunk_x0 <= temp3;
				r_in.chunk_x <= temp3;
				r_in.chunk_valid <= '1';	
				r_in.state <= up;
			
			when up =>
				if rinc = '1' then
					r_in.chunk_n <= r.chunk_n + 1;
					if r.count = (DISPLAY_WIDTH/CHUNK_SIZE)-1 then
						r_in.count <= 0;
						r_in.chunk_x <= r.chunk_x0;
						if r.line_n = 0 then
							r_in.line_n <= 241;
							r_in.line_y <= std_logic_vector(signed(r.line_y0) - signed(r.p));
							r_in.state <= down;
						else
							r_in.line_y <= std_logic_vector(signed(r.line_y) + signed(r.p));
							r_in.line_n <= r.line_n - 1;
						end if ;
					else			
						r_in.count <= r.count + 1; 
						temp4 := r.p(58 downto 0) & (4 downto 0 => '0');
						r_in.chunk_x <= std_logic_vector(signed(r.chunk_x) + signed(temp4));
					end if ;
				end if ;

			when down =>
				if rinc = '1' then
					r_in.chunk_n <= r.chunk_n + 1;
					if r.count = (DISPLAY_WIDTH/CHUNK_SIZE)-1 then
						r_in.count <= 0;
						r_in.chunk_x <= r.chunk_x0;
						if r.line_n = 479 then
							r_in.chunk_valid <= '0';
							r_in.state <= init0;
						else
							r_in.line_y <= std_logic_vector(signed(r.line_y) - signed(r.p));		
							r_in.line_n <= r.line_n + 1;			
						end if ;
					else
						r_in.count <= r.count + 1; 
						temp4 := r.p(58 downto 0) & (4 downto 0 => '0');
						r_in.chunk_x <= std_logic_vector(signed(r.chunk_x) + signed(temp4));
					end if;
				end if ;
		end case ;
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