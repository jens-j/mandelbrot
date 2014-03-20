library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity line_collector is
	port (
		clk 			: in  std_logic;
		reset 			: in  std_logic;
		-- input ports. connects to a FIFO
		data_in 		: in  line_vector_t;
		empty 			: in  std_logic;
		rinc 			: out std_logic;
		-- output ports. connects to the RAM controller
		RAM_write_ready : in  std_logic;
		RAM_write_data 	: out data_vector_t;
		RAM_write_addr 	: out std_logic_vector(22 downto 0);
		RAM_write_start	: out std_logic
	) ;
end entity ; -- line_collector


architecture arch of line_collector is



begin



end architecture ; -- arch