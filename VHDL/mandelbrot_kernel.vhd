library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity mandelbrot_kernel is
  port (
	clk 			: in  std_logic;
	max_iter 		: in  integer range 0 to 65535;
	-- pixels coords of first pixel in 
	in_valid 		: in  std_logic;
	c0_real			: in  std_logic_vector(63 downto 0);
	c0_imag 		: in  std_logic_vector(63 downto 0);
	in_p 			: in  std_logic_vector(63 downto 0);
	in_line_n 		: in  integer range 0 to DISPLAY_HEIGHT-1;
	in_inc 			: out std_logic;
	-- iteration numbers of entire line out
	ack 			: in  std_logic;
	done 			: out std_logic;
	out_line_n 		: out integer range 0 to DISPLAY_HEIGHT-1;
	result 			: out line_vector_t
	);	
end entity ; -- mandelbrot_kernel


architecture arch of mandelbrot_kernel is

	type state_t is (idle,busy,finished);
	type iteration_t is array (PIPELINE_DEPTH-1 downto 0) of integer range 0 to 65535;
	type taskid_t is array(PIPELINE_DEPTH-1 downto 0) of integer range 0 to DISPLAY_WIDTH-1; 
	
	type kernel_reg is record
		-- FSM states
		state 			: state_t;
		pipeline_state 	: integer range 0 to PIPELINE_DEPTH-1;
		-- pix coord (c) calculation
		c0_real 		: std_logic_vector(63 downto 0);
		c0_imag 		: std_logic_vector(63 downto 0);
		p 				: std_logic_vector(63 downto 0);
		pix_n 			: integer range 0 to DISPLAY_WIDTH-1;
		-- algorithm data
		z_real 			: kernel_data_t;
		z_imag 			: kernel_data_t;
		c_real 			: kernel_data_t;
		c_imag 			: kernel_data_t;
		iteration		: iteration_t; 
		task_id 		: taskid_t; -- keeps track of which pipeline stage does which pixel
		pipe_start 		: std_logic;
		pipe_end 		: std_logic;
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
		done 			: std_logic;
		result 			: line_vector_t;
		line_n 			: integer range 0 to DISPLAY_HEIGHT-1;
	end record;

	


	signal r, r_in 			: kernel_reg;
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


    done <= r.done;
    result <= r.result;
    out_line_n <= r.line_n;


	comb_proc : process(r, 
						max_iter, in_valid, c0_real, c0_imag, in_p, in_line_n, ack, 
						mult0_res_s, mult1_res_s, mult2_res_s, add0_res_s, add1_res_s, add2_res_s, inc0_res_s, sub_res_s, comp0_res_s, comp1_res_s) 
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

		variable pix_next 					: std_logic;

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
		pix_next 	:= '0';

		in_inc <= '0';


		-- increment pipeline stage. do it before the FSM so it can be overwritten
		if r.pipeline_state = PIPELINE_DEPTH-1 then
			v.pipeline_state := 0;
			v.pipe_start := '0';
		else
			v.pipeline_state := r.pipeline_state+1;
		end if ;


		case( r.state ) is
		
			when idle =>
				if in_valid = '1' then
					v.c0_real := c0_real;
					v.c0_imag := c0_imag;
					v.p := in_p;
					v.line_n := in_line_n;
					v.pix_n := 0;
					v.pipeline_state := 0;
					v.pipe_start := '1';
					v.pipe_end := '0';
					in_inc <= '1';
					v.done := '0';
					v.state := busy;
				end if ;
		
			when busy =>
				case( r.pipeline_state ) is

					when 0 =>
						if (r.comp0_res='1' or r.comp1_res='1' or r.pipe_start = '1') then -- iteration finished or not yet started
							pix_next := '1';
							-- output result
							if r.pipe_start = '0' then
								v.result(r.task_id(0)) 	:= std_logic_vector(to_unsigned(r.iteration(0),16));		
							end if ;	
							-- input next z0 in pipeline slot
							if r.pipe_end = '0' then
								v.z_real(0) 		:= r.c0_real;
								v.z_imag(0) 		:= r.c0_imag;
								v.c_real(0)			:= r.c0_real;
								v.c_imag(0)			:= r.c0_imag;
								v.task_id(0) 		:= r.pix_n;
								v.iteration(0) 		:= 0;
							else
								v.done := '1';
								v.state := finished;
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

			when finished =>
				if ack = '1' then
					v.state := idle;
					v.done := '0';
				end if ;
		
		end case ;

		if pix_next = '1' then
			if r.pix_n = DISPLAY_WIDTH-1 then
				v.pipe_end := '1';
			else
				v.c0_real := std_logic_vector(signed(r.c0_real) + signed(r.p));
				v.pix_n := r.pix_n + 1;
			end if ;
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