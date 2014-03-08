library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity btn_display_test is
	port (
		CLK 			: in std_logic;
		-- NEXYS 4 buttons
	  	btnCpuReset		: in  std_logic;
	  	btnC			: in  std_logic;
	  	btnU			: in  std_logic;
	  	btnL			: in  std_logic;
	  	btnR			: in  std_logic;
	  	btnD			: in  std_logic;
	  	-- NEXYS 4 7-segent display
	  	SEG 			: out std_logic_vector(6 downto 0);
		AN 				: out std_logic_vector(7 downto 0);
		LED 			: out std_logic_vector(15 downto 0)
		) ;
end entity ; -- btn_display_test

architecture behavioural of btn_display_test is

	component button_debouncer is
	  port (
	  	CLK 			: in  std_logic; -- 100MHz
	  	-- NEXYS 4 buttons
	  	btnCpuReset		: in  std_logic;
	  	btnC			: in  std_logic;
	  	btnU			: in  std_logic;
	  	btnL			: in  std_logic;
	  	btnR			: in  std_logic;
	  	btnD			: in  std_logic;
	  	-- debounced outputs
	  	btnCpuReset_d 	: out std_logic;
	  	btnC_d			: out std_logic;
	  	btnU_d 			: out std_logic;
	  	btnL_d			: out std_logic;
	  	btnR_d			: out std_logic;
	  	btnD_d			: out std_logic
	  ) ;
	end component ; -- button_debouncer

	component seven_segment_controller is
	port (
		CLK 			: in  std_logic;
		display_data 	: in  std_logic_vector(31 downto 0);
		SEG 			: out std_logic_vector(6 downto 0);
		AN 				: out std_logic_vector(7 downto 0)
	  ) ;
	end component ; -- seven_segment_controller

	signal btnCpuReset_s 	: std_logic;
  	signal btnC_s			: std_logic;
  	signal btnU_s 			: std_logic;
  	signal btnL_s			: std_logic;
  	signal btnR_s			: std_logic;
  	signal btnD_s			: std_logic;
  	signal display_data_s 	: std_logic_vector(31 downto 0) := x"00000001";
  	signal inc, dec 		: std_logic_vector(31 downto 0);

begin

	input_comp : button_debouncer
	port map(
		CLK 			=> CLK, 
		btnCpuReset 	=> btnCpuReset, 
		btnC 			=> btnC, 
		btnU 			=> btnU, 
		btnL 			=> btnL, 
		btnR 			=> btnR, 
		btnD 			=> btnD, 
		btnCpuReset_d 	=> btnCpuReset_s, 
		btnC_d 			=> btnC_s, 
		btnU_d 			=> btnU_s, 
		btnL_d 			=> btnL_s,
		btnR_d 			=> btnR_s, 
		btnD_d 			=> btnD_s);

	output_comp : seven_segment_controller
	port map(CLK, display_data_s, SEG, AN);


	process(btnU_s,btnL_s,btnR_s,btnD_s,display_data_s)

	begin
		inc <= std_logic_vector(unsigned(display_data_s) + 1);
		dec <= std_logic_vector(unsigned(display_data_s) - 1);
		LED <= (others => '0') & btnU_s & btnL_s & btnR_s & btnD_s;

		if rising_edge(btnU_s) then
			display_data_s <= inc;
		end if ;
		if rising_edge(btnD_s) then
			display_data_s <= dec;
		end if ;
		if rising_edge(btnL_s) then
			display_data_s <= display_data_s(30 downto 0) & display_data_s(31);
		end if ;
		if rising_edge(btnR_s) then
			display_data_s <=  display_data_s(31) & display_data_s(30 downto 0);
		end if ;
	end process;


end architecture ; -- arch