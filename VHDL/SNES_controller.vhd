library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SNES_controller is
  port (
	clk			: in  	std_logic; -- clocked at 1MHz
	led 		: out 	std_logic_vector(15 downto 0);
	JA 			: inout std_logic_vector(7 downto 0)
  ) ;
end entity ; -- SNES_controller

architecture behavioural of SNES_controller is

	type state_t is (s0,s1,s2,s3,s4);
	type buf_vector is array (integer range <>) of std_logic_vector(15 downto 0);
	
	type snes_reg is record
		state 			: state_t;
		shift_in 		: std_logic_vector(11 downto 0);
		btn_state 		: std_logic_vector(11 downto 0);
		count 			: integer range 0 to 15;
		fbuf 			: buf_vector(172800);
		bufcount 		: integer range 0 to 172800;
	end record;

	signal r, r_in 		: snes_reg;
	signal clk_count 	: integer range 0 to 127;

begin

	comb_proc : process(r, JA)
		variable v : snes_reg;
		variable snes_latch_v, snes_data_v, snes_clk_v : std_logic;
	begin
		v 				:= r;
		snes_latch_v 	:= '0';
		snes_clk_v 		:= '0';


		case( r.state ) is
		
			when s0 =>
				v.state := s1;
				v.count := 0;
				v.bufcount := r.bufcount + 1;
				v.fbuf(r.bufcount) := std_logic_vector(to_unsigned(r.bufcount,16));

			when s1 =>
				snes_latch_v := '1';
				v.state := s2;

			when s2 => 
				v.shift_in := r.shift_in(10 downto 0) & JA(2);
				if r.count = 11 then
					v.state := s4;
				else
					v.count := r.count + 1;
					v.state := s3;
				end if ;

			when s3 =>
				snes_clk_v := '1';
				v.state := s2;

			when others =>
				v.btn_state := r.shift_in;
				v.state := s0;
		
		end case ;

		JA(7) 		<= snes_latch_v;
		JA(3) 		<= snes_clk_v;
		led 		<= "0000" & not r.btn_state;
		r_in		<= v;
	end process;

	reg_proc : process(clk)
	begin
		if rising_edge(clk) then 
			if clk_count = 99 then
		 		r <= r_in;
		 		clk_count <= 0;
			else
				clk_count <= clk_count+1;
			end if ;
		end if;

	end process;


end architecture ; -- behavioural