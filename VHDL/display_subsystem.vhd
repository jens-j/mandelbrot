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
		RAM_read_data	: in  data_vector_t
	) ;
end entity ; -- display_subsystem


architecture arch of display_subsystem is

	type read_state_t is (reading0, reading1, idle);
	type write_state_t is (writing0, writing1);

	type display_reg_t is record 
		read_state  : read_state_t;
		write_state : write_state_t;
		count 		: integer;
		address	 	: std_logic_vector(22 downto 0);
		data 		: VGA_vector_t;
		data2 		: VGA_vector_t;
		data2_set 	: std_logic;
		wfull 		: std_logic;
	end record;

	signal r 		: display_reg_t := (reading0,writing0,0,(others => '0'),((others=> (others=>'0'))),((others=> (others=>'0'))),'0','0');
	signal r_in 	: display_reg_t;
 	signal rinc_s, winc_s, rempty_s, wfull_s : std_logic;
 	signal rdata_s, wdata_s	: std_logic_vector(11 downto 0);

begin

	vga_contr : entity work.VGA_controller
	port map(	
		vga_clk		=> VGA_clk,
		reset 		=> reset,
		pix_in 		=> rdata_s,
		pix_next 	=> rinc_s,
		Vsync		=> Vsync,
		Hsync		=> Hsync,
		vgaRed		=> vgaRed,
		vgaGreen	=> vgaGreen,
		vgaBlue 	=> vgaBlue
	);

	fifo_buff : entity work.FIFO
	generic map(
		FIFO_LOG_DEPTH 	=> 5,
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

	ram_reader : process( r, wfull_s, rempty_s, RAM_read_ready, RAM_read_data  )
		variable v : display_reg_t;
		variable v_RAM_read_start : std_logic;
		variable v_winc : std_logic;
	begin
		v := r;
		v_RAM_read_start := '0';
		v_winc := '0';
		

		case( r.read_state) is
		
			when reading0 =>
				RAM_read_addr <= r.address;
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
						v.data2(i) := RAM_read_data(i)(11 downto 0);  
					end loop;
					v.data2_set := '1';
					v.read_state := idle;
				end if ;

			when idle =>
				if r.data2_set = '0' then
					v.read_state := reading0;
				end if ;
		end case ;
		 
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
					wdata_s <= r.data(r.count);
					v_winc := '1';
					if r.count = 31 then
						v.write_state := writing0;
					else
						v.count := r.count + 1;
					end if ;
				end if ;
		end case;
		
		winc_s <= v_winc;
		RAM_read_start <= v_RAM_read_start;
		r_in <= v;
		r_in.wfull <= wfull_s;
	end process ; -- ram_reader

	identifier : process( RAM_clk )
	begin
		if rising_edge(RAM_clk) then
			if reset = '1' then
				r <= (reading0,writing0,0,(others => '0'),((others=> (others=>'0'))),((others=> (others=>'0'))),'0','0');
			else
				r <= r_in;				
			end if ;
		end if ;
	end process ; -- identifier

end architecture ; -- arch