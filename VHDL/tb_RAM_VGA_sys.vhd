library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity tb_RAM_VGA_sys is
end entity ; -- tb_RAM_VGA_sys


architecture arch of tb_RAM_VGA_sys is

	signal clk 			: std_logic := '0';
	signal btnCpuReset 	: std_logic;
	-- VGA signals
	signal Vsync		: std_logic;
	signal Hsync		: std_logic;
	signal vgaRed		: std_logic_vector(3 downto 0);
	signal vgaGreen		: std_logic_vector(3 downto 0);
	signal vgaBlue 		: std_logic_vector(3 downto 0);
	-- RAM signals
	signal RAMWAIT 		: std_logic;
	signal RAMOEN 		: std_logic;
	signal RAMCRE 		: std_logic;
	signal RAMADVN 		: std_logic;
	signal RAMWEN 		: std_logic;
	signal RAMCEN 		: std_logic;
	signal RAMUBN 		: std_logic;
	signal RAMLBN 		: std_logic;
	signal RAMCLK 		: std_logic;
	signal MEMADR  		: std_logic_vector(22 downto 0);
	signal MEMDB 		: std_logic_vector(15 downto 0);

begin

	UUT : entity work.RAM_VGA_sys
	port map(
		clk 			=> clk,
		btnCpuReset 	=> btnCpuReset,
		-- VGA signals
		Vsync			=> Vsync,
		Hsync			=> Hsync,
		vgaRed			=> vgaRed,
		vgaGreen		=> vgaGreen,
		vgaBlue 		=> vgaBlue,
		-- RAM signals
		RAMWAIT 		=> RAMWAIT,
		RAMOEN 			=> RAMOEN,
		RAMCRE 			=> RAMCRE,
		RAMADVN 		=> RAMADVN,
		RAMWEN 			=> RAMWEN,
		RAMCEN 			=> RAMCEN,
		RAMUBN 			=> RAMUBN,
		RAMLBN 			=> RAMLBN,
		RAMCLK 			=> RAMCLK,
		MEMADR  		=> MEMADR,
		MEMDB 			=> MEMDB
	) ;


	MEMDB <= MEMADR(15 downto 0);
	btnCpuReset <= '0', '1' after 200 ns;
	clk <= not clk after 5 ns;

	wait_proc : process
	begin
		wait until RAMCEN'event and RAMCEN = '0';
		RAMWAIT <=  	'1', '0' after 50 ns; 	
	end process;

end architecture ; -- arch