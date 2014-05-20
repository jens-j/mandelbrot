library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity display_subsystem is
	port (
		VGA_clk			: in  std_logic;
		RAM_clk 		: in  std_logic;
		reset 			: in  std_logic;
		-- VGA signals
		Vsync			: out std_logic;
		Hsync			: out std_logic;
		vgaRed			: out std_logic_vector(3 downto 0);
		vgaGreen		: out std_logic_vector(3 downto 0);
		vgaBlue 		: out std_logic_vector(3 downto 0);
		-- RAM read port signals
		RAM_read_addr 	: out std_logic_vector(22 downto 0);
		RAM_read_start 	: out std_logic;
		RAM_read_ready  : in  std_logic;
		RAM_read_data	: in  data_vector_t;
		-- IO
		SW 				: in  std_logic_vector(15 downto 11);
		-- signals from the calculation subsystem
		iterations 		: in  integer range 0 to 65535;
		color_set 		: in  integer range 0 to COLOR_SET_N
	) ;
end entity ; -- display_subsystem


architecture arch of display_subsystem is

	type read_state_t is (reading0, reading1, idle);
	type write_state_t is (writing0, writing1, writing2, writing3);

	type display_reg_t is record 
		read_state  	: read_state_t;
		write_state 	: write_state_t;
		count 			: integer;
		address	 		: std_logic_vector(22 downto 0);
		data 			: data_vector_t;
		data2 			: data_vector_t;
		data2_set 		: std_logic;
		wfull 			: std_logic;
		shift_counter 	: integer;
		table_offset 	: integer;
		prev_Vsync 		: std_logic;
	end record;

	constant R_INIT : display_reg_t := 	(reading0,writing0,0,(others => '0'),((others=> (others=>'0'))),
										((others=> (others=>'1'))),'0','0',0,0,'1');

	signal r 		: display_reg_t := R_INIT;
	signal r_in 	: display_reg_t := R_INIT;
 	signal rinc_s, winc_s, rempty_s, wfull_s : std_logic;
 	signal rdata_s, wdata_s	: std_logic_vector(11 downto 0);

 	signal table_index_s : integer := 0;
 	signal Vsync_s 	: std_logic;

	signal log_rom_addr_s : std_logic_vector(12 downto 0);
	signal log_rom_data_s : std_logic_vector(7 downto 0);
	signal color_rom_addr_s : std_logic_vector(COLOR_SET_LOG+7 downto 0);
	signal color_rom_data_s : std_logic_vector(11 downto 0);

begin

	vga_contr : entity work.VGA_controller
	port map(	
		vga_clk		=> VGA_clk,
		reset 		=> reset,
		pix_in 		=> rdata_s,
		pix_next 	=> rinc_s,
		Vsync		=> Vsync_s,
		Hsync		=> Hsync,
		vgaRed		=> vgaRed,
		vgaGreen	=> vgaGreen,
		vgaBlue 	=> vgaBlue
	);

	fifo_buff : entity work.FIFO
	generic map(
		FIFO_LOG_DEPTH 	=> 8,
		FIFO_WIDTH 		=> 12
	)
	port map(
		reset 		=> reset,
		-- read side ports
		rclk 		=> VGA_clk,
		rinc 		=> rinc_s,
		rempty 		=> rempty_s,
		rdata 		=> rdata_s,
		-- write side port
		wclk 		=> RAM_clk,
		winc 		=> winc_s,
		wdata 		=> wdata_s,
		wfull 		=> wfull_s
	);

	log_rom : entity work.log_ROM
	port map (
		clka  		=> RAM_clk,
		addra 		=> log_rom_addr_s,
		douta 		=> log_rom_data_s
	);

	color_rom : entity work.color_table_ROM
	port map (
		clka  		=> RAM_clk,
		addra 		=> color_rom_addr_s,
		douta 		=> color_rom_data_s
	);


	Vsync <= Vsync_s;



	ram_reader : process( 	r, wfull_s, rempty_s, RAM_read_ready, RAM_read_data, table_index_s, Vsync_s, 
						 	iterations, SW, log_rom_data_s, color_rom_data_s, color_set)
		variable v : display_reg_t;
		variable v_RAM_read_start : std_logic;
		variable v_winc : std_logic;
		variable temp_index_sum : integer;
		variable temp_index : std_logic_vector(7 downto 0);
		variable data_mod : std_logic_vector(7 downto 0);
	begin
		v := r;
		v_RAM_read_start := '0';
		v_winc := '0';

		color_rom_addr_s <= (others => '0');
		log_rom_addr_s <= (others => '0');
		wdata_s <= (others => '0');

		case( r.read_state) is
			-- this process reads vectors from the RAM
			when reading0 =>
				v_RAM_read_start := '1';
				if to_integer(unsigned(r.address)) < DISPLAY_WIDTH * DISPLAY_HEIGHT - 32 then
					v.address := std_logic_vector(unsigned(r.address) + 32);
				else
					v.address := (others => '0');					
				end if ;
				v.read_state := reading1;

			when reading1 =>
				if RAM_read_ready = '1' then
					for i in 0 to 31 loop
						v.data2(i) := RAM_read_data(i);  
					end loop;
					v.data2_set := '1';
					v.read_state := idle;
				end if ;

			when idle =>
				if r.data2_set = '0' then
					v.read_state := reading0;
				end if ;
		end case ;
		-- this process feeds the data from the vectors of the other process to the FIFO element wise 
		case ( r.write_state ) is	
			when writing0 =>
				if r.data2_set = '1' then
					v.data := r.data2;
					v.data2_set := '0';
					v.count := 0;
					v.write_state := writing1;
				end if ;

			when  writing1 =>
				if r.wfull = '0' then
					log_rom_addr_s <= r.data(r.count)(12 downto 0);
					v.write_state := writing2;
				end if ;

			when writing2 =>	
				color_rom_addr_s <= std_logic_vector(to_unsigned(color_set,COLOR_SET_LOG)) &  
									std_logic_vector(unsigned(log_rom_data_s) + to_unsigned(r.table_offset,8));
				v.write_state := writing3;

			when writing3 =>
				v_winc := '1';
				if r.data(r.count) = std_logic_vector(to_unsigned(iterations,16)) then
					wdata_s <= x"000";
				else
					wdata_s <= color_rom_data_s;
				end if;
				if r.count = 31 then
					v.write_state := writing0;
				else
					v.count := r.count + 1;
					v.write_state := writing1;
				end if ;


		end case;
		
		-- color shift counter
		if r.prev_Vsync = '1' and Vsync_s = '0' and SW(15) = '1' then
			if r.shift_counter = 7  or (SW(14) = '1' and r.shift_counter = 3) or (SW(13) = '1' and r. shift_counter = 1) or SW(12)='1' then
				v.shift_counter := 0;
				if r.table_offset = 255 then
					v.table_offset := 0;
				else
					if SW(11) = '0' then
						v.table_offset := r.table_offset+1;			
					else
						v.table_offset := r.table_offset-1;				
					end if ;
				end if ;
			else
				v.shift_counter := r.shift_counter+1;
			end if ;
		end if ;
		v.prev_Vsync := Vsync_s;





		-- -- pick VGA output value (color) from table 
		-- if r.data(r.count) = std_logic_vector(to_unsigned(iterations,16)) then
		-- 	wdata_s <= x"000";
		-- 	table_index_s <= 0; -- prevent latches
		-- else
		-- 	data_mod := r.data(r.count)(7 downto 0);
		-- 	if SW(12) = '1' then
		-- 		temp_index_sum := to_integer(unsigned(data_mod)) - r.table_offset;	
		-- 	else
		-- 		temp_index_sum := to_integer(unsigned(data_mod)) + r.table_offset;	
		-- 	end if ;
		-- 	temp_index := std_logic_vector(to_unsigned(temp_index_sum,8)); 
		-- 	table_index_s <= to_integer(unsigned(temp_index));	
		-- 	wdata_s <= RAINBOW_TABLE(table_index_s);
		-- end if ;



		RAM_read_addr <= r.address;
		RAM_read_start <= v_RAM_read_start;
		winc_s <= v_winc;
		r_in <= v;
		r_in.wfull <= wfull_s;
	end process ; -- ram_reader

	clk_proc : process( RAM_clk )
	begin
		if rising_edge(RAM_clk) then
			if reset = '1' then
				r <= R_INIT;
			else
				r <= r_in;				
			end if ;
		end if ;
	end process ; -- identifier

end architecture ; -- arch