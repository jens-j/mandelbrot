library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity seven_segment_controller is
  port (
	clk 			: in  std_logic;
	display_data 	: in  std_logic_vector(31 downto 0);
	SEG 			: out std_logic_vector(6 downto 0);
	AN 				: out std_logic_vector(7 downto 0)
  ) ;
end entity ; -- seven_segment_controller


architecture nehavioural of seven_segment_controller is

	signal count, count_in 	: integer range 0 to 7 		:= 0;
	signal clk_div 			: integer range 0 to 4999 	:= 0;
begin

	comb_proc : process(count, display_data)
		variable AN_v 	: std_logic_vector(7 downto 0);
		variable seg_v 	: std_logic_vector(3 downto 0);
	begin
		AN_v 		:= x"FF";
		AN_v(count) := '0';
		AN 			<= AN_v;

		case( count ) is
			when 0 		=> seg_v := display_data(3 downto 0);
			when 1 		=> seg_v := display_data(7 downto 4);
			when 2 		=> seg_v := display_data(11 downto 8);
			when 3 		=> seg_v := display_data(15 downto 12);
			when 4 		=> seg_v := display_data(19 downto 16);
			when 5 		=> seg_v := display_data(23 downto 20);
			when 6 		=> seg_v := display_data(27 downto 24);
			when others => seg_v := display_data(31 downto 28);
		end case;

		case( seg_v ) is
			when x"0" 	=> SEG <= "1000000";
			when x"1" 	=> SEG <= "1111001";
			when x"2" 	=> SEG <= "0100100";
			when x"3" 	=> SEG <= "0110000";
			when x"4" 	=> SEG <= "0011001";
			when x"5" 	=> SEG <= "0010010";
			when x"6" 	=> SEG <= "0000010";
			when x"7" 	=> SEG <= "1111000";
			when x"8" 	=> SEG <= "0000000";
			when x"9" 	=> SEG <= "0010000";
			when x"A" 	=> SEG <= "0001000";
			when x"B" 	=> SEG <= "0000011";
			when x"C" 	=> SEG <= "1000110";
			when x"D" 	=> SEG <= "0100001";
			when x"E" 	=> SEG <= "0000110";
			when others => SEG <= "0001110";	
		end case;

		if count = 7 then
			count_in <= 0;
		else
			count_in <= count + 1;
		end if ;

	end process;

	reg_proc : process(clk)
	begin
		if rising_edge(clk) then
			if clk_div = 4999 then
				count <= count_in;
				clk_div <= 0;
			else
				clk_div <= clk_div + 1;
			end if ;
		end if ;
	end process;

end architecture ; -- arch