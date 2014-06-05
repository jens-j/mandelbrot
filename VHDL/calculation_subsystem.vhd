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
		clk_en 			: in  std_logic;
		-- RAM signals
		RAM_write_data 	: out  data_vector_t;
		RAM_write_addr 	: out  std_logic_vector(22 downto 0);
		RAM_write_start	: out  std_logic;
		RAM_write_ready : in   std_logic;
		-- snes controller port
		JA 				: inout   std_logic_vector(7 downto 0);
		-- IO
		SEG 			: out std_logic_vector(6 downto 0);
		AN 				: out std_logic_vector(7 downto 0);
		-- signal to display system
		calc_to_disp 	: out calc_to_disp_t;
		-- other IO
		buttons 		: out std_logic_vector(11 downto 0);
		julia 			: out std_logic
	) ;
end entity ; -- calculation_subsystem


architecture behavioural of calculation_subsystem is


	type state_t is (ramw0,ramw1);

	type calculation_subsystem_reg is record
		state 				: state_t;
		chunk_data 			: chunk_vector_t;
		count 				: integer range 0 to 31;
		address				: std_logic_vector(22 downto 0);
		rempty 				: std_logic;
		prev_chunk_valid 	: std_logic;
		framerate 			: std_logic_vector(15 downto 0);
		prev_framerate 		: std_logic_vector(15 downto 0);
		fps_counter 		: integer range 0 to 99999999;
	end record;

	-- type kernel_io_t is record
	-- 	-- scheduler signals
	--   	chunk_valid		: std_logic;
	--   	chunk_x 		: std_logic_vector(63 downto 0);
	--   	chunk_y 		: std_logic_vector(63 downto 0);
 -- 	 	p 				: std_logic_vector(63 downto 0);
 -- 		chunk_n			: integer range 0 to DISPLAY_SIZE/CHUNK_SIZE-1;
	--   	req_chunk		: std_logic;
	--   	-- collector signals
	--    	ack				: std_logic;
	--   	done			: std_logic;
	--   	out_chunk_n		: std_logic_vector(13 downto 0);
	--   	result			: chunk_vector_t;	
	-- end record;

	type kernel_io_vector_t is array (KERNEL_N-1 downto 0) of kernel_io_t;

	
	constant RESULT_INIT : chunk_vector_t 	:= (others => (others => 'Z'));
	constant CHUNK_INIT : chunk_vector_t 	:= (others => (others => '0'));
	constant IO_INIT : kernel_io_t 			:=  (chunk_valid => '0',
												julia => '0',
												chunk_x => (others => '0'),
												chunk_y => (others => '0'),
												c_x => (others =>'0'),
												c_y => (others =>'0'),
												p => (others => '0'),
												chunk_n => 0,
												req_chunk => '0',
												ack => '0',
												done => '0',
												out_chunk_n => (others => '0'),
												result => CHUNK_INIT
												);
	constant REG_INIT : calculation_subsystem_reg := (ramw0,CHUNK_INIT,0,(others => '0'),'0','0',(others => '0'),(others => '0'),0);


  	-- fifo signals
 	signal rinc_s, winc_s, rempty_s, wfull_s, rempty_chunk_s, wfull_chunk_s : std_logic;
 	signal rdata_s, wdata_s				: std_logic_vector(CHUNK_SIZE*16-1 downto 0);
 	signal rdata_chunk_s, wdata_chunk_s : std_logic_vector(13 downto 0);
 	-- fifo to ram signals
 	signal RAM_addr, next_RAM_addr 		: std_logic_vector(22 downto 0) := (others => '0');	
 	-- user input signals
 	signal buttons_s 					: std_logic_vector(11 downto 0);
 	signal p_in_s, p_out_s				: std_logic_vector(63 downto 0);
 	signal center_x_s 					: std_logic_vector(63 downto 0);
 	signal center_y_s 					: std_logic_vector(63 downto 0);
 	-- scheduler signals
  	signal chunk_valid_s, next_chunk_s	: std_logic := '0';
  	signal chunk_x_s,chunk_y_s 			: std_logic_vector(63 downto 0);
  	signal chunk_n_s					: integer range 0 to (DISPLAY_SIZE/CHUNK_SIZE)-1 := 0;
  	signal feeder_rinc_s 				: std_logic;

 	signal kernel_io_s : kernel_io_vector_t := (others => IO_INIT);

 	signal r,r_in : calculation_subsystem_reg := REG_INIT;
 	signal wfull_r : std_logic;
 	signal seven_seg_data_s : std_logic_vector(31 downto 0); 

 	signal iter_to_bcd_bin_s : std_logic_vector(12 downto 0);
 	signal iter_to_bcd_start_s : std_logic;
 	signal fps_to_bcd_start_s : std_logic;

 	signal julia_in_s : std_logic;
	signal julia_out_s : std_logic;
 	signal c_x_in_s : std_logic_vector(63 downto 0);
 	signal c_y_in_s : std_logic_vector(63 downto 0);
 	signal c_x_out_s : std_logic_vector(63 downto 0);
 	signal c_y_out_s : std_logic_vector(63 downto 0);

 	signal calc_to_disp_s : calc_to_disp_t;


begin

	controller_interface : entity work.snes_controller_interface
	port map(
		clk			=> clk,
		buttons		=> buttons_s,	-- 0 = R, 1 = L, 2 = X, 3 = A, 4 = right, 5 = left, 6 = down, 7 = up
		JA 			=> JA			-- 8 = start, 9 = select, 10 = Y, 11 = B
	);

	user_input : entity work.user_input_controller
	port map(
		clk 			=> clk,
		reset 			=> reset,
		buttons 		=> buttons_s,
		julia 			=> julia_in_s,
		p 				=> p_in_s,
		center_x 		=> center_x_s,
		center_y 		=> center_y_s,
		c_x 			=> c_x_in_s,
		c_y 			=> c_y_in_s,
		calc_to_disp 	=> calc_to_disp_s
	);

	line_feeder : entity work.line_feeder
	port map(
		clk 		=> kernel_clk,
		reset 		=> reset,
		rinc 		=> feeder_rinc_s,
		julia_in 	=> julia_in_s,
		c_x_in 		=> c_x_in_s,
		c_y_in 		=> c_y_in_s,
		center_x 	=> center_x_s,
		center_y 	=> center_y_s,
		p_in		=> p_in_s,
		chunk_valid => chunk_valid_s,
		julia_out	=> julia_out_s,
		c_x_out 	=> c_x_out_s,
		c_y_out		=> c_y_out_s,
		p_out 		=> p_out_s,
		chunk_x 	=> chunk_x_s,
		chunk_y 	=> chunk_y_s,
		chunk_n 	=> chunk_n_s
	);

	kernel_loop : for i in 0 to KERNEL_N-1 generate
		mul_kernels : if i < 5 generate 
			kernel_mul : entity work.mandelbrot_kernel  
			port map (
	      		clk   		=> kernel_clk,
	      		max_iter 	=> calc_to_disp_s.iterations,
	     	 	io 			=> kernel_io_s(i)
   			);
		end generate;
		LUT_kernels : if i >= 5 generate 
			kernel_LUT : entity work.mandelbrot_kernel_LUT  
			port map (
	      		clk   		=> kernel_clk,
	      		max_iter 	=> calc_to_disp_s.iterations,
	     	 	io 			=> kernel_io_s(i)
   			);			
		end generate ;
	end generate;



	data_fifo_buff : entity work.FIFO
	generic map(
		FIFO_LOG_DEPTH 	=> 5,
		FIFO_WIDTH 		=> CHUNK_SIZE*16
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
		FIFO_LOG_DEPTH 	=> 5,
		FIFO_WIDTH 		=> 14
	)
	port map(
		reset 		=> reset,
		-- read side ports
		rclk 		=> RAM_clk,
		rinc 		=> rinc_s,
		rempty 		=> rempty_chunk_s,
		rdata 		=> rdata_chunk_s,
		-- write side port
		wclk 		=> kernel_clk,
		winc 		=> winc_s,
		wdata 		=> wdata_chunk_s,
		wfull 		=> wfull_chunk_s
	);

	seven_seg_driver : entity work.seven_segment_controller
	port map(
		clk 			=> clk,
		display_data 	=> seven_seg_data_s,
		SEG 			=> SEG,
		AN 				=> AN
	);

	iter_to_bcd : entity work.bin13_to_bcd4
	port map(
		clk 		=> RAM_clk,
		start 		=> '1',
		bin 		=> iter_to_bcd_bin_s,
		bcd 		=> seven_seg_data_s(15 downto 0)
	) ;

	fps_to_bcd : entity work.bin13_to_bcd4
	port map(
		clk 		=> RAM_clk,
		start 		=> '1',
		bin 		=> r.prev_framerate(12 downto 0),
		bcd 		=> seven_seg_data_s(31 downto 16)
	) ;

	calc_to_disp <= calc_to_disp_s;
	julia <= julia_out_s;
	buttons <= buttons_s;
	iter_to_bcd_bin_s <= std_logic_vector(to_unsigned(calc_to_disp_s.iterations,13));

	comb_proc : process( r, wfull_r, rempty_s, kernel_io_s, chunk_valid_s, p_out_s, chunk_x_s, chunk_y_s, chunk_n_s, rdata_s, rdata_chunk_s, RAM_write_ready, c_x_out_s, c_y_out_s, julia_out_s )
		variable temp1,temp2 : std_logic_vector(22 downto 0);
	begin

		r_in <= r;
		r_in.rempty <= rempty_s;
		r_in.prev_chunk_valid <= chunk_valid_s;

		-- -- line feeder to kernels
		for i in 0 to (KERNEL_N-1) loop 
				-- drive kernel outputs with high impedance 
				kernel_io_s(i).req_chunk 	<= 'Z';
				kernel_io_s(i).done			<= 'Z';
				kernel_io_s(i).out_chunk_n 	<= (others => 'Z');
				kernel_io_s(i).result 		<= RESULT_INIT; -- all Z's
				-- initialize kernel inputs to logic zero
		 	    kernel_io_s(i).p 			<= p_out_s;
		 	    kernel_io_s(i).c_x 			<= c_x_out_s;
		 	    kernel_io_s(i).c_y 			<= c_y_out_s;
			 	kernel_io_s(i).julia 		<= julia_out_s;	 	    
		 		kernel_io_s(i).chunk_x 		<= (others => '0');
		 		kernel_io_s(i).chunk_y 		<= (others => '0');
		 		kernel_io_s(i).chunk_n 		<= 0;
		 		kernel_io_s(i).chunk_valid 	<= '0';
		 		kernel_io_s(i).ack 			<= '0';
		end loop;	

		-- feed line cordinates to the first kernel that requestst one
		feeder_rinc_s <= '0';
		for i in 0 to KERNEL_N-1 loop 
			if kernel_io_s(i).req_chunk = '1' then	
				kernel_io_s(i).chunk_x <= chunk_x_s;
				kernel_io_s(i).chunk_y <= chunk_y_s;
				kernel_io_s(i).chunk_n <= chunk_n_s;
				kernel_io_s(i).chunk_valid <= chunk_valid_s;
				feeder_rinc_s <= chunk_valid_s;	
				exit;
			end if ;
		end loop;	


		-- kernels to FIFO
		wdata_s <= (others => '0');
		wdata_chunk_s <= (others => '0');
		winc_s <= '0';
		if wfull_r = '0' then
			for i in 0 to KERNEL_N-1 loop
				if kernel_io_s(i).done = '1' then
					for j in 0 to CHUNK_SIZE-1 loop
						wdata_s(16*(j+1)-1 downto 16*j) <= kernel_io_s(i).result(j);
					end loop;
					wdata_chunk_s <= kernel_io_s(i).out_chunk_n;
					winc_s <= '1';
					kernel_io_s(i).ack <= '1';
					exit;
				end if;
			end loop;
		end if; 


		-- FIFO to RAM 
		rinc_s <= '0';
		RAM_write_start <= '0';
		for i in 0 to CHUNK_SIZE-1 loop
			RAM_write_data(i) <= rdata_s(16*(i+1)-1 downto 16*i);							
		end loop ; -- identifier

		RAM_write_addr <= (22 downto 19 => '0') & rdata_chunk_s & (4 downto 0 => '0'); -- addr = chunk_n * 32

		if r.rempty = '0' and RAM_write_ready = '1' then
			RAM_write_start <= '1';
			rinc_s <= '1';
		end if ;

		
		-- framerate
		if r.prev_chunk_valid = '0' and chunk_valid_s = '1' then
			r_in.framerate <= std_logic_vector(unsigned(r.framerate) + 1);
		end if ;

		if r.fps_counter = 99999999 then
			r_in.fps_counter <= 0;
			r_in.prev_framerate <= r.framerate;
			r_in.framerate <= (others => '0');
		else
			r_in.fps_counter <= r.fps_counter + 1;
			fps_to_bcd_start_s <= '0';
		end if ;



		-- case (r.state) is
		-- 	when ramw0 => 
		-- 		if r.rempty = '0' then
		-- 			for i in 0 to CHUNK_SIZE-1 loop 
		-- 				r_in.chunk_data(i) <= rdata_s(16*(i+1)-1 downto 16*i);
		-- 			end loop;
		-- 			temp1 := (22 downto 19 => '0')&rdata_line_s(9 downto 0)&(8 downto 0 => '0');
		-- 			temp2 := (22 downto 17 => '0')&rdata_line_s(9 downto 0)&(6 downto 0 => '0');
		-- 			r_in.address <= std_logic_vector(unsigned(temp1) + unsigned(temp2)); -- address is line_n * 640. which is line_n<<9 + line_n<<7
		-- 			--r_in.address <= (22 downto 19 => '0') & rdata_chunk_s & (4 downto 0 => '0'); -- addr = chunk_n * 32
		-- 			r_in.count <= 0;
		-- 			rinc_s <= '1';
		-- 			r_in.state <= ramw1;
		-- 		end if ;

		-- 	when ramw1 =>
		-- 		if RAM_write_ready = '1' then
		-- 			for i in 0 to 31 loop
		-- 				--if r.address = std_logic_vector(to_unsigned(152960,23)) then
		-- 				--	RAM_write_data(i) <= x"0080";
		-- 				--else
		-- 					RAM_write_data(i) <= r.line_data(32*r.count+i);							
		-- 				--end if ;
		-- 			end loop ; -- identifier
		-- 			RAM_write_addr <= r.address;
		-- 			RAM_write_start <= '1';
		-- 			if r.count = DISPLAY_WIDTH/32-1 then
		-- 				r_in.state <= ramw0;
		-- 			else
		-- 				r_in.count <= r.count + 1;
		-- 				r_in.address <= std_logic_vector(unsigned(r.address) + 32);
		-- 			end if ;
		-- 		end if ;
		-- end case;
	end process ; -- comb_proc

	RAM_clk_proc : process(RAM_clk)
	begin
		if rising_edge(RAM_clk) then
			if reset = '1' then
				r <= REG_INIT;
			elsif clk_en = '1' then
		 		r <= r_in;			
		 	end if ;
		end if ; 
	end process;

	kernel_clk_proc : process(kernel_clk)
	begin
		if rising_edge(kernel_clk) then
		 	wfull_r <= wfull_s;
		end if ; 
	end process;


end architecture ; -- arch