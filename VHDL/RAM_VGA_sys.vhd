library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity RAM_VGA_sys is
port (
	clk 			: in  std_logic;
	btnCpuReset 	: in  std_logic;
	-- VGA signals
	Vsync			: out std_logic;
	Hsync			: out std_logic;
	vgaRed			: out std_logic_vector(3 downto 0);
	vgaGreen		: out std_logic_vector(3 downto 0);
	vgaBlue 		: out std_logic_vector(3 downto 0);
	-- RAM signals
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
	MEMDB 			: inout std_logic_vector(15 downto 0)
) ;
end entity ; -- RAM_VGA_sys


architecture arch of RAM_VGA_sys is

	signal ram_clk_s 		: std_logic := '0';
	signal vga_clk_s 		: std_logic := '0';
	signal reset 			: std_logic := '0';
	signal write_data_s 	: data_vector_t;
	signal write_addr_s 	: std_logic_vector(22 downto 0) := "000" & x"00000";
	signal write_start_s	: std_logic := '0';
	signal write_ready_s 	: std_logic := '0';
	signal read_addr_s 		: std_logic_vector(22 downto 0) := "000" & x"00000";
	signal read_start_s 	: std_logic := '0';
	signal read_data_s		: data_vector_t;
	signal read_ready_s 	: std_logic := '0';

begin

	ram_controller : entity work.RAM_controller 
	port map(
		RAM_clk 	=> ram_clk_s,
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

	ram_feeder : entity work.RAM_feed
	port map(
		RAM_clk 		=> ram_clk_s,
		RAM_write_data 	=> write_data_s,
		RAM_write_addr 	=> write_addr_s,
		RAM_write_start	=> write_start_s,
		RAM_write_ready => write_ready_s
	);

	display_subsystem : entity work.display_subsystem 
	port map(
		VGA_clk			=> vga_clk_s,
		RAM_clk 		=> ram_clk_s,
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
		RAM_read_ready  => read_ready_s
	) ;

	reset <= not btnCpuReset;

	ram_clk_div : process( clk )
	begin
		if rising_edge(clk) then
			ram_clk_s <= not ram_clk_s;
		end if ;
	end process ; -- clk_div

	vga_clk_div : process( ram_clk_s )
	begin
		if rising_edge(ram_clk_s) then
			vga_clk_s <= not vga_clk_s;
		end if ;
	end process ; -- clk_div


end architecture ; -- arch