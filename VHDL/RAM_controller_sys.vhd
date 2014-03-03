library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;

entity RAM_controller_sys is
  port (
  	clk 		: in  std_logic;
	RAMWAIT 	: in  std_logic;
	RAMOEN 		: out std_logic;
	RAMCLK 		: out std_logic;
	RAMCRE 		: out std_logic;
	RAMADVN 	: out std_logic;
	RAMWEN 		: out std_logic;
	RAMCEN 		: out std_logic;
	RAMLBN 		: out std_logic;
	RAMUBN 		: out std_logic;
	MEMADR  	: out std_logic_vector(22 downto 0);
	MEMDB 		: inout std_logic_vector(15 downto 0);
	-- IO
	btnCpuReset	: in  std_logic;
	SW 			: in  std_logic_vector(15 downto 0);
	LED 		: out std_logic_vector(15 downto 0)
  	) ;
end entity ; -- RAM_controller_tb

architecture behavioural of RAM_controller_sys is

	component RAM_controller is
 	port (
		RAM_clk 	: in  std_logic;
		burst_en 	: in  std_logic; -- set to change to burst mode
		-- write port signals
		write_data 	: in  data_vector_t;
		write_addr 	: in  std_logic_vector(22 downto 0);
		write_start	: in  std_logic;
		write_ready : out std_logic;
		-- read port
		read_addr 	: in  std_logic_vector(22 downto 0);
		read_start 	: in  std_logic;
		read_ready  : out std_logic;
		read_data	: out data_vector_t;
		-- RAM signal
		RAMWAIT 	: in  std_logic;
		RAMOEN 		: out std_logic;
		RAMCRE 		: out std_logic;
		RAMADVN 	: out std_logic;
		RAMWEN 		: out std_logic;
		RAMCEN 		: out std_logic;
		RAMUBN 		: out std_logic;
		RAMLBN 		: out std_logic;
		RAMCLK 		: out std_logic;
		MEMADR  	: out std_logic_vector(22 downto 0);
		MEMDB 		: inout std_logic_vector(15 downto 0)
  	) ;
	end component ; -- RAM_controller


	signal reset_s 			: std_logic := '0';
	signal burst_en_s 		: std_logic := '0';
	signal write_data_s 	: data_vector_t;
	signal write_addr_s 	: std_logic_vector(22 downto 0) := "000" & x"00000";
	signal write_start_s	: std_logic := '0';
	signal write_ready_s 	: std_logic := '0';
	signal read_addr_s 		: std_logic_vector(22 downto 0) := "000" & x"00000";
	signal read_start_s 	: std_logic := '0';
	signal read_data_s		: data_vector_t;
	signal read_ready_s 	: std_logic := '0';
  	signal state 			: integer := 0;
  	signal count 			: integer := 0;
  	signal ram_clk_s 		: std_logic := '0';
begin



	controller : RAM_controller 
	port map(
		RAM_clk 	=> ram_clk_s,
		burst_en 	=> burst_en_s,
		-- write port signals
		write_data 	=> write_data_s,
		write_addr 	=> write_addr_s,
		write_start	=> write_start_s,
		write_ready => write_ready_s,
		-- read port
		read_addr 	=> read_addr_s,
		read_start 	=> read_start_s,
		read_data	=> read_data_s,
		read_ready 	=> read_ready_s,
		-- RAM signal
		RAMWAIT 	=> RAMWAIT,
		RAMOEN 		=> RAMOEN,
		RAMCLK 		=> RAMCLK,
		RAMCRE 		=> RAMCRE,
		RAMADVN 	=> RAMADVN,
		RAMWEN 		=> RAMWEN,
		RAMCEN 		=> RAMCEN,
		RAMUBN 		=> RAMUBN,
		RAMLBN 		=> RAMLBN,
		MEMADR  	=> MEMADR,
		MEMDB 		=> MEMDB
	);


	init_data0 : for i in 0 to 31 generate
		--write_data_s(i) <= x"0f0f";
		write_data_s(i) <= std_logic_vector(to_unsigned(i,16));
	end generate;

	test : process(ram_clk_s)
	begin


		if rising_edge(ram_clk_s) then
			if btnCpuReset = '0' then
				state <= 0;
				led <= x"AAAA";
			else
				--led <= x"5555";
				case( state ) is

					-- when 0 =>
					-- 	if btnCpuReset = '1' then
					-- 		read_start_s 	<= '1';
					-- 		state 			<= 1; 
					-- 	end if ;
					-- 	LED <= '1' & (14 downto 0 => '0');

					-- when others =>
					-- 	read_start_s 	<= '0';
					-- 	led 			<= "01" & read_data_s(0)(13 downto 0);
					-- 	if btnCpuReset = '0' then
					-- 		state <= 0;
					-- 	end if ;

					when 0 =>
						--if count = 16050 then
							--write_start_s <= '1';
							burst_en_s <= '1';
							state <= 1;	
						--else
							--count <= count + 1;
						--end if ;
						

					when 1 =>
						--write_start_s <= '0';
						burst_en_s <= '0';
						count <= 0;
						state <= 2;

					when 2 =>
						if count = 100 then
							write_start_s <= '1';
							count <= 0;
							state <= 3;
						else
							count <= count + 1;
							state <= 2;
						end if ;

					when 3 =>
						write_start_s <= '0';
						if count = 100 then
							read_start_s 	<= '1';
							state 		<= 4;
						else
							count <= count + 1;
						end if ;

					when others =>
						read_start_s 	<= '0';
						state  			<= 4;
						led 			<= read_data_s(to_integer(unsigned(SW(4 downto 0))));
						if sw(15) = '1' then
							count <= 0;
							state <= 2;
						end if ;

				end case ;
			end if;
		end if ;


	end process;

	clk_proc : process(clk)
	begin
		if rising_edge(clk) then
			ram_clk_s <= not ram_clk_s;
		end if ;
	end process;


end architecture ; -- behavioural