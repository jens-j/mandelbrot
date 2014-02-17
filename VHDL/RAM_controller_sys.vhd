library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;

entity RAM_controller_sys is
  port (
  	CLK 		: in  std_logic;
	RAMWAIT 	: in  std_logic;
	RAMCLK 		: out std_logic;
	RAMCRE 		: out std_logic;
	RAMADVN 	: out std_logic;
	RAMWEN 		: out std_logic;
	RAMCEN 		: out std_logic;
	MEMADR  	: out std_logic_vector(22 downto 0);
	MEMDB 		: inout std_logic_vector(15 downto 0);
	LED 		: out std_logic_vector(15 downto 0);
	-- constants
	RAMOEN 		: out std_logic;
	RAMLBN 		: out std_logic;
	RAMUBN 		: out std_logic;
	-- buttons
	btnCpuReset		: in  std_logic;
  	btnC			: in  std_logic;
  	btnU			: in  std_logic;
  	btnL			: in  std_logic;
  	btnR			: in  std_logic;
  	btnD			: in  std_logic
  	) ;
end entity ; -- RAM_controller_tb

architecture behavioural of RAM_controller_sys is

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
		RAMCEN 		: out std_logic;
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
		CLK_OUT3 		  : out    std_logic;
		-- Status and control signals
		RESET             : in     std_logic;
		LOCKED            : out    std_logic
	 );
	end component;

	component button_debouncer is
	port (
		CLK 			: in  std_logic; -- 100MHz
		-- NEXYS 4 buttons
		btnCpuReset		: in  std_logic;
		btnC			: in  std_logic;
		btnU			: in  std_logic;
		btnL			: in  std_logic;
		btnR			: in  std_logic;
		btnD			: in  std_logic;
		-- debounced outputs
		btnCpuReset_d 	: out std_logic;
		btnC_d			: out std_logic;
		btnU_d 			: out std_logic;
		btnL_d			: out std_logic;
		btnR_d			: out std_logic;
		btnD_d			: out std_logic
	) ;
	end component ; -- button_debouncer

	--signal clk_s 			: std_logic := '0';
	signal ram_clk_s		: std_logic;
	signal ram_out_clk_s	: std_logic;
	signal btn_clk_s 		: std_logic;
	signal ram_ready_s		: std_logic; 
	signal locked_s			: std_logic;
	signal reset_s 			: std_logic := '0';
	signal write_data_s 	: data_vector_t;
	signal write_addr_s 	: std_logic_vector(17 downto 0);
	signal write_start_s	: std_logic := '0';
	signal read_addr_s 		: std_logic_vector(17 downto 0);
	signal read_start_s 	: std_logic := '0';
	signal read_data_s		: data_vector_t;
	signal ramwait_s 		: std_logic;
	signal count 			: integer := 0;
	signal btnCpuReset_s 	: std_logic;
  	signal btnC_s			: std_logic;
  	signal btnC_s2			: std_logic;   
  	signal btnU_s 			: std_logic;
  	signal btnL_s			: std_logic;
  	signal btnR_s			: std_logic;
  	signal btnD_s			: std_logic;
  	signal state 			: integer := 0;
  	signal new_state 		: integer := 0;
  	signal debug 		 	: std_logic;

begin

	clock_gen : RAM_clock_gen
	port map(
		CLK_IN1 	=> CLK,
		CLK_OUT1 	=> ram_clk_s,
		CLK_OUT2 	=> ram_out_clk_s,
		CLK_OUT2_CE => ram_ready_s,
		CLK_OUT3 	=> btn_clk_s,
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
		RAMWAIT 	=> RAMWAIT,
		RAMCRE 		=> RAMCRE,
		RAMADVN 	=> RAMADVN,
		RAMWEN 		=> RAMWEN,
		RAMCEN 		=> debug,
		MEMADR  	=> MEMADR,
		MEMDB 		=> MEMDB
	);

	btn_in : button_debouncer
	port map(
		CLK 			=> btn_clk_s,
		btnCpuReset		=> btnCpuReset,
		btnC			=> btnC,
		btnU			=> btnU,
		btnL			=> btnL,
		btnR			=> btnR,
		btnD			=> btnD,
		-- debounced outputs
		btnCpuReset_d 	=> btnCpuReset_s,
		btnC_d			=> btnC_s,
		btnU_d 			=> btnU_s,
		btnL_d			=> btnL_s,
		btnR_d			=> btnR_s,
		btnD_d			=> btnD_s
	);

	-- clk_s <= not clk_s after 5 ns;


	RAMOEN 	<= '0';
	RAMLBN 	<= '0';
	RAMUBN 	<= '0';
	RAMCLK  <= ram_out_clk_s;
	LED(15) <= '1';

	test : process(count,btnC_s,btnC_s2,state,write_data_s,write_start_s,read_start_s,read_data_s,btnR_s,RAMWAIT)
	begin
		if count >= 10000 and btnC_s = '1' and btnC_s2 = '0' and state = 0 then
			LED(14 downto 12) <= "100";
			for i in 0 to 31 loop
				write_data_s(i) <= std_logic_vector(to_unsigned(i,16));
			end loop;
			write_addr_s 		<= (others => '0');
			write_start_s		<= '1';
			LED(7 downto 0)		<= write_data_s(15)(7 downto 0); 
			new_state 			<= 1;
		end if;


		if write_start_s = '0' and btnC_s = '1' and btnC_s2 = '0' and state = 1 then
			LED(14 downto 12) 	<= "010";
			read_addr_s			<= (others => '0');
			read_start_s		<= '1';
			new_state 			<= 2;
		end if;

		if read_start_s = '0' and btnC_s = '1' and btnC_s2 = '0' and state = 2 then
			LED(14 downto 12) 	<= "001";
			LED(7 downto 0) 	<= read_data_s(15)(7 downto 0);
			new_state 		 	<= 3;
		end if;

		LED(11 downto 8) <= write_start_s & read_start_s & btnR_s & RAMWAIT;
		RAMCEN 	<= btnR_s;

	end process;

	reg_proc : process(btn_clk_s)
	begin
		if rising_edge(btn_clk_s) then
			if count < 10000 then
				count <= count+1;
			end if ;
			btnC_s2 <= btnC_s;
			state <= new_state;
		end if;
	end process;

end architecture ; -- behavioural