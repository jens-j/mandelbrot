library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity bin13_to_bcd4 is
	port (
		clk 		: in  std_logic;
		start 		: in  std_logic; -- strobe
		bin 		: in  std_logic_vector(12 downto 0); -- max 8192
		bcd 		: out std_logic_vector(15 downto 0)
	) ;
end entity ; -- bin13_to_bcd4


architecture arch of bin13_to_bcd4 is

	type state_t is (idle, working);

	type bin_to_bcd_reg is record
		state 		: state_t; 
		shift_reg 	: std_logic_vector(28 downto 0);
		bcd 		: std_logic_vector(15 downto 0);
		count  		: integer range 0 to 15;
	end record;

	constant REG_INIT : bin_to_bcd_reg := (idle, (others => '0'), (others => '0'), 0);

	signal r, r_in : bin_to_bcd_reg := REG_INIT;

begin

	bcd <= r.bcd;

	comb_proc : process(r, start, bin)
		variable v : bin_to_bcd_reg;
		variable temp : std_logic_vector(3 downto 0);
	begin 
		v := r;

		case( r.state ) is
		
			when idle =>
				if start = '1' then
					v.shift_reg := (28 downto 13 => '0') & bin;
					v.count := 0;
					v.state := working;
				end if ;
		
			when working =>
				if r.count = 13 then
					v.bcd := r.shift_reg(28 downto 13);
					v.state := idle;
				else
					for i in 0 to 3 loop
					 	temp := r.shift_reg((16+4*i) downto (13+4*i));
					 	if temp(3)='1' or (temp(2)='1' and (temp(1)='1' or temp(0)='1')) then
					 		v.shift_reg(12+4*(i+1) downto 13+4*i) := std_logic_vector(unsigned(r.shift_reg(12+4*(i+1) downto 13+4*i)) + 3);
					 	end if ;
					end loop ; 
					v.shift_reg := v.shift_reg(27 downto 0) & '0';
					v.count := r.count + 1;
				end if ;
		
		end case ;

		r_in <= v;
	end process;

	clk_proc : process( clk )
	begin
		if rising_edge(clk) then
			r <= r_in;				
		end if ;
	end process ; -- clk_proc

end architecture ; -- arch