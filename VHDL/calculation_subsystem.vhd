library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity calculation_subsystem is
	port (
		clk 			: in  std_logic;
		kernel_clk 		: in  std_logic;
		RAM_clk 		: in  std_logic;	
		reset 			: in  std_logic;
		-- RAM signals
		RAM_write_data 	: out  data_vector_t;
		RAM_write_addr 	: out  std_logic_vector(22 downto 0);
		RAM_write_start	: out  std_logic;
		RAM_write_ready : in   std_logic;
		-- snes controller port
		JA 				: inout   std_logic_vector(7 downto 0)
	) ;
end entity ; -- calculation_subsystem


architecture behavioural of calculation_subsystem is

	type state_t is (ramw0,ramw1);

	type calculation_subsystem_reg is record
		state 		: state_t;
		line_data 	: line_vector_t;
		count 		: integer range 0 to 31;
		address		: std_logic_vector(22 downto 0);
		rempty 		: std_logic;
	end record;

  	-- scheduler signals
  	signal line_valid_s,next_line_s	: std_logic := '0';
  	signal line_x_s,line_y_s 		: std_logic_vector(63 downto 0);
  	signal line_n_s					: integer range 0 to DISPLAY_HEIGHT-1 := 0;
  	-- collector signals
  	signal ack_s, done_s 			: std_logic := '0';
  	signal out_line_n_s 			: integer range 0 to DISPLAY_HEIGHT-1 := 0;
  	signal result_s 				: line_vector_t;	
  	-- fifo signals
 	signal rinc_s, winc_s, rempty_s, wfull_s, rempty_line_s, wfull_line_s : std_logic;
 	signal rdata_s, wdata_s			: std_logic_vector(DISPLAY_WIDTH*16-1 downto 0);
 	signal rdata_line_s, wdata_line_s : std_logic_vector(9 downto 0);
 	-- fifo to ram signals
 	signal RAM_addr, next_RAM_addr 	: std_logic_vector(22 downto 0) := (others => '0');	
 	-- user input signals
 	signal buttons_s 				: std_logic_vector(11 downto 0);
 	signal p_s 						: std_logic_vector(63 downto 0);
 	signal center_x_s 				: std_logic_vector(63 downto 0);
 	signal center_y_s 				: std_logic_vector(63 downto 0);


 	signal r,r_in : calculation_subsystem_reg;

begin

	controller_interface : entity work.snes_controller_interface
	port map(
		clk			=> clk,
		buttons		=> buttons_s,
		JA 			=> JA
	);

	user_input : entity work.user_input_controller
	port map(
		clk 		=> clk,
		buttons 	=> buttons_s,
		p 			=> p_s,
		center_x 	=> center_x_s,
		center_y 	=> center_y_s
	);

	line_feeder : entity work.line_feeder
	port map(
		clk 		=> kernel_clk,
		reset 		=> reset,
		rinc 		=> next_line_s,
		center_x 	=> center_x_s,
		center_y 	=> center_y_s,
		p 			=> p_s,
		line_valid 	=> line_valid_s,
		line_x 		=> line_x_s,
		line_y 		=> line_y_s,
		line_n 		=> line_n_s
	);

	kernel : entity work.mandelbrot_kernel  
	port map (
      	clk   		=> kernel_clk,
      	max_iter 	=> 255,

		in_valid 	=> line_valid_s,
		c0_real 	=> line_x_s,
		c0_imag 	=> line_y_s,
		in_p 		=> p_s,
		in_line_n 	=> line_n_s,
		in_inc 		=> next_line_s,
		ack 		=> ack_s,
		done 		=> winc_s,
		out_line_n 	=> out_line_n_s,
		result 		=> result_s
    );

	data_fifo_buff : entity work.FIFO
	generic map(
		FIFO_LOG_DEPTH 	=> 3,
		FIFO_WIDTH 		=> DISPLAY_WIDTH*16
	)
	port map(
		reset 		=> reset,
		-- read side ports
		rclk 		=> RAM_clk,
		rinc 		=> rinc_s,
		rempty 		=> rempty_s,
		rdata 		=> rdata_s,
		-- write side port
		wclk 		=> kernel_clk,
		winc 		=> winc_s,
		wdata 		=> wdata_s,
		wfull 		=> wfull_s
	);

	line_addr_fifo_buff : entity work.FIFO
	generic map(
		FIFO_LOG_DEPTH 	=> 3,
		FIFO_WIDTH 		=> 10
	)
	port map(
		reset 		=> reset,
		-- read side ports
		rclk 		=> RAM_clk,
		rinc 		=> rinc_s,
		rempty 		=> rempty_line_s,
		rdata 		=> rdata_line_s,
		-- write side port
		wclk 		=> kernel_clk,
		winc 		=> winc_s,
		wdata 		=> wdata_line_s,
		wfull 		=> wfull_line_s
	);


	ack_s <= winc_s and not wfull_s;

	wdata_line_s <= std_logic_vector(to_unsigned(out_line_n_s,10));



	comb_proc : process( r, rempty_s, result_s, rdata_s, rdata_line_s, RAM_write_ready )
		variable temp1,temp2 : std_logic_vector(22 downto 0);
	begin
		for i in 0 to DISPLAY_WIDTH-1 loop
			wdata_s(16*(i+1)-1 downto 16*i) <= result_s(i);
		end loop;


		r_in <= r;
		r_in.rempty <= rempty_s;
		rinc_s <= '0';
		RAM_write_start <= '0';
		RAM_write_addr <= (others => '0');
		for i in 0 to 31 loop
			RAM_write_data(i) <= (others => '0');
		end loop ; -- identifier

		case (r.state) is
			when ramw0 => 
				if r.rempty = '0' then
					for i in 0 to DISPLAY_WIDTH-1 loop 
						r_in.line_data(i) <= rdata_s(16*(i+1)-1 downto 16*i);
					end loop;
					temp1 := (22 downto 19 => '0')&rdata_line_s(9 downto 0)&(8 downto 0 => '0');
					temp2 := (22 downto 17 => '0')&rdata_line_s(9 downto 0)&(6 downto 0 => '0');
					r_in.address <= std_logic_vector(unsigned(temp1) + unsigned(temp2)); -- address is line_n * 640. which is line_n<<9 + line_n<<7
					r_in.count <= 0;
					rinc_s <= '1';
					r_in.state <= ramw1;
				end if ;

			when ramw1 =>
				if RAM_write_ready = '1' then
					for i in 0 to 31 loop
						RAM_write_data(i) <= r.line_data(32*r.count+i);
					end loop ; -- identifier
					RAM_write_addr <= r.address;
					RAM_write_start <= '1';
					if r.count = DISPLAY_WIDTH/32-1 then
						r_in.state <= ramw0;
					else
						r_in.count <= r.count + 1;
						r_in.address <= std_logic_vector(unsigned(r.address) + 32);
					end if ;
				end if ;
		end case;
	end process ; -- comb_proc

	clk_proc : process(RAM_clk)
	begin
		if rising_edge(RAM_clk) then
		 	r <= r_in;
		end if ; 
	end process;


end architecture ; -- arch