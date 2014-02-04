library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;

entity RAM_controller_tb is
  port (
	RAMWAIT 	: in  std_logic;
	RAMCRE 		: out std_logic;
	RAMADVN 	: out std_logic;
	RAMWEN 		: out std_logic;
	MEMADR  	: out std_logic_vector(22 downto 0);
	MEMDB 		: inout std_logic_vector(15 downto 0)
  	) ;
end entity ; -- RAM_controller_tb

architecture behavioural of RAM_controller_tb is

	component RAM_controller is
 	port (
		RAM_clk 	: in  std_logic;
		reset 		: in  std_logic;
		-- write port signals
		write_data 	: in  data_vector_t;
		write_addr 	: in  std_logic_vector(17 downto 0);
		write_start	: in  std_logic;
		-- read port
		read_addr 	: in  std_logic_vector(17 downto 0);
		read_start 	: in  std_logic;
		read_data	: out data_vector_t;
		-- RAM signal
		RAMWAIT 	: in  std_logic;
		RAMCRE 		: out std_logic;
		RAMADVN 	: out std_logic;
		RAMWEN 		: out std_logic;
		MEMADR  	: out std_logic_vector(22 downto 0);
		MEMDB 		: inout std_logic_vector(15 downto 0)
  	) ;
	end component ; -- RAM_controller

	signal clk_s 			: std_logic := '0';
	signal reset_s 			: std_logic := '0';
	signal write_data_s 	: data_vector_t;
	signal write_addr_s 	: std_logic_vector(17 downto 0);
	signal write_start_s	: std_logic;
	signal read_addr_s 		: std_logic_vector(17 downto 0);
	signal read_start_s 	: std_logic;
	signal read_data_s		: data_vector_t;
	signal ramwait_s 		: std_logic;

begin

	uut : RAM_controller 
	port map(
		RAM_clk 	=> clk_s,
		reset 		=> reset_s,
		-- write port signals
		write_data 	=> write_data_s,
		write_addr 	=> write_addr_s,
		write_start	=> write_start_s,
		-- read port
		read_addr 	=> read_addr_s,
		read_start 	=> read_start_s,
		read_data	=> read_data_s,
		-- RAM signal
		RAMWAIT 	=> ramwait_s,
		RAMCRE 		=> RAMCRE,
		RAMADVN 	=> RAMADVN,
		RAMWEN 		=> RAMWEN,
		MEMADR  	=> MEMADR,
		MEMDB 		=> MEMDB
	);

	clk_s <= not clk_s after 5 ns;

	test : process

	begin

		reset_s <= '1';
		wait for 100 ns;
		reset_s <= '0'; 
		wait for 200 us;

		for i in 0 to 31 loop
			write_data_s(i) <= std_logic_vector(to_unsigned(i,16));
		end loop;
		write_addr_s 	<= (others => '0');
		write_start_s	<= '1';
		ramwait_s 		<= '1';
		wait for 100 ns;
		write_start_s 	<= '0';
		ramwait_s 		<= '0';
		wait for 50 us;



	end process;

end architecture ; -- behavioural