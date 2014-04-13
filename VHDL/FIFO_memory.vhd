library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FIFO_memory is
	generic(
		MEM_WIDTH 		: integer := 16;
		MEM_LOG_DEPTH 	: integer := 4
	);
	port(
		clk 		: in  std_logic;
		write_en 	: in  std_logic;
		raddr 		: in  std_logic_vector(MEM_LOG_DEPTH-1 downto 0);
		waddr 		: in  std_logic_vector(MEM_LOG_DEPTH-1 downto 0);
		wdata 		: in  std_logic_vector(MEM_WIDTH-1 downto 0);
		rdata 		: out std_logic_vector(MEM_WIDTH-1 downto 0)
	) ;
end entity ; -- FIFO_memory


architecture arch of FIFO_memory is

	type mem_t is array (2**MEM_LOG_DEPTH-1 downto 0) of std_logic_vector(MEM_WIDTH-1 downto 0);
	signal memory : mem_t;
	signal raddr_r : std_logic_vector(MEM_LOG_DEPTH-1 downto 0);

begin

	rw : process(clk,raddr,memory)
	begin
		-- synchronous write
		if rising_edge(clk) then
			if write_en = '1' then
				memory(to_integer(unsigned(waddr))) <= wdata;
			end if ;
			raddr_r <= raddr;
		end if ;
		-- synchronous read
		rdata <= memory(to_integer(unsigned(raddr_r)));
	end process;


end architecture ; -- arch