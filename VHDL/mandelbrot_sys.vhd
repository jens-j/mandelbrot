library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity mandelbrot_sys is
	port (
		clk 			: in  std_logic;
		btnCpuReset 	: in  std_logic; 
		-- VGA ports
		Vsync			: out std_logic;
		Hsync			: out std_logic;
		vgaRed			: out std_logic_vector(3 downto 0);
		vgaGreen		: out std_logic_vector(3 downto 0);
		vgaBlue 		: out std_logic_vector(3 downto 0);
		-- RAM ports
		RAMWAIT 		: in  std_logic;
		RAMOEN 			: out std_logic;
		RAMCRE 			: out std_logic;
		RAMADVN 		: out std_logic;
		RAMWEN 			: out std_logic;
		RAMCEN 			: out std_logic;
		RAMUBN 			: out std_logic;
		RAMLBN 			: out std_logic;
		RAMCLK 			: out std_logic;
		MEMADR  		: out std_logic_vector(22 downto 0);
		MEMDB 			: inout std_logic_vector(15 downto 0);
		-- snes controller port
		JA 				: inout  std_logic_vector(7 downto 0);
		-- IO
		SW 				: in  std_logic_vector(15 downto 0);
		LED 			: out std_logic_vector(15 downto 0);
		SEG 			: out std_logic_vector(6 downto 0);
		AN 				: out std_logic_vector(7 downto 0)
	) ;
end entity ; -- mandelbrot_sys


architecture arch of mandelbrot_sys is

	signal reset 			: std_logic;
	-- clk 
	signal clk_slow_s		: std_logic := '0';
	signal clk_slower_s		: std_logic := '0';
	signal RAM_clk_s 		: std_logic := '0';
	signal VGA_clk_s 		: std_logic := '0';
	signal kernel_clk_s 	: std_logic := '0';
	signal system_clk_s   	: std_logic := '0';
	-- RAM controller signals
	signal write_data_s 	: data_vector_t;
	signal write_addr_s 	: std_logic_vector(22 downto 0) := "000" & x"00000";
	signal write_start_s	: std_logic := '0';
	signal write_ready_s 	: std_logic := '0';
	signal read_addr_s 		: std_logic_vector(22 downto 0) := "000" & x"00000";
	signal read_start_s 	: std_logic := '0';
	signal read_data_s		: data_vector_t;
	signal read_ready_s 	: std_logic := '0';

	signal iterations_s  	: integer range 0 to 65535;
	signal buttons_s		: std_logic_vector(11 downto 0);
	signal color_set_s 		: integer range 0 to COLOR_SET_N;
	signal julia_s 			: std_logic;

begin

	clk_gen : entity work.main_clk_gen
	port map(
	  CLK_IN1          => clk,
	  system_clk       => system_clk_s,
	  VGA_clk          => VGA_clk_s,
	  kernel_clk       => kernel_clk_s
	);
	
	controller : entity work.RAM_controller 
	port map(
		clk 		=> system_clk_s,
		RAM_clk 	=> RAM_clk_s,
		burst_en 	=> '1',
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

	calc_sub : entity work.calculation_subsystem
	port map(
		clk 			=> kernel_clk_s, -- system_clk_s,
		kernel_clk 		=> kernel_clk_s,
		RAM_clk 		=> RAM_clk_s,
		reset 			=> reset,
		clk_en 			=> SW(0),
		-- RAM signals
		RAM_write_data 	=> write_data_s,
		RAM_write_addr 	=> write_addr_s,
		RAM_write_start	=> write_start_s,
		RAM_write_ready => write_ready_s,
		-- snes controller 
		JA 				=> JA,
		-- IO
		SEG 			=> SEG,
		AN 				=> AN,
		-- to display system
		iterations 		=> iterations_s,
		buttons 		=> buttons_s,
		color_set 		=> color_set_s,
		julia 			=> julia_s
	);

	display_subsystem : entity work.display_subsystem 
	port map(
		VGA_clk			=> VGA_clk_s,
		RAM_clk 		=> RAM_clk_s,
		reset 			=> reset,
		-- VGA signals
		Vsync			=> Vsync,
		Hsync			=> Hsync,
		vgaRed			=> vgaRed,
		vgaGreen		=> vgaGreen,
		vgaBlue 		=> vgaBlue,
		-- RAM read port signals
		RAM_read_addr 	=> read_addr_s,
		RAM_read_start 	=> read_start_s,
		RAM_read_data	=> read_data_s,
		RAM_read_ready  => read_ready_s,
		-- IO
		SW 				=> SW(15 downto 11),
		iterations 		=> iterations_s,
		color_set 		=> color_set_s
	) ;

	reset <= not btnCpuReset or buttons_s(8);

	LED <= (15 downto 1 => '0') & julia_s;


	-- kernel_clk_s 	<= clk_slower_s;
	-- RAM_clk_s 		<= clk;
	-- VGA_clk_s		<= clk_slower_s;


	-- clk_div_slow : process( clk )
	-- begin
	-- 	if rising_edge(clk) then
	-- 		clk_slow_s <= not clk_slow_s;	
	-- 	end if ;
	-- end process ; -- clk_div

	-- clk_div_slower : process( clk_slow_s )
	-- begin
	-- 	if rising_edge(clk_slow_s) then
	-- 		clk_slower_s <= not clk_slower_s;
	-- 	end if ;
	-- end process ; -- 


end architecture ; -- arch