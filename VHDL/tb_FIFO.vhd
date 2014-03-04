library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity tb_FIFO is
end entity ; -- tb_FIFO


architecture arch of tb_FIFO is
	


	component FIFO is
	generic(
		FIFO_LOG_DEPTH 	: integer := 4;
		FIFO_WIDTH 		: integer := 16
	);
	port(
		reset 		: in  std_logic;
		-- read side ports
		rclk 		: in  std_logic;
		rinc 		: in  std_logic;
		rempty 		: out std_logic;
		rdata 		: out std_logic_vector(FIFO_WIDTH-1 downto 0);
		-- write side port
		wclk 		: in  std_logic;
		winc 		: in  std_logic;
		wdata 		: in  std_logic_vector(FIFO_WIDTH-1 downto 0);
		wfull 		: out std_logic
	) ;
	end component ; -- FIFO

	signal reset_s 	: std_logic := '0';
	signal rclk_s 	: std_logic := '0';
	signal rinc_s 	: std_logic := '0';
	signal rempty_s : std_logic := '0';
	signal rdata_s 	: std_logic_vector(15 downto 0) := (others => '0');
	signal wclk_s 	: std_logic := '0';
	signal winc_s 	: std_logic := '0';
	signal wdata_s 	: std_logic_vector(15 downto 0) := (others => '0');
	signal wfull_s 	: std_logic := '0';
	signal count 	: integer := 0;
	signal next_winc_s	: std_logic;
	signal next_rinc_s 	: std_logic;

begin

	UUT : FIFO 
	port map(
		reset 		=> reset_s,
		-- read side ports
		rclk 		=> rclk_s,
		rinc 		=> rinc_s,
		rempty 		=> rempty_s,
		rdata 		=> rdata_s,
		-- write side port
		wclk 		=> wclk_s,
		winc 		=> winc_s,
		wdata 		=> wdata_s,
		wfull 		=> wfull_s
	);

	reset_s <= 	'1' after 0 ns,
				'0' after 100 ns;
	rclk_s <= not rclk_s after 7 ns;
	wclk_s <= not wclk_s after 18 ns;



	wdata_s <= std_logic_vector(to_unsigned(count,16));
	next_winc_s <= not wfull_s;
	next_rinc_s <= not rempty_s;





	clk_proc : process(wclk_s)
	begin
		if rising_edge(wclk_s) then
			if reset_s = '0' and wfull_s = '0' then
				if count = 2**16-1 then
					count <= 0;
				else		
					count <= count + 1;
				end if;
			end if ;
			winc_s <= next_winc_s;
			rinc_s <= next_rinc_s;
		end if ;
	end process;

end architecture ; -- arch