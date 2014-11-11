library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FIFO_tb is
	port(
			clk	: in std_logic
		);
end entity ; -- FIFO_tb

architecture arch of FIFO_tb is

	signal reset 		: std_logic;
	-- read side ports
	signal rclk 		: std_logic;
	signal rinc 		: std_logic;
	signal rempty 		: std_logic;
	signal rdata 		: std_logic_vector(640*16-1 downto 0);
	-- write side port
	signal wclk 		: std_logic;
	signal winc 		: std_logic;
	signal wdata 		: std_logic_vector(640*16-1 downto 0);
	signal wfull 		: std_logic;

begin

UUT : entity work.FIFO
	generic map(
		FIFO_LOG_DEPTH 	=> 4,
		FIFO_WIDTH 		=> 640*16
	)
	port map(
		reset 		=> reset,
		-- read side ports
		rclk 		=> clk,
		rinc 		=> rinc,
		rempty 		=> rempty,
		rdata 		=> rdata,
		-- write side port
		wclk 		=> clk,
		winc 		=> winc,
		wdata 		=> wdata,
		wfull 		=> wfull
	) ;



end architecture ; -- arch