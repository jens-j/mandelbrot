library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity button_debouncer is
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
end entity ; -- button_debouncer


architecture behavioural of button_debouncer is

	signal reg_clk 	: std_logic 					:= '0';
	signal count 	: integer range 0 to 999999 	:= 0;

begin

	debouncer : process(reg_clk) -- the buttons are debounced by simple sampling them @ 50 Hz
	begin
		if rising_edge(reg_clk) then
			btnCpuReset_d 	<= btnCpuReset;
		  	btnC_d 			<= btnC;
		  	btnU_d 			<= btnU;
		  	btnL_d 			<= btnL;
		  	btnR_d 			<= btnR;
		  	btnD_d 			<= btnD;			
		end if ;
	end process;

	clk_div : process(CLK)
	begin
		if rising_edge(CLK) then
			if count = 999999 then
				reg_clk <= not reg_clk;
				count <= 0;
			else
				count <= count + 1;
			end if ;
		end if ;
	end process;

end architecture ; -- arch