library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;

entity RAM_controller_tb is
  port (
  	CLK 		: in  std_logic;
	RAMWAIT 	: in  std_logic;
	RAMCRE 		: out std_logic;
	RAMADVN 	: out std_logic;
	RAMWEN 		: out std_logic;
	RAMCLK 		: out std_logic;
	LED 		: out std_logic_vector(15 downto 0);
	MEMADR  	: out std_logic_vector(22 downto 0);
	MEMDB 		: inout std_logic_vector(15 downto 0);
	-- constants
	RAMOEN 		: out std_logic;
	RAMLBN 		: out std_logic;
	RAMUBN 		: out std_logic
  	) ;
end entity ; -- RAM_controller_tb

architecture behavioural of RAM_controller_tb is

	component RAM_controller is
 	port (
		RAM_clk 	: in  std_logic;
		reset 		: in  std_logic;
		RAM_ready 	: out std_logic; -- indicates if the ram is initialized 
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

	component RAM_clock_gen is
	port
	 (-- Clock in ports
		CLK_IN1           : in     std_logic;
		-- Clock out ports
		CLK_OUT1          : out    std_logic;
		CLK_OUT2_CE       : in     std_logic;
		CLK_OUT2          : out    std_logic;
		-- Status and control signals
		RESET             : in     std_logic;
		LOCKED            : out    std_logic
	 );
	end component;

	--signal clk_s 			: std_logic := '0';
	signal ram_clk_s		: std_logic;
	signal ram_out_clk_s	: std_logic;
	signal ram_ready_s		: std_logic;
	signal locked_s			: std_logic;
	signal reset_s 			: std_logic := '0';
	signal write_data_s 	: data_vector_t;
	signal write_addr_s 	: std_logic_vector(17 downto 0);
	signal write_start_s	: std_logic;
	signal read_addr_s 		: std_logic_vector(17 downto 0);
	signal read_start_s 	: std_logic;
	signal read_data_s		: data_vector_t;
	signal ramwait_s 		: std_logic;

begin

	clock_gen : RAM_clock_gen
	port map(
		CLK_IN1 	=> CLK,
		CLK_OUT1 	=> ram_clk_s,
		CLK_OUT2 	=> ram_out_clk_s,
		CLK_OUT2_CE => ram_ready_s,
		RESET 		=> reset_s,
		LOCKED 		=> locked_s
	);

	uut : RAM_controller 
	port map(
		RAM_clk 	=> ram_clk_s,
		reset 		=> reset_s,
		RAM_ready 	=> ram_ready_s,
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

	-- clk_s <= not clk_s after 5 ns;

	test : process

	begin

		RAMOEN 	<= '0';
		RAMLBN 	<= '0';
		RAMUBN 	<= '0';
		RAMCLK  <= ram_out_clk_s;


		reset_s <= '1';
		wait for 100 ns;
		reset_s <= '0'; 
		wait for 250 us;

		for i in 0 to 31 loop
			write_data_s(i) <= std_logic_vector(to_unsigned(i,16));
		end loop;
		write_addr_s 	<= (others => '0');
		write_start_s	<= '1';
		ramwait_s 		<= '1';
		wait for 100 ns;
		ramwait_s 		<= '0';
		wait for 500 ns;
		read_addr_s		<= (others => '0');
		read_start_s	<= '1';
		wait for 100 ns;
		LED 			<= read_data_s(15);
		wait for 100 us;



	end process;

end architecture ; -- behavioural