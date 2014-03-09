library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity mandelbrot_kernel is
  port (
	clk 		: in  std_logic;
	max_iter 	: in  integer range 0 to 65535;
	-- pixels coords in
	next_valid 	: in  std_logic;
	next_cx		: in  std_logic_vector(63 downto 0);
	next_cy 	: in  std_logic_vector(63 downto 0);
	next_pix_n 	: in  integer range 0 to DISPLAY_SIZE-1;
	next_inc 	: out std_logic;
	-- iteration numbers out
	done 		: out std_logic;
	pix_out_n 	: out integer range 0 to DISPLAY_SIZE-1;
	result 		: out std_logic_vector(15 downto 0)
	);
end entity ; -- mandelbrot_kernel


architecture arch of mandelbrot_kernel is


	type iteration_t is array (PIPELINE_DEPTH-1 downto 0) of integer range 0 to 65535;
	type taskid_t is array(PIPELINE_DEPTH-1 downto 0) of integer range 0 to DISPLAY_SIZE-1; 
	
	type kernel_reg is record
		-- FSM states
		pipeline_state 	: integer range 0 to PIPELINE_DEPTH-1;
		-- algorithm data
		z_real 			: kernel_data_t;
		z_imag 			: kernel_data_t;
		c_real 			: kernel_data_t;
		c_imag 			: kernel_data_t;
		iteration		: iteration_t; 
		task_id 		: taskid_t; -- keeps track of which pipeline stage does which pixel
		--pipeline registers
		sub_res 		: std_logic_vector(63 downto 0);
		comp0_res  		: std_logic;
		comp1_res  		: std_logic;
		add0_res 		: std_logic_vector(63 downto 0);
		add1_res 		: std_logic_vector(63 downto 0);
		add2_res 		: std_logic_vector(63 downto 0);
		inc_res 		: integer range 0 to 65535;
		imag_temp 		: std_logic_vector(63 downto 0); -- the product 2*x*y is kept idle for one stage  
		-- output
		done 			: std_logic_vector(PIPELINE_DEPTH-1 downto 0); -- done is waiting to get output data read
		idle 			: std_logic_vector(PIPELINE_DEPTH-1 downto 0); -- idle is waiting for input data
	end record;

	


	signal r, r_in 			: kernel_reg := (0,
											(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>(others=>'0')),(others=>0),(others=>0),
											(others=>'0'),'0','0',(others=>'0'),(others=>'0'),(others=>'0'),0,(others=>'0'),
											(others=>'0'),(others=>'1'));
	-- x*x
	signal mult0_op1_s 		: std_logic_vector(63 downto 0);
	signal mult0_op2_s 		: std_logic_vector(63 downto 0);
	signal mult0_res_s 		: std_logic_vector(63 downto 0);
	-- y*y
	signal mult1_op1_s 		: std_logic_vector(63 downto 0);
	signal mult1_op2_s 		: std_logic_vector(63 downto 0);
	signal mult1_res_s 		: std_logic_vector(63 downto 0);
	-- X*y
	signal mult2_op1_s 		: std_logic_vector(63 downto 0);
	signal mult2_op2_s 		: std_logic_vector(63 downto 0);
	signal mult2_res_s 		: std_logic_vector(63 downto 0);
	-- x*x + y*y
	signal add0_op1_s 		: std_logic_vector(63 downto 0);
	signal add0_op2_s 		: std_logic_vector(63 downto 0);
	signal add0_res_s 		: std_logic_vector(63 downto 0);
	-- add c_real
	signal add1_op1_s 		: std_logic_vector(63 downto 0);
	signal add1_op2_s 		: std_logic_vector(63 downto 0);
	signal add1_res_s 		: std_logic_vector(63 downto 0);
	-- add c_imag
	signal add2_op1_s 		: std_logic_vector(63 downto 0);
	signal add2_op2_s 		: std_logic_vector(63 downto 0);
	signal add2_res_s 		: std_logic_vector(63 downto 0);
	-- interation++
	signal inc0_op_s 		: integer range 0 to 65535;
	signal inc0_res_s 		: integer range 0 to 65535;
	-- x*x - y*y
	signal sub_op1_s 		: std_logic_vector(63 downto 0);
	signal sub_op2_s 		: std_logic_vector(63 downto 0);
	signal sub_res_s 		: std_logic_vector(63 downto 0);
	-- itearation > max_iter
	signal comp0_op1_s		: integer range 0 to 65535;
	signal comp0_op2_s		: integer range 0 to 65535;
	signal comp0_res_s		: std_logic;
	-- |z| > 4
	signal comp1_op_s		: std_logic_vector(3 downto 0);
	signal comp1_res_s		: std_logic;

	-- component mult64x64
	-- PORT(
	-- 	clk : IN std_logic;
	-- 	a : IN std_logic_vector(63 downto 0);
	-- 	b : IN std_logic_vector(63 downto 0);          
	-- 	p : OUT std_logic_vector(63 downto 0)
	-- 	);
	-- END component;

begin

	multiplier0 : entity work.mult64x64  
	port map (
      clk   => clk,
      a     => mult0_op1_s,
      b     => mult0_op2_s,
      p 	=> mult0_res_s
    );

	multiplier1 : entity work.mult64x64  
	port map (
      clk   => clk,
      a     => mult1_op1_s,
      b     => mult1_op2_s,
      p 	=> mult1_res_s
    );

    multiplier2 : entity work.mult64x64  
    port map (
      clk   => clk,
      a     => mult2_op1_s,
      b     => mult2_op2_s,
      p 	=> mult2_res_s
    );



	comb_proc : process(r, max_iter, next_valid, next_cx, next_cy, next_pix_n, mult0_res_s, mult1_res_s, mult2_res_s, add0_res_s, add1_res_s, add2_res_s, inc0_res_s, sub_res_s, comp0_res_s, comp1_res_s) 
		variable v 							: kernel_reg;
		variable inc0_op_v 					: integer range 0 to DISPLAY_WIDTH-1;
		variable inc1_op_v 					: integer range 0 to 65535;  
		variable comp1_op_v 				: std_logic_vector(3 downto 0); 
		variable sub_op1_v, sub_op2_v 		: std_logic_vector(63 downto 0);
		variable comp0_op1_v, comp0_op2_v 	: integer range 0 to 65535;
		variable mult0_op1_v, mult0_op2_v, mult1_op1_v, mult1_op2_v, mult2_op1_v, mult2_op2_v 					: std_logic_vector(63 downto 0);
		variable add0_op1_v, add0_op2_v, add1_op1_v, add1_op2_v, add2_op1_v, add2_op2_v, add3_op1_v, add3_op2_v : std_logic_vector(63 downto 0);
		
		variable next_inc_v 				: std_logic;
		variable done_v 					: std_logic;
		variable pix_out_n_v  				: integer range 0 to DISPLAY_SIZE-1;
		variable result_v 					: std_logic_vector(15 downto 0);
	begin
		v 			:= r;
		sub_op1_v 	:= (others => '0');
		sub_op2_v 	:= (others => '0');
		comp0_op1_v := 0;
		comp0_op2_v	:= 1;
		comp1_op_v	:= (others => '0');
		mult0_op1_v := (others => '0');
		mult0_op2_v := (others => '0');
		mult1_op1_v := (others => '0');
		mult1_op2_v := (others => '0');
		mult2_op1_v := (others => '0');
		mult2_op2_v := (others => '0');
		add0_op1_v 	:= (others => '0');
		add0_op2_v 	:= (others => '0');
		add1_op1_v 	:= (others => '0');
		add1_op2_v 	:= (others => '0');
		add2_op1_v 	:= (others => '0');
		add2_op2_v 	:= (others => '0');
		inc0_op_v 	:= 0;

		next_inc_v 	:= '0';
		done_v 		:= '0';
		pix_out_n_v := 0;
		result_v 	:= (others=>'0');

				

		case( r.pipeline_state ) is

			when 0 =>
				if (r.comp0_res='1' or r.comp1_res='1' or r.idle(0) = '1') then -- iteration finished or not yet started
					-- output result
					if r.idle(0) = '0' then
						result_v 	:= std_logic_vector(to_unsigned(r.iteration(0),16));
						pix_out_n_v := r.task_id(0);
						done_v 		:= '1';							
					end if ;
					-- input next z0 in pipeline slot
					if next_valid = '1' then
						v.z_real(0) 		:= next_cx;
						v.z_imag(0) 		:= next_cy;
						v.c_real(0)			:= next_cx;
						v.c_imag(0)			:= next_cy;
						v.task_id(0) 		:= next_pix_n;
						v.iteration(0) 		:= 0;
						v.idle(0) 			:= '0';
						next_inc_v 			:= '1';
					else
						v.idle(0) 			:= '1';
					end if ;

				else -- else: continue iteration
					v.z_real(0) 		:= r.add1_res;
					v.z_imag(0) 		:= r.add2_res;
				end if ;

				mult0_op1_v := v.z_real(0);
				mult0_op2_v := v.z_real(0);
				mult1_op1_v := v.z_imag(0);
				mult1_op2_v := v.z_imag(0);
				mult2_op1_v := v.z_real(0);
				mult2_op2_v := v.z_imag(0);

			when 1 =>

			when 2 =>
					add0_op1_v 		:= mult0_res_s;
					add0_op2_v 		:= mult1_res_s;
					sub_op1_v 		:= mult0_res_s;
					sub_op2_v 		:= mult1_res_s;
					inc0_op_v 		:= r.iteration(0);
					v.iteration(0) 	:= inc0_res_s;	

			when others =>
					add1_op1_v 	:= r.sub_res;
					add1_op2_v 	:= r.c_real(0);
					add2_op1_v 	:= r.imag_temp;
					add2_op2_v 	:= r.c_imag(0);
					comp0_op1_v := r.iteration(0);
					comp0_op2_v := max_iter;
					comp1_op_v 	:= r.add0_res(63 downto 60);							

		end case ;

		-- increment pipeline stage 
		if r.pipeline_state = PIPELINE_DEPTH-1 then
			v.pipeline_state := 0;
		else
			v.pipeline_state := r.pipeline_state+1;
		end if ;




		-- connect the FU's outputs to the pipeline registers
		v.sub_res 	:= sub_res_s;
		v.comp0_res := comp0_res_s;
		v.comp1_res := comp1_res_s;
		v.add0_res 	:= add0_res_s;
		v.add1_res 	:= add1_res_s;
		v.add2_res 	:= add2_res_s;
		v.inc_res 	:= inc0_res_s;
		v.imag_temp := mult2_res_s(62 downto 0) & '0';

		-- set the FU's inputs
		sub_op1_s 	<= sub_op1_v;
		sub_op2_s 	<= sub_op2_v;
		comp0_op1_s <= comp0_op1_v;
		comp0_op2_s <= comp0_op2_v;
		comp1_op_s 	<= comp1_op_v;
		mult0_op1_s <= mult0_op1_v;
		mult0_op2_s <= mult0_op2_v;
		mult1_op1_s <= mult1_op1_v;
		mult1_op2_s <= mult1_op2_v;
		mult2_op1_s <= mult2_op1_v;
		mult2_op2_s <= mult2_op2_v;
		add0_op1_s 	<= add0_op1_v;
		add0_op2_s 	<= add0_op2_v;
		add1_op1_s 	<= add1_op1_v;
		add1_op2_s 	<= add1_op2_v;
		add2_op1_s 	<= add2_op1_v;
		add2_op2_s 	<= add2_op2_v;
		inc0_op_s 	<= inc0_op_v;

		pix_out_n 	<= pix_out_n_v;
		result 		<= result_v;
		done 		<= done_v;
		next_inc 	<= next_inc_v;
		r_in 		<= v;
	end process;


	reg_proc : process(clk)
	begin
		if rising_edge(clk) then 
		 	r <= r_in;
		end if;
	end process;


	subtractor : process(sub_op1_s, sub_op2_s)
	begin
		sub_res_s <= std_logic_vector(signed(sub_op1_s) - signed(sub_op2_s));
	end process;


	comperator0 : process(comp0_op1_s, comp0_op2_s) -- unsigned 16 bit comperator
	begin
		if comp0_op1_s >= comp0_op2_s then
			comp0_res_s <= '1';
		else
			comp0_res_s <= '0';
		end if ;
	end process;

	comperator1 : process(comp1_op_s) -- unsigned 16 bit comperator
	begin
		if to_integer(unsigned(comp1_op_s)) > 4 then
			comp1_res_s <= '1';
		else
			comp1_res_s <= '0';
		end if ;
	end process;


	adder0 : process(add0_op1_s, add0_op2_s)
	begin
		add0_res_s <=  std_logic_vector(signed(add0_op1_s) + signed(add0_op2_s));
	end process;

	adder1 : process(add1_op1_s, add1_op2_s)
	variable res : std_logic_vector(64 downto 0);
	begin
		add1_res_s <= std_logic_vector(signed(add1_op1_s) + signed(add1_op2_s));
	end process;

	adder2 : process(add2_op1_s, add2_op2_s)
	variable res : std_logic_vector(64 downto 0);
	begin
		add2_res_s <=  std_logic_vector(signed(add2_op1_s) + signed(add2_op2_s));
	end process;

	incrementer0 : process(inc0_op_s)
	begin
		inc0_res_s <= inc0_op_s + 1;
	end process;


end architecture ; -- arch