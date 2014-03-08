library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity tb_VGA_FIFO_sys is
end entity ; -- tb_VGA_FIFO_sys

architecture arch of tb_VGA_FIFO_sys is

	signal clk_s 		: std_logic := '0';
	signal reset_s 		: std_logic;
	signal Vsync_s		: std_logic;
	signal Hsync_s		: std_logic;
	signal vgaRed_s		: std_logic_vector(3 downto 0);
	signal vgaGreen_s	: std_logic_vector(3 downto 0);
	signal vgaBlue_s 	: std_logic_vector(3 downto 0);

begin

	UUT : entity work.VGA_FIFO_sys 
	port map(
		clk 		=> clk_s,
		btnC 		=> reset_s,
		Vsync		=> Vsync_s,
		Hsync		=> Hsync_s,
		vgaRed		=> vgaRed_s,
		vgaGreen	=> vgaGreen_s,
		vgaBlue 	=> vgaBlue_s
	);

	clk_s <= not clk_s after 5 ns;

	reset_s <= '1', '0' after 100 ns;

end architecture ; -- arch