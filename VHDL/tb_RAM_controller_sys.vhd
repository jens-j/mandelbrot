library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity tb_RAM_controller_sys is
end entity ; -- tb_RAM_controller_sys


architecture arch of tb_RAM_controller_sys is

	component RAM_controller_sys is
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
	end component ; -- RAM_controller_tb

  	signal clk_s 			: std_logic := '0';
	signal RAMWAIT_s 		: std_logic := '0';
	signal RAMOEN_s 		: std_logic := '0';
	signal RAMCLK_s 		: std_logic := '0';
	signal RAMCRE_s			: std_logic := '0';
	signal RAMADVN_s 		: std_logic := '0';
	signal RAMWEN_s 		: std_logic := '0';
	signal RAMCEN_s 		: std_logic := '0';
	signal RAMLBN_s 		: std_logic := '0';
	signal RAMUBN_s 		: std_logic := '0';
	signal MEMADR_s  		: std_logic_vector(22 downto 0);
	signal MEMDB_s 			: std_logic_vector(15 downto 0);
	-- IO
	signal SW_s 			: std_logic_vector(15 downto 0) := x"8000";
	signal btnCpuReset_s	: std_logic;
	signal LED_s 			: std_logic_vector(15 downto 0);

begin

	UUT : RAM_controller_sys
	port map(
		clk 		=> clk_s,
		RAMWAIT 	=> RAMWAIT_s,
		RAMOEN 		=> RAMOEN_s,
		RAMCLK 		=> RAMCLK_s,
		RAMCRE 		=> RAMCRE_s,
		RAMADVN 	=> RAMADVN_s,
		RAMWEN 		=> RAMWEN_s,
		RAMCEN 		=> RAMCEN_s,
		RAMLBN 		=> RAMLBN_s,
		RAMUBN 		=> RAMUBN_s,
		MEMADR  	=> MEMADR_s,
		MEMDB 		=> MEMDB_s,
		-- IO
		SW 			=> SW_s,
		btnCpuReset	=> btnCpuReset_s,
		LED 		=> LED_s
	);

	clk_s <= not clk_s after 5 ns;

	btnCpuReset_s <=	'0' after 0 ns,
						'1' after 200 ns,
						'0' after 180000 ns,
						'1' after 182000 ns;

	wait_proc : process
	begin
		wait until RAMCEN_s'event and RAMCEN_s = '0';
		RAMWAIT_s <=  	'1', '0' after 50 ns; 	
	end process;


end architecture ; -- arch