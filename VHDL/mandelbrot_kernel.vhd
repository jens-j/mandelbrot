library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity mandelbrot_kernel is
  port (
	clock 		: in  std_logic;
	orig_real	: in  std_logic_vector(63 downto 0);
	orig_imag 	: in  std_logic_vector(63 downto 0);
	pix_size 	: in  std_logic_vector(63 downto 0);
	max_iter 	: in  integer range 0 to 65535;
	start 		: in  std_logic;
	done 		: out std_logic;
	result 		: out kernel_result_t
	);
end entity ; -- mandelbrot_kernel


architecture arch of mandelbrot_kernel is

	type state_t is (idle,busy,done);
	type iteration_t is array (6 downto 0) of integer in range 0 to 65525;
	type taskid_t is array(6 downto 0) of integer in range 0 to 479; 
	
	type kernel_reg is record
		z_real 			: kernel_data_t;
		z_imag 			: kernel_data_t;
		z0_real 		: kernel_data_t;
		z0_imag 		: std_logic_vector(63 downto 0); -- is the same for each pixel in a row
		result 			: kernel_output_t;
		iteration		: iteration_t; 
		state 			: state_t;
		pipeline_state 	: integer range 0 to 20;
		p_x 			: integer range 0 to 479; -- relative pixel x/real coordinate
		next_real 		: std_logic_vector(63 downto 0);
		next_imag 		: std_logic_vector(63 downto 0);
		pix_size 		: std_logic_vector(63 downto 0);
		pixel_done 		: std_logic_vector(6 downto 0); -- pipeline signal 
		tasks 			: taskid_t; -- keeps track of which pipeline stage does which pixel
		real_squared 	: std_logic_vector(63 downto 0);
		abs_value 		: std_logic_vector(63 downto 0);
		real_temp 		: std_logic_vector(63 downto 0);
	end record;

	signal r, r_in 			: kernel_reg;
	signal mult_op1_s 		: std_logic_vector(63 downto 0);
	signal mult_op2_s 		: std_logic_vector(63 downto 0);
	signal mult_res_s 		: std_logic_vector(63 downto 0);

	signal uadd_op1_s 		: std_logic_vector(63 downto 0);
	signal uadd_op2_s 		: std_logic_vector(63 downto 0);
	signal uadd_res_s 		: std_logic_vector(63 downto 0);

	signal sadd_op1_s 		: std_logic_vector(63 downto 0);
	signal sadd_op2_s 		: std_logic_vector(63 downto 0);
	signal sadd_res_s 		: std_logic_vector(63 downto 0);
	signal sadd_sub_s		: std_logic;

	signal comp_op1_s		: std_logic_vector(15 downto 0);
	signal comp_op2_s		: std_logic_vector(15 downto 0);
	signal comp_res_s		: std_logic; -- op1 > op2 => '1'



begin
	multiplier : entity work.mult64x64
    port map (
      clk   => clk,
      a     => mult_op1,
      b     => mult_op2,
      p 	=> mult_res
    );

	comb_prov : process(r,z0_imag,z0_real,start) 
		variable v 	: kernel_reg;
		variable uadd_op1_v, uadd_op2_v, sadd_op1_v, sadd_op2_v, sadd_sub_s, mult_op1_v, mult_op2_v, comp_op1_v, comp_op1_v : std_logic_vector(63 downto 0); 
		variable sadd_sub_s	: std_logic;

	begin
		v 				:= r;
		mult_op1_v 		:= (others => '0');
		mult_op2_v 		:= (others => '0');
		uadd_op1_v 		:= (others => '0');
		uadd_op2_v 		:= (others => '0');
		sadd_op1_v 		:= (others => '0');
		sadd_op2_v 		:= (others => '0');
		comp_op1_v 		:= (others => '0');
		comp_op2_v 		:= (others => '0');
		uadd_addsub_v 	:= '0';

		case( r.state ) is

			when idle =>
				v.pipeline_state 	:= 0;
				v.iteration 		:= (0,0,0,0,0,0,0)
				v.pixel_done 		:= "1111111";
				v.p_x 				:= 0;
				if start = '1' then
					v.next_real := orig_real;
					v.next_imag := orig_imag;
					v.z0_imag 	:= orig_imag;
					v.pix_size 	:= pix_size;
					v.state 	:= busy;
				end if ;
		
			when busy =>
				
				case( r.pipeline_state ) is

					when 0 =>
						if r.pixel_done(0) = '1' then
							-- store result here
							v.z_real(0) 	:= r.next_real;
							v.z0_real(0)	:= r.next_real;
							v.z_imag(0) 	:= r.next_imag;
							v.taskid_t(0) 	:= r.p_x;
							v.p_x 			:= r.p_x+1;
							uadd_op1_v 		:= r.next_real;
							uadd_op2_v 		:= r.pix_size;
							v.next_real(0) 	:= uadd_res_s;
							v.pixel_done(0) := '0';
						end if ;
						mult_op1_v 		:= v.z_real(0);
						mult_op2_v 		:= v.z_real(0);
						v.real_squared 	<= mult_res_s;
						sadd_op1_s 		
						v.iteration(1) 	:= r.iteration(1)+1;
				
					when 1 =>
						mult_op1_v 	:= r.z_imag(0);
						mult_op2_v 	:= r.z_imag(0);
						sadd_op1_v 	:= r.real_squared;
						sadd_op2_v 	:= mult_res_s;
						sadd_sub_v 	:= '1';
						v.real_temp := sadd_res_s;
						uadd_op1_v 	:= r.real_squared;
						uadd_op2_v 	:= mult_res_s;
						v.abs_value := uadd_res_s;
						comp_op1_v 	:= to_integer(unsigned(r.iteration(1)),16);
						comp_op2_v  := to_integer(unsigned(max_iter),16);
						if comp_res_s = '1' then
							v.pixel_done(1) := '1';
						end if ;

					when 2 =>
						mult_op2_v 	:= r.z_real(0);
						sadd_op1_v 	:= mult_res(62 downto 0) & '0';
						sadd_op2_v 	:= r.z0_imag;
						v.z_imag(1) := sadd_res_s;
						uadd_op1_v 	:= r.real_temp;
						uadd_op2_v 	:= r.z0_real;
						v.z_real(1) := sadd_res_s;
						comp_op1_v 	:= to_integer(unsigned(r.abs_value),16);
						comp_op2_v  := x"0004";
						if comp_res_s = '1' then
							v.pixel_done(1) := '1';
						end if;
				
				end case ;

				if r.pipeline_state = 20 then
					v.pipeline_state := 0;
				else
					v.pipeline_state := r.pipeline_state+1;
				end if ;

			when done =>

		
		end case ;

		mult_op1_s 	<= mult_op1_v;
		mult_op2_s 	<= mult_op1_v;
		uadd_op1_s 	<= uadd_op1_v;
		uadd_op2_s 	<= uadd_op2_v;
		sadd_op1_s 	<= sadd_op1_v;
		sadd_op2_s 	<= sadd_op2_v;
		r_in 		<= v;
	end process;


	reg_proc : process(clk)
	begin
		if rising_edge(clk) then 
		 	r <= r_in;
		end if;
	end process;


	unsigned_adder : process(uadd_op1_s, uadd_op2_s)
	variable res : std_logic_vector(64 downto 0);
	begin
		res := uadd_op1_s + uadd_op2_s;
		uadd_res_s <= res(63 downto 0);
	end process;


	signed_adder : process(sadd_op1_s, sadd_op2_s, sadd_sub_s)
	variable x 	 : std_logic_vector(63 downto 0);
	variable res : std_logic_vector(64 downto 0);
	begin
		if sadd_sub_s then
			x := not sadd_op2_s;
		else
			x := sadd_op2_s;
		end if ;
		res := uadd_op1_s + x + sadd_sub_s;
		uadd_res_s <= res(63 downto 0);
	end process;


	comperator : process(comp_op1_s, comp_op2_s) -- unsigned 16 bit comperator
	begin
		if comp_op1_s > comp_op2_s then
			comp_res_s <= '1';
		else
			comp_res_s <= '0';
		end if ;
	end process;

end architecture ; -- arch