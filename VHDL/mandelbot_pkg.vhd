library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package mandelbot_pkg is

	constant KERNEL_N 		: integer := 15;
	constant DSIPLAY_WIDTH 	: integer := 480;
	constant DISPLAY_HEIGHT : integer := 360;

	type kernel_data_t   is array (6 downto 0) of std_logic_vector(63 downto 0);
	type kernel_output_t is array (DSIPLAY_WIDTH-1 downto 0) of std_logic_vector(15 downto 0);
	
end package ; -- mandelbot_pkg