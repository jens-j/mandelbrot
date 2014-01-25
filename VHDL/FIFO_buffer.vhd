library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library work;
use work.mandelbrot_pkg.all;


entity FIFO_buffer is
	generic (
		WIDTH : integer := 16;
		DEPTH : integer := 16
	);
	port (
		clk_w 		: in  std_logic;
		clk_r 		: in  std_logic;
		pop			: in  std_logic;
		push 		: in  std_logic;
		data_in 	: in  std_logic_vector(WIDTH-1 downto 0);
		data_out 	: out std_logic_vector(WIDTH-1 downto 0);
		buff_full  	: out std_logic;
		buff_empty 	: out std_logic
	);
end entity ; -- FIFO_buffer


architecture behavioural of FIFO_buffer is

	type fifo_mem is array (DEPTH-1 downto 0) of std_logic_vector(WIDTH-1 downto 0);

	signal read_ptr, write_ptr : std_logic_vector(integer(ceil(log2(real(DEPTH))))-1 downto 0);

begin



end architecture ; -- arch