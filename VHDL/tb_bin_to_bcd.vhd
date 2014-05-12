library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity tb_bin_to_bcd is
end entity ; -- tb_bin_to_bcd

architecture arch of tb_bin_to_bcd is

	signal clk, start : std_logic := '0';
	signal bin : std_logic_vector(12 downto 0);
	signal bcd : std_logic_vector(15 downto 0);

begin

	bin13_to_bcd4 : entity work.bin13_to_bcd4
	port map(
		clk 		=> clk,
		start 		=> start,
		bin 		=> bin,
		bcd 		=> bcd
	) ;

	bin <= '0' & x"73A";
	clk <= not clk after 10 ns;
	start <= 	'0',
				'1' after 100 ns,
				'0' after 140 ns;

end architecture ; -- arch