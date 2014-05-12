library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity tb_mandelbrot_sys is
end entity ; -- tb_mandelbrot_sys


architecture arch of tb_mandelbrot_sys is

	signal clk, btnCpuReset : std_logic := '0';
	signal Vsync,Hsync : std_logic;
	signal vgaRed,vgaBlue,vgaGreen :  std_logic_vector(3 downto 0);
	signal RAMWAIT ,RAMOEN ,RAMCRE ,RAMADVN ,RAMWEN ,RAMCEN ,RAMUBN ,RAMLBN ,RAMCLK : std_logic;
	signal MEMADR : std_logic_vector(22 downto 0);
	signal MEMDB : std_logic_vector(15 downto 0);
	signal JA : std_logic_vector(7 downto 0);
	signal LED, SW : std_logic_vector(15 downto 0);
	signal AN : std_logic_vector(7 downto 0);
	signal SEG : std_logic_vector(6 downto 0);

begin

	UUT : entity work.mandelbrot_sys
	port map(
		clk 			=> clk,
		btnCpuReset 	=> btnCpuReset,
		-- VGA ports
		Vsync			=> Vsync,
		Hsync			=> Hsync,
		vgaRed			=> vgaRed,
		vgaGreen		=> vgaGreen,
		vgaBlue 		=> vgaBlue,
		-- RAM ports
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
		MEMDB 			=> MEMDB,
		-- snes controller port
		JA 				=> JA,
		-- IO
		SW 				=> SW,
		SEG 			=> SEG,
		AN 				=> AN
	) ;

	clk <= not clk after 5 ns;
	btnCpuReset <= '0', '1' after 500 ns;
	SW <= x"0003";

	mem_proc : process( RAMWEN )
	begin
		if RAMWEN = '0' then
			MEMDB <= (others => 'Z');
		else
			MEMDB <= x"00C8";
		end if ;
	end process ; -- identifier

	wait_proc : process
	begin
		wait until RAMCEN'event and RAMCEN = '0';
		RAMWAIT <=  	'1', '0' after 50 ns; 	
	end process;

end architecture ; -- arch