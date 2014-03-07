library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity RAM_feed is
	port (
		RAM_clk 		: in  std_logic;
		RAM_write_ready : in  std_logic;
		RAM_write_data 	: out data_vector_t;
		RAM_write_addr 	: out std_logic_vector(22 downto 0);
		RAM_write_start	: out std_logic
	) ;
end entity ; -- RAM_feed


architecture arch of RAM_feed is

	type feed_reg is record
		x 			: integer;
		y 			: integer;
		count 		: integer;
		address 	: std_logic_vector(22 downto 0);
		done 		: std_logic;
	end record;

	signal r 	: feed_reg := (0,0,0,(others=>'0'),'0');
	signal r_in : feed_reg;

begin
	RAM_write_addr <= r.address;

	comb_proc : process( r )
		variable temp_data : std_logic_vector(6 downto 0);
		variable v_write_start : std_logic;
	begin
		r_in <= r;
		v_write_start := '0';
		if r.done = '0' then
			if r.count = 200 then
				r_in.count <= 0;

				for i in 0 to 31 loop
					temp_data := std_logic_vector(to_unsigned(r.y, 7));
					RAM_write_data(i) <= x"000" & temp_data(6 downto 3);
				end loop ; 
				v_write_start := '1';
				if to_integer(unsigned(r.address)) < DISPLAY_WIDTH*DISPLAY_HEIGHT then
					r_in.address <= std_logic_vector(unsigned(r.address) + 32);
				else
					r_in.done <= '1';
					r_in.address <= (others=>'0');
				end if ;

				if r.x = DISPLAY_WIDTH/32-1 then
					r_in.x <= 0;
					if r.y = DISPLAY_HEIGHT-1 then
						r_in.y <= 0;
					else
						r_in.y <= r.y + 1;
					end if ;
				else
					r_in.x <= r.x + 1;
				end if ;
			else
				r_in.count 	<= r.count + 1;	
			end if ;
			RAM_write_start <= v_write_start;
		end if ;

	end process;

	clk_proc : process( RAM_clk )
	begin
		if rising_edge(RAM_clk) then
			r <= r_in;
		end if ;
	end process ; -- clk_proc

end architecture ; -- arch