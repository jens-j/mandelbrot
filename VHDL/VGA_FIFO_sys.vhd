library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity VGA_FIFO_sys is
	port (
		clk 		: in  std_logic;
		btnC 		: in  std_logic;
		Vsync		: out std_logic;
		Hsync		: out std_logic;
		vgaRed		: out std_logic_vector(3 downto 0);
		vgaGreen	: out std_logic_vector(3 downto 0);
		vgaBlue 	: out std_logic_vector(3 downto 0)
	) ;
end entity ; -- VGA_FIFO_sys


architecture arch of VGA_FIFO_sys is

	type vga_fifo_reg is record
		h_count 	: integer;
		v_count 	: integer;
		winc 		: std_logic;
		wdata 		: std_logic_vector(11 downto 0);
	end record;


	signal vga_clk	: std_logic :='0';
	signal rdata_s 	: std_logic_vector(11 downto 0);
	signal rempty_s : std_logic;
	signal wfull_s 	: std_logic;
	signal rinc_s 	: std_logic;
	signal winc_s 	: std_logic;
	signal wdata_s 	: std_logic_vector(11 downto 0);

	signal r 		: vga_fifo_reg := (0,0,'0',(others => '0'));
	signal r_in 	: vga_fifo_reg;

	signal clk_div_s : std_logic := '0';

begin

	--clk_gen : entity work.clk_gen_25MHz
	--port map(
	--	CLK_IN1 	=> clk,
	--	CLK_OUT1 	=> vga_clk
	--);

	vga_contr : entity work.VGA_controller
	port map(	
		vga_clk		=> vga_clk,
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
		FIFO_LOG_DEPTH 	=> 3,
		FIFO_WIDTH 		=> 12
	)
	port map(
		reset 		=> btnC,
		-- read side ports
		rclk 		=> vga_clk,
		rinc 		=> rinc_s,
		rempty 		=> rempty_s,
		rdata 		=> rdata_s,
		-- write side port
		wclk 		=> clk,
		winc 		=> winc_s,
		wdata 		=> wdata_s,
		wfull 		=> wfull_s
	);

	--winc_s 	<= r.winc;
	--wdata_s <= r.wdata;

	comb_proc : process(r, wfull_s, btnC)
		variable tempR : std_logic_vector(31 downto 0);
		variable tempB : std_logic_vector(31 downto 0);

	begin
		r_in 		<= r;
		r_in.winc	<= '0';

		if wfull_s = '0' and btnC = '0' then
			--r_in.winc 	<= '1';
			winc_s 		<= '1';
			tempR 		:= std_logic_vector(to_unsigned(r.v_count,32));
			tempB 		:= std_logic_vector(to_unsigned(r.h_count,32));
			--r_in.wdata  <= x"00" & tempR(7 downto 4); 
			wdata_s 	<= tempB(6 downto 3) & x"0" & tempR(6 downto 3); 
			if r.h_count = 639 then
				r_in.h_count <= 0;
				if r.v_count = 479 then
					r_in.v_count <= 0;
				else
					r_in.v_count <= r.v_count + 1;
				end if ;
			else
				r_in.h_count <= r.h_count + 1;
			end if ;
		end if ;

	end process ; -- comb_proc


	reg_proc : process( clk )
	begin
		if rising_edge(clk) then
			r <= r_in;

			clk_div_s <= not clk_div_s;
			if clk_div_s = '1' then
				vga_clk <= not vga_clk;
			end if ;
		end if ;
	end process ; -- reg_proc




end architecture ; -- arch