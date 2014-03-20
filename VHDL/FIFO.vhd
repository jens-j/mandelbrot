library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FIFO is
	generic(
		FIFO_LOG_DEPTH 	: integer := 4;
		FIFO_WIDTH 		: integer := 640*16
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
end entity ; -- FIFO


architecture arch of FIFO is

	signal write_en_s 	: std_logic;
	signal raddr_s 		: std_logic_vector(FIFO_LOG_DEPTH-1 downto 0);
	signal waddr_s 		: std_logic_vector(FIFO_LOG_DEPTH-1 downto 0);
	signal rinc_en 	 	: std_logic;
	signal winc_en 		: std_logic;
	signal rptr 		: std_logic_vector(FIFO_LOG_DEPTH downto 0);
	signal wptr 		: std_logic_vector(FIFO_LOG_DEPTH downto 0);
	signal rgnext		: std_logic_vector(FIFO_LOG_DEPTH downto 0);
	signal wgnext		: std_logic_vector(FIFO_LOG_DEPTH downto 0);
	signal wq1_rptr 	: std_logic_vector(FIFO_LOG_DEPTH downto 0);
	signal wq2_rptr 	: std_logic_vector(FIFO_LOG_DEPTH downto 0);
	signal rq1_wptr 	: std_logic_vector(FIFO_LOG_DEPTH downto 0);
	signal rq2_wptr 	: std_logic_vector(FIFO_LOG_DEPTH downto 0);
	signal wfull_s 		: std_logic;
	signal rempty_s		: std_logic;
	signal wfull_r 		: std_logic;
	signal rempty_r 	: std_logic;

begin

	fifo_mem : entity work.FIFO_memory
		generic map(
			MEM_WIDTH 		=> FIFO_WIDTH,
			MEM_LOG_DEPTH 	=> FIFO_LOG_DEPTH
		)
		port map(
			clk 		=> wclk,
			write_en 	=> write_en_s,
			raddr 		=> raddr_s,
			waddr 		=> waddr_s,
			wdata 		=> wdata,
			rdata 		=> rdata
		);

	read_counter : entity work.dual_grey_counter
		generic map(
			WIDTH 		=> FIFO_LOG_DEPTH+1
		)
		port map(
			clk 		=> rclk,
			reset 		=> reset,
			inc 		=> rinc,
			inc_en 		=> rinc_en,
			bin 		=> raddr_s,
			ptr 		=> rptr,
			gnext 		=> rgnext
		);

	write_counter : entity work.dual_grey_counter
		generic map(
			WIDTH 		=> FIFO_LOG_DEPTH+1
		)
		port map(
			clk 		=> wclk,
			reset 		=> reset,
			inc 		=> winc,
			inc_en 		=> winc_en,
			bin 		=> waddr_s,
			ptr 		=> wptr,
			gnext 		=> wgnext
		);


	-- internal signals
	rempty_s 	<= 	'1' when rgnext = rq2_wptr else
					'0';
	wfull_s 	<=  '1' when 	not (wgnext(FIFO_LOG_DEPTH) = wq2_rptr(FIFO_LOG_DEPTH)) and 
								not (wgnext(FIFO_LOG_DEPTH-1) = wq2_rptr(FIFO_LOG_DEPTH-1)) and 
								wgnext(FIFO_LOG_DEPTH-2 downto 0) = wq2_rptr(FIFO_LOG_DEPTH-2 downto 0) else
					'0';  

	-- sub component ports
	write_en_s 	<= winc and not wfull_r;
	rinc_en 	<= not rempty_r;
	winc_en 	<= not wfull_r;

	-- FIFO output ports 
	rempty 	<= rempty_s;
	wfull 	<= wfull_s;

	-- wprt to rclk synchronization
	rclk_proc : process(rclk)
	begin
		if rising_edge(rclk) then
			rq2_wptr <= rq1_wptr;
			rq1_wptr <= wptr;
			rempty_r <= rempty_s;
		end if;
	end process;

	-- rptr to wclk synchronization
	wclk_proc : process(wclk)
	begin
		if rising_edge(wclk) then
			wq2_rptr <= wq1_rptr;
			wq1_rptr <= rptr;	
			wfull_r  <= wfull_s;
		end if;
	end process;



end architecture ; -- arch