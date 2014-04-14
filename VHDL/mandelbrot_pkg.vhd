library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package mandelbrot_pkg is


	constant KERNEL_N 		: integer := 5;
	constant DISPLAY_WIDTH 	: integer := 640;
	constant DISPLAY_HEIGHT : integer := 480;
	constant DISPLAY_SIZE 	: integer := DISPLAY_WIDTH*DISPLAY_HEIGHT;
	constant PIPELINE_DEPTH : integer := 4;


    type color_table_t 		is array (255 downto 0) of std_logic_vector(11 downto 0);
	type line_vector_t 		is array (DISPLAY_WIDTH-1 downto 0) of std_logic_vector(15 downto 0);
	type data_vector_t 		is array (31 downto 0) of std_logic_vector(15 downto 0);
	type VGA_vector_t 		is array (31 downto 0) of std_logic_vector(11 downto 0); 
	type kernel_data_t   	is array (PIPELINE_DEPTH-1 downto 0) of std_logic_vector(63 downto 0);

	constant RAINBOW_TABLE 	: color_table_t := 
		(
			x"0" & x"0" & x"f",
			x"0" & x"1" & x"f",
			x"0" & x"2" & x"f",
			x"0" & x"4" & x"f",
			x"0" & x"5" & x"f",
			x"0" & x"7" & x"f",
			x"0" & x"8" & x"f",
			x"0" & x"9" & x"f",
			x"0" & x"b" & x"f",
			x"0" & x"c" & x"f",
			x"0" & x"e" & x"f",
			x"0" & x"f" & x"e",
			x"0" & x"f" & x"d",
			x"0" & x"f" & x"b",
			x"0" & x"f" & x"a",
			x"0" & x"f" & x"8",
			x"0" & x"f" & x"7",
			x"0" & x"f" & x"6",
			x"0" & x"f" & x"4",
			x"0" & x"f" & x"3",
			x"0" & x"f" & x"1",
			x"0" & x"f" & x"0",
			x"1" & x"f" & x"0",
			x"2" & x"f" & x"0",
			x"3" & x"f" & x"0",
			x"5" & x"f" & x"0",
			x"6" & x"f" & x"0",
			x"8" & x"f" & x"0",
			x"9" & x"f" & x"0",
			x"a" & x"f" & x"0",
			x"c" & x"f" & x"0",
			x"d" & x"f" & x"0",
			x"f" & x"e" & x"0",
			x"f" & x"d" & x"0",
			x"f" & x"c" & x"0",
			x"f" & x"a" & x"0",
			x"f" & x"9" & x"0",
			x"f" & x"7" & x"0",
			x"f" & x"6" & x"0",
			x"f" & x"4" & x"0",
			x"f" & x"3" & x"0",
			x"f" & x"2" & x"0",
			x"f" & x"0" & x"0",
			x"f" & x"0" & x"0",
			x"f" & x"0" & x"2",
			x"f" & x"0" & x"3",
			x"f" & x"0" & x"4",
			x"f" & x"0" & x"6",
			x"f" & x"0" & x"7",
			x"f" & x"0" & x"9",
			x"f" & x"0" & x"a",
			x"f" & x"0" & x"c",
			x"f" & x"0" & x"d",
			x"f" & x"0" & x"e",
			x"d" & x"0" & x"f",
			x"c" & x"0" & x"f",
			x"a" & x"0" & x"f",
			x"9" & x"0" & x"f",
			x"8" & x"0" & x"f",
			x"6" & x"0" & x"f",
			x"5" & x"0" & x"f",
			x"3" & x"0" & x"f",
			x"2" & x"0" & x"f",
			x"1" & x"0" & x"f",
			x"0" & x"0" & x"f",
			x"0" & x"1" & x"f",
			x"0" & x"2" & x"f",
			x"0" & x"4" & x"f",
			x"0" & x"5" & x"f",
			x"0" & x"7" & x"f",
			x"0" & x"8" & x"f",
			x"0" & x"9" & x"f",
			x"0" & x"b" & x"f",
			x"0" & x"c" & x"f",
			x"0" & x"e" & x"f",
			x"0" & x"f" & x"e",
			x"0" & x"f" & x"d",
			x"0" & x"f" & x"b",
			x"0" & x"f" & x"a",
			x"0" & x"f" & x"8",
			x"0" & x"f" & x"7",
			x"0" & x"f" & x"6",
			x"0" & x"f" & x"4",
			x"0" & x"f" & x"3",
			x"0" & x"f" & x"1",
			x"0" & x"f" & x"0",
			x"1" & x"f" & x"0",
			x"2" & x"f" & x"0",
			x"3" & x"f" & x"0",
			x"5" & x"f" & x"0",
			x"6" & x"f" & x"0",
			x"8" & x"f" & x"0",
			x"9" & x"f" & x"0",
			x"a" & x"f" & x"0",
			x"c" & x"f" & x"0",
			x"d" & x"f" & x"0",
			x"f" & x"e" & x"0",
			x"f" & x"d" & x"0",
			x"f" & x"c" & x"0",
			x"f" & x"a" & x"0",
			x"f" & x"9" & x"0",
			x"f" & x"7" & x"0",
			x"f" & x"6" & x"0",
			x"f" & x"4" & x"0",
			x"f" & x"3" & x"0",
			x"f" & x"2" & x"0",
			x"f" & x"0" & x"0",
			x"f" & x"0" & x"0",
			x"f" & x"0" & x"2",
			x"f" & x"0" & x"3",
			x"f" & x"0" & x"4",
			x"f" & x"0" & x"6",
			x"f" & x"0" & x"7",
			x"f" & x"0" & x"9",
			x"f" & x"0" & x"a",
			x"f" & x"0" & x"c",
			x"f" & x"0" & x"d",
			x"f" & x"0" & x"e",
			x"d" & x"0" & x"f",
			x"c" & x"0" & x"f",
			x"a" & x"0" & x"f",
			x"9" & x"0" & x"f",
			x"8" & x"0" & x"f",
			x"6" & x"0" & x"f",
			x"5" & x"0" & x"f",
			x"3" & x"0" & x"f",
			x"2" & x"0" & x"f",
			x"1" & x"0" & x"f",
			x"0" & x"0" & x"f",
			x"0" & x"1" & x"f",
			x"0" & x"2" & x"f",
			x"0" & x"4" & x"f",
			x"0" & x"5" & x"f",
			x"0" & x"7" & x"f",
			x"0" & x"8" & x"f",
			x"0" & x"9" & x"f",
			x"0" & x"b" & x"f",
			x"0" & x"c" & x"f",
			x"0" & x"e" & x"f",
			x"0" & x"f" & x"e",
			x"0" & x"f" & x"d",
			x"0" & x"f" & x"b",
			x"0" & x"f" & x"a",
			x"0" & x"f" & x"8",
			x"0" & x"f" & x"7",
			x"0" & x"f" & x"6",
			x"0" & x"f" & x"4",
			x"0" & x"f" & x"3",
			x"0" & x"f" & x"1",
			x"0" & x"f" & x"0",
			x"1" & x"f" & x"0",
			x"2" & x"f" & x"0",
			x"3" & x"f" & x"0",
			x"5" & x"f" & x"0",
			x"6" & x"f" & x"0",
			x"8" & x"f" & x"0",
			x"9" & x"f" & x"0",
			x"a" & x"f" & x"0",
			x"c" & x"f" & x"0",
			x"d" & x"f" & x"0",
			x"f" & x"e" & x"0",
			x"f" & x"d" & x"0",
			x"f" & x"c" & x"0",
			x"f" & x"a" & x"0",
			x"f" & x"9" & x"0",
			x"f" & x"7" & x"0",
			x"f" & x"6" & x"0",
			x"f" & x"4" & x"0",
			x"f" & x"3" & x"0",
			x"f" & x"2" & x"0",
			x"f" & x"0" & x"0",
			x"f" & x"0" & x"0",
			x"f" & x"0" & x"2",
			x"f" & x"0" & x"3",
			x"f" & x"0" & x"4",
			x"f" & x"0" & x"6",
			x"f" & x"0" & x"7",
			x"f" & x"0" & x"9",
			x"f" & x"0" & x"a",
			x"f" & x"0" & x"c",
			x"f" & x"0" & x"d",
			x"f" & x"0" & x"e",
			x"d" & x"0" & x"f",
			x"c" & x"0" & x"f",
			x"a" & x"0" & x"f",
			x"9" & x"0" & x"f",
			x"8" & x"0" & x"f",
			x"6" & x"0" & x"f",
			x"5" & x"0" & x"f",
			x"3" & x"0" & x"f",
			x"2" & x"0" & x"f",
			x"1" & x"0" & x"f",
			x"0" & x"0" & x"f",
			x"0" & x"1" & x"f",
			x"0" & x"2" & x"f",
			x"0" & x"4" & x"f",
			x"0" & x"5" & x"f",
			x"0" & x"7" & x"f",
			x"0" & x"8" & x"f",
			x"0" & x"9" & x"f",
			x"0" & x"b" & x"f",
			x"0" & x"c" & x"f",
			x"0" & x"e" & x"f",
			x"0" & x"f" & x"e",
			x"0" & x"f" & x"d",
			x"0" & x"f" & x"b",
			x"0" & x"f" & x"a",
			x"0" & x"f" & x"8",
			x"0" & x"f" & x"7",
			x"0" & x"f" & x"6",
			x"0" & x"f" & x"4",
			x"0" & x"f" & x"3",
			x"0" & x"f" & x"1",
			x"0" & x"f" & x"0",
			x"1" & x"f" & x"0",
			x"2" & x"f" & x"0",
			x"3" & x"f" & x"0",
			x"5" & x"f" & x"0",
			x"6" & x"f" & x"0",
			x"8" & x"f" & x"0",
			x"9" & x"f" & x"0",
			x"a" & x"f" & x"0",
			x"c" & x"f" & x"0",
			x"d" & x"f" & x"0",
			x"f" & x"e" & x"0",
			x"f" & x"d" & x"0",
			x"f" & x"c" & x"0",
			x"f" & x"a" & x"0",
			x"f" & x"9" & x"0",
			x"f" & x"7" & x"0",
			x"f" & x"6" & x"0",
			x"f" & x"4" & x"0",
			x"f" & x"3" & x"0",
			x"f" & x"2" & x"0",
			x"f" & x"0" & x"0",
			x"f" & x"0" & x"0",
			x"f" & x"0" & x"2",
			x"f" & x"0" & x"3",
			x"f" & x"0" & x"4",
			x"f" & x"0" & x"6",
			x"f" & x"0" & x"7",
			x"f" & x"0" & x"9",
			x"f" & x"0" & x"a",
			x"f" & x"0" & x"c",
			x"f" & x"0" & x"d",
			x"f" & x"0" & x"e",
			x"d" & x"0" & x"f",
			x"c" & x"0" & x"f",
			x"a" & x"0" & x"f",
			x"9" & x"0" & x"f",
			x"8" & x"0" & x"f",
			x"6" & x"0" & x"f",
			x"5" & x"0" & x"f",
			x"3" & x"0" & x"f",
			x"2" & x"0" & x"f",
			x"0" & x"0" & x"0"
		);
	
end package ; -- mandelbrot_pkg

package body mandelbrot_pkg is
end package body mandelbrot_pkg;