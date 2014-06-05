library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package mandelbrot_pkg is


	constant KERNEL_N 		: integer := 5;
	constant DISPLAY_WIDTH 	: integer := 640;
	constant DISPLAY_HEIGHT : integer := 480;
	constant DISPLAY_SIZE 	: integer := DISPLAY_WIDTH*DISPLAY_HEIGHT;
	constant PIPELINE_DEPTH : integer := 16;
	constant CHUNK_SIZE 	: integer := 32;
	constant COLOR_SET_N 	: integer := 6;
	constant COLOR_SET_LOG 	: integer := 3;


    type color_table_t 		is array (0 to 255) of std_logic_vector(11 downto 0);
	type line_vector_t 		is array (DISPLAY_WIDTH-1 downto 0) of std_logic_vector(15 downto 0);
	type data_vector_t 		is array (31 downto 0) of std_logic_vector(15 downto 0);
	type VGA_vector_t 		is array (31 downto 0) of std_logic_vector(11 downto 0); 
	type kernel_data_t   	is array (PIPELINE_DEPTH-1 downto 0) of std_logic_vector(63 downto 0);
	type chunk_vector_t 	is array (CHUNK_SIZE-1 downto 0) of std_logic_vector(15 downto 0);


	type kernel_io_t is record
		-- scheduler signals
	  	chunk_valid		: std_logic;
	  	julia 			: std_logic;
	  	chunk_x 		: std_logic_vector(63 downto 0);
	  	chunk_y 		: std_logic_vector(63 downto 0);
	  	c_x 			: std_logic_vector(63 downto 0);
	  	c_y 			: std_logic_vector(63 downto 0);
 	 	p 				: std_logic_vector(63 downto 0);
 		chunk_n			: integer range 0 to DISPLAY_SIZE/CHUNK_SIZE-1;
	  	req_chunk		: std_logic;
	  	-- collector signals
	   	ack				: std_logic;
	  	done			: std_logic;
	  	out_chunk_n		: std_logic_vector(13 downto 0);
	  	result			: chunk_vector_t;	
	end record;

	type calc_to_disp_t is record
		iterations  : integer range 0 to 65535;
		color_set 	: integer range 0 to COLOR_SET_N-1;
		color_shift : std_logic;
		shift_dir 	: std_logic;
		shift_speed : integer range 0 to 3;
	end record;

	
end package ; -- mandelbrot_pkg

package body mandelbrot_pkg is
end package body mandelbrot_pkg;