library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity VGA_controller_tb is
end entity;


architecture behavioural of VGA_controller_tb is

	component VGA_controller is
	port(		clk			: in  std_logic;
				Vsync		: out std_logic;
				Hsync		: out std_logic;
				vgaRed		: out std_logic_vector(3 downto 0);
				vgaGreen	: out std_logic_vector(3 downto 0);
				vgaBlue 	: out std_logic_vector(3 downto 0);
				led			: out std_logic_vector(15 downto 0)
 		);
	end component;

	signal clk_s : std_logic := '0';
	signal Vsync_s : std_logic;
	signal Hsync_s : std_logic;
	signal vgaRed_s : std_logic_vector(3 downto 0);
	signal vgaGreen_s : std_logic_vector(3 downto 0);
	signal vgaBlue_s : std_logic_vector(3 downto 0);
	signal led_s : std_logic_vector(15 downto 0);
begin 

	UUT : VGA_controller 
	port map(clk_s,Vsync_s,Hsync_s,vgaRed_s,vgaGreen_s,vgaBlue_s,led_s);

	clk_s <= not clk_s after 5 ns;

end architecture;