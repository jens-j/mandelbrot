library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package mandelbrot_pkg is

	constant KERNEL_N 		: integer := 5;
	constant DISPLAY_WIDTH 	: integer := 640;
	constant DISPLAY_HEIGHT : integer := 480;
	constant DISPLAY_SIZE 	: integer := DISPLAY_WIDTH*DISPLAY_HEIGHT;
	constant PIPELINE_DEPTH : integer := 4;


	type data_vector_t 		is array (31 downto 0) of std_logic_vector(15 downto 0);
	type VGA_vector_t 		is array (31 downto 0) of std_logic_vector(11 downto 0); 
	type kernel_data_t   	is array (PIPELINE_DEPTH-1 downto 0) of std_logic_vector(63 downto 0);
	--type kernel_output_t 	is array (DISPLAY_WIDTH-1 downto 0) of std_logic_vector(15 downto 0);
	
end package ; -- mandelbrot_pkg

package body mandelbrot_pkg is
end package body mandelbrot_pkg;