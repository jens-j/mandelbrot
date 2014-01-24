library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity VGA_controller is
	port(		clk			: in  std_logic;
				Vsync		: out std_logic;
				Hsync		: out std_logic;
				vgaRed		: out std_logic_vector(3 downto 0);
				vgaGreen	: out std_logic_vector(3 downto 0);
				vgaBlue 	: out std_logic_vector(3 downto 0)
 		);
end entity;


architecture behavioural of VGA_controller is

	component clk_wiz_v3_6 is
	port
	 (-- Clock in ports
	  CLK_IN1           : in     std_logic;
	  -- Clock out ports
	  CLK_OUT1          : out    std_logic;
	  -- Status and control signals
	  RESET             : in     std_logic;
	  LOCKED            : out    std_logic
	 );
	end component;

	type VGA_reg is record
		h_count 	: integer; -- horizontal position
		v_count 	: integer; -- vertical position
		l_count 	: integer; -- display line 
		p_count	 	: integer; -- position in display area (pixel counter)
		f_count 	: integer; -- absolute position in frame
		frames		: integer; -- counts frames
	end record;

	constant P_VS 		: integer := 416800;
	constant T_V_pw		: integer := 1600;
	constant T_V_start	: integer := 1600 + 23200;
	constant T_V_end	: integer := 1600 + 23200 + 384000;

	constant P_HS 		: integer := 800;
	constant T_H_pw		: integer := 96;
	constant T_H_start	: integer := 96 + 48;
	constant T_H_end	: integer := 96 + 48 + 640;

	signal r   	: VGA_reg := (0,0,0,0,0,0);
	signal r_in : VGA_reg := (0,0,0,0,0,0);
	signal vga_clk	: std_logic;

begin 

	clk_gen : clk_wiz_v3_6
	port map(	CLK_IN1 	=> clk,
				CLK_OUT1 	=> vga_clk,
				RESET		=> '0');



	comb_proc : process(r)
		variable v 						: VGA_reg;
		variable v_VS, v_HS 			: std_logic;
		variable v_red, v_green, v_blue : std_logic_vector(3 downto 0);
	begin
		v 		:= r;
		v_VS	:= '1';
		v_HS 	:= '1';
		v_red 	:= "0000";
		v_green := "0000";
		v_blue 	:= "0000";

		v.h_count := r.h_count + 1; -- increment horizontal counter
		v.f_count := r.f_count + 1; -- increment overall counter
		if v.h_count = P_HS then  -- check for end of line
			v.h_count := 0;
			v.p_count := 0;
			v.v_count := r.v_count + 1;	-- increment vertical counter
			v.l_count := r.l_count + 1; 
		elsif r.h_count < T_H_pw then -- HS pulse active
			v_HS := '0';
		end if;

		if v.f_count = P_VS then -- check for end of frame
			v.f_count := 0;
			v.v_count := 0;
			v.l_count := 0;
			v.frames  := r.frames + 1;
		elsif r.f_count < T_V_pw then -- VS pulse active
			v_VS := '0';
		elsif (r.f_count > T_V_start AND r.f_count < T_V_end) then -- in vertical T_disp
			if (r.h_count > T_H_start AND r.h_count < T_H_end) then -- in horizontal T_display 
				v.p_count 	:= r.p_count + 1;
				v_red 		:= std_logic_vector(to_unsigned(r.p_count mod 16, v_red'length));
				v_green 	:= std_logic_vector(to_unsigned(r.l_count mod 16, v_green'length));
				v_blue 		:= std_logic_vector(to_unsigned((40*(r.l_count/16) + (r.p_count/16)) mod 16, v_blue'length));
			end if;
		end if; 


		Vsync 		<= v_VS;
		Hsync 		<= v_HS;
		vgaRed 		<= v_red;
		vgaGreen 	<= v_green;
		vgaBlue 	<= v_blue;
		r_in 		<= v;
	end process;




	reg_proc : process(vga_clk)
	begin
		if rising_edge(vga_clk) then
			r <= r_in;
		end if;
	end process;

end architecture;