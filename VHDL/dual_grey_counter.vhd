library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dual_grey_counter is
	generic(
		WIDTH 		: integer := 5
	);
	port (
		clk 		: in  std_logic;
		reset 		: in  std_logic;
		inc 		: in  std_logic;
		inc_en 		: in  std_logic;
		bin 		: out std_logic_vector(WIDTH-2 downto 0);
		ptr 		: out std_logic_vector(WIDTH-1 downto 0);
		gnext 		: out std_logic_vector(WIDTH-1 downto 0)
	);
end entity ; -- dual_grey_counter


architecture arch of dual_grey_counter is

	function bin_to_grey(x : std_logic_vector) return std_logic_vector is
	begin
		return x xor ('0' & x(x'length-1 downto 1));
	end bin_to_grey;

	signal bin_reg, next_bin 	: std_logic_vector(WIDTH-1 downto 0);
	signal grey_reg, next_grey 	: std_logic_vector(WIDTH-1 downto 0);

begin

	-- output ports
	bin 		<= bin_reg(WIDTH-2 downto 0);
	ptr 		<= grey_reg; 
	gnext 		<= next_grey;

	comb_proc : process(inc, inc_en, next_bin, bin_reg, reset)
		variable inc_in : std_logic_vector(WIDTH-1 downto 0);
	begin
		if reset = '1' then
			next_bin <= (others => '0');
			next_grey <= (others => '0');
		else
			inc_in 		:= (WIDTH-1 downto 1 => '0') & (inc and inc_en);
			next_bin 	<= std_logic_vector(unsigned(bin_reg) + unsigned(inc_in));
			next_grey 	<= bin_to_grey(next_bin);
		end if ;
	end process;

	clk_proc : process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				bin_reg <= (others => '0');
				grey_reg <= (others => '0');
			else
				bin_reg <= next_bin;
				grey_reg <= next_grey;
			end if ;

		end if ;
	end process;

end architecture ; -- arch+