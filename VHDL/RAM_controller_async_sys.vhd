library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity RAM_controller_async_sys is
  port (
	CLK 		: in  std_logic;
	LED 		: out std_logic_vector(15 downto 0);
		-- RAM signal
	RAMCLK 		: out std_logic;
	RAMCRE 		: out std_logic;
	RAMADVN 	: out std_logic;
	RAMWEN 		: out std_logic;
	RAMCEN 		: out std_logic;
	RAMOEN 		: out std_logic;
	RAMLBN 		: out std_logic;
	RAMUBN 		: out std_logic;
	MEMADR  	: out std_logic_vector(22 downto 0);
	MEMDB 		: inout std_logic_vector(15 downto 0)
  ) ;
end entity ; -- RAM_controller_async_sys


architecture behavioural of RAM_controller_async_sys is

	component RAM_controller_async is
 	port (
		CLK 		: in  std_logic;
		reset 		: in  std_logic;
		RAM_ready 	: out std_logic; -- indicates if the ram is initialized 
		-- write port signals
		write_data 	: in  std_logic_vector(15 downto 0);
		write_addr 	: in  std_logic_vector(22 downto 0);
		write_start	: in  std_logic;
		write_done 	: out  std_logic;
		-- read port
		read_data	: out std_logic_vector(15 downto 0);
		read_addr 	: in  std_logic_vector(22 downto 0);
		read_start 	: in  std_logic;
		read_done 	: out std_logic;
		-- RAM signal
		RAMCLK 		: out std_logic;
		RAMCRE 		: out std_logic;
		RAMADVN 	: out std_logic;
		RAMWEN 		: out std_logic;
		RAMCEN 		: out std_logic;
		RAMOEN 		: out std_logic;
		RAMLBN 		: out std_logic;
		RAMUBN 		: out std_logic;
		MEMADR  	: out std_logic_vector(22 downto 0);
		MEMDB 		: inout std_logic_vector(15 downto 0)
  	) ;
end component ; -- RAM_controller

	signal RAM_ready_s 	:  std_logic; -- indicates if the ram is initialized 
	-- write port signals
	signal write_data_s 	: std_logic_vector(15 downto 0);
	signal write_addr_s 	: std_logic_vector(22 downto 0);
	signal write_start_s	: std_logic;
	signal write_done_s 	: std_logic;
	-- read port
	signal read_data_s		: std_logic_vector(15 downto 0);
	signal read_addr_s 		: std_logic_vector(22 downto 0);
	signal read_start_s 	: std_logic;
	signal read_done_s 		: std_logic;

	signal state 		: integer := 0;
	signal state_in		: integer := 0;

	--signal clk_s 		: std_logic := '0';
	signal reset_s 		: std_logic := '0';

begin

	uut : RAM_controller_async 
	port map(
		CLK 		=> CLK,
		reset 		=> reset_s,
		RAM_ready 	=> RAM_ready_s,

		write_data 	=> write_data_s,
		write_addr 	=> write_addr_s,
		write_start => write_start_s,
		write_done 	=> write_done_s,

		read_data 	=> read_data_s,
		read_addr 	=> read_addr_s,
		read_start 	=> read_start_s,
		read_done 	=> read_done_s,

		RAMCLK 		=> RAMCLK,
		RAMCRE 		=> RAMCRE,
		RAMADVN 	=> RAMADVN,
		RAMWEN 		=> RAMWEN,
		RAMCEN 		=> RAMCEN,
		RAMOEN 		=> RAMOEN,
		RAMLBN 		=> RAMLBN,
		RAMUBN 		=> RAMUBN,
		MEMADR  	=> MEMADR,
		MEMDB 		=> MEMDB
	);


	--clk_s <= not clk_s after 5 ns;


	comb_proc : process(state, write_done_s, read_done_s, read_data_s, RAM_ready_s)
	begin

		case( state ) is
		
			when 0 =>
				LED(15) <= '1';
				if RAM_ready_s = '1' then
					state_in <= 1;
				end if ;

			when 1 =>
				LED(14) <= '1';
				write_addr_s 	<= (others => '0');
				write_data_s 	<= x"CCCC";
				write_start_s 	<= '1';
				state_in 		<= 2;

			when 2 =>
				LED(13) <= '1';
				if write_done_s = '1' then
					state_in <= 3;
				end if ;
		
			when 3 =>
				LED(12) <= '1';
				read_addr_s 	<= (others => '0');
				read_start_s 	<= '1';
				state_in 		<= 4;

			when 4 =>
				LED(11) <= '1';
				if read_done_s = '1' then
					state_in <= 5;
				end if ;

			when others =>
				LED(10) <= '1';
				LED(9 downto 0) <= read_data_s(9 downto 0);
		
		end case ;
	end process;

	reg_proc : process(CLK)
	begin
		if rising_edge(CLK) then
			state <= state_in;
		end if;
	end process;	

end architecture ; -- arch