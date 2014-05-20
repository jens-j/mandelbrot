library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity mandelbrot_kernel is
  port (
  	-- global signals
	clk 			: in  	std_logic;
	max_iter 		: in  	integer range 0 to 65535;
	-- kernel specific
	io 				: inout kernel_io_t

	-- -- pixels coords of first pixel in 
	-- in_valid 		: in  std_logic;
	-- c0_real			: in  std_logic_vector(63 downto 0);
	-- c0_imag 		: in  std_logic_vector(63 downto 0);
	-- in_p 			: in  std_logic_vector(63 downto 0);
	-- chunk_n 		: in  integer range 0 to (DISPLAY_SIZE/CHUNK_SIZE)-1;
	-- in_req			: out std_logic;
	-- -- iteration numbers of entire line out
	-- ack 			: in  std_logic;
	-- done 			: out std_logic;
	-- out_chunk_n 	: out std_logic_vector(13 downto 0);
	-- result 			: out chunk_vector_t
	);	
end entity ; -- mandelbrot_kernel


architecture arch of mandelbrot_kernel is

	type state_t is (idle,busy,finished);
	type iteration_t is array (PIPELINE_DEPTH-1 downto 0) of integer range 0 to 65535;
	type taskid_t is array(PIPELINE_DEPTH-1 downto 0) of integer range 0 to CHUNK_SIZE-1; 
	
	type kernel_reg is record
		-- FSM states
		state 			: state_t;
		stage0_count 	: integer range 0 to PIPELINE_DEPTH-1;
		stage19_count	: integer range 0 to PIPELINE_DEPTH-1;
		stage20_count 	: integer range 0 to PIPELINE_DEPTH-1;
		-- pix coord (c) calculation
		c0_real 		: std_logic_vector(63 downto 0);
		c0_imag 		: std_logic_vector(63 downto 0);
		p 				: std_logic_vector(63 downto 0);
		pix_n 			: integer range 0 to CHUNK_SIZE-1;
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
		done 			: std_logic_vector(PIPELINE_DEPTH-1 downto 0);
		done_out 		: std_logic;
		result 			: chunk_vector_t;
		chunk_n 		: std_logic_vector(13 downto 0);
		-- input 
		in_req 			: std_logic;
	end record;

	
	constant BOUNDARY  : std_logic_vector(63 downto 0) := x"4000000000000000";

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
	signal comp1_op1_s		: std_logic_vector(1 downto 0);
	signal comp1_op2_s 		: std_logic_vector(63 downto 0);
	signal comp1_op3_s 		: std_logic_vector(63 downto 0);	
	signal comp1_res_s		: std_logic;


begin

	multiplier0 : entity work.mult_64x64_14st  
	port map (
      clk   => clk,
      a     => mult0_op1_s,
      b     => mult0_op2_s,
      p 	=> mult0_res_s
    );

	multiplier1 : entity work.mult_64x64_14st  
	port map (
      clk   => clk,
      a     => mult1_op1_s,
      b     => mult1_op2_s,
      p 	=> mult1_res_s
    );

    multiplier2 : entity work.mult_64x64_14st  
    port map (
      clk   => clk,
      a     => mult2_op1_s,
      b     => mult2_op2_s,
      p 	=> mult2_res_s
    );



	comb_proc : process(r, max_iter, io, 
						mult0_res_s, mult1_res_s, mult2_res_s, add0_res_s, add1_res_s, add2_res_s, inc0_res_s, sub_res_s, comp0_res_s, comp1_res_s) 
		variable v 							: kernel_reg;
		variable inc0_op_v 					: integer range 0 to 65535;
		variable comp1_op1_v 				: std_logic_vector(1 downto 0); 
		variable comp1_op2_v, comp1_op3_v	: std_logic_vector(63 downto 0); 
		variable sub_op1_v, sub_op2_v 		: std_logic_vector(63 downto 0);
		variable comp0_op1_v, comp0_op2_v 	: integer range 0 to 65535;
		variable mult0_op1_v, mult0_op2_v, mult1_op1_v, mult1_op2_v, mult2_op1_v, mult2_op2_v 					: std_logic_vector(63 downto 0);
		variable add0_op1_v, add0_op2_v, add1_op1_v, add1_op2_v, add2_op1_v, add2_op2_v, add3_op1_v, add3_op2_v : std_logic_vector(63 downto 0);
		
		variable result_v 					: std_logic_vector(15 downto 0);

		variable pix_next 					: std_logic;

		variable v_z_real, v_z_imag : std_logic_vector (63 downto 0);

	begin
		v 			:= r;
		sub_op1_v 	:= (others => '0');
		sub_op2_v 	:= (others => '0');
		comp0_op1_v := 0;
		comp0_op2_v	:= 1;
		comp1_op1_v	:= (others => '0');
		comp1_op2_v	:= (others => '0');
		comp1_op3_v	:= (others => '0');
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

		result_v 	:= (others=>'0');
		pix_next 	:= '0';

		


		-- increment pipeline stage. do it before the FSM so it can be overwritten
		if r.stage0_count = PIPELINE_DEPTH-1 then
			v.stage0_count := 0;
			v.pipe_start := '0';
		else
			v.stage0_count := r.stage0_count+1;
		end if ;

		if r.stage19_count = PIPELINE_DEPTH-1 then
			v.stage19_count := 0;
		else
			v.stage19_count := r.stage19_count+1;
		end if ;

		if r.stage20_count = PIPELINE_DEPTH-1 then
			v.stage20_count := 0;
		else
			v.stage20_count := r.stage20_count+1;
		end if ;



		case( r.state ) is
		
			when idle =>
				v.in_req := '1';
				if io.chunk_valid = '1' then
					v.c0_real := io.chunk_x;
					v.c0_imag := io.chunk_y;
					v.p := io.p;
					v.chunk_n := std_logic_vector(to_unsigned(io.chunk_n,14));
					v.pix_n := 0;
					v.stage0_count := 0;
					v.stage19_count := 2;
					v.stage20_count := 1;
					v.pipe_start := '1';
					v.pipe_end := '0';
					v.in_req := '0';
					v.done := (PIPELINE_DEPTH-1 downto 0 => '0');
					v.done_out := '0';
					v.state := busy;
				end if ;
		
			when busy =>

				-- STAGE 0
				if (r.comp0_res='1' or r.comp1_res='1' or r.pipe_start = '1') then -- iteration finished or not yet started
					pix_next := '1';
					-- output result
					if r.pipe_start = '0' and r.done(r.stage0_count) = '0' then
						v.result(r.task_id(r.stage0_count)) 	:= std_logic_vector(to_unsigned(r.iteration(r.stage0_count),16));		
					end if ;	
					-- input next z0 in pipeline slot
					if r.pipe_end = '0' then
						v_z_real 						:= r.c0_real;
						v_z_imag 						:= r.c0_imag;
						v.c_real(r.stage0_count)		:= v_z_real;
						v.c_imag(r.stage0_count)		:= v_z_imag;
						v.task_id(r.stage0_count) 		:= r.pix_n;
						v.iteration(r.stage0_count) 	:= 0;
					else
						v.done(r.stage0_count) 			:= '1';
						v_z_real 						:= (others => '0');
						v_z_imag 						:= (others => '0');
					end if ;
				else -- else: continue iteration
					v_z_real 						:= r.add1_res;
					v_z_imag 						:= r.add2_res;
				end if ;
				v.z_real(r.stage0_count) 	:= v_z_real;
				v.z_imag(r.stage0_count) 	:= v_z_imag;
				mult0_op1_v		 			:= v_z_real;
				mult0_op2_v 				:= v_z_real;
				mult1_op1_v 				:= v_z_imag;
				mult1_op2_v 				:= v_z_imag;
				mult2_op1_v 				:= v_z_real;
				mult2_op2_v 				:= v_z_imag;

				-- STAGE 19
				inc0_op_v 						:= r.iteration(r.stage19_count);
				v.iteration(r.stage19_count) 	:= inc0_res_s;	
				add0_op1_v 						:= mult0_res_s;
				add0_op2_v 						:= mult1_res_s;
				sub_op1_v 						:= mult0_res_s;
				sub_op2_v 						:= mult1_res_s;

				-- STAGE 20
				add2_op2_v 	:= r.c_imag(r.stage20_count);
				comp0_op1_v := r.iteration(r.stage20_count);		
				add1_op2_v 	:= r.c_real(r.stage20_count);		
				add1_op1_v 	:= r.sub_res;
				add2_op1_v 	:= r.imag_temp;
				comp0_op2_v := max_iter;
				comp1_op1_v := r.add0_res(63 downto 62);	
				comp1_op2_v := r.z_real(r.stage20_count);--(63 downto 61);
				comp1_op3_v := r.z_imag(r.stage20_count);--(63 downto 61);

				-- check if line is done 
				if v.done = (PIPELINE_DEPTH-1 downto 0 => '1') then
					v.done_out := '1';
					v.state := finished;
				end if ;


			when finished =>
				if io.ack = '1' then
					v.state := idle;
					v.done_out := '0';
				end if ;
		end case ;


		if pix_next = '1' then
			if r.pix_n = CHUNK_SIZE-1 then
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
		comp1_op1_s <= comp1_op1_v;
		comp1_op2_s <= comp1_op2_v;
		comp1_op3_s <= comp1_op3_v;
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

		-- link register to outputs 
		io.done 		<= r.done_out;
    	io.result 		<= r.result;
    	io.out_chunk_n 	<= r.chunk_n;
   	 	io.req_chunk 	<= r.in_req;

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

	comperator1 : process(comp1_op1_s, comp1_op2_s, comp1_op3_s)
	begin
		-- if to_integer(unsigned(comp1_op_s)) > to_integer(unsigned(BOUNDARY)) then -- |z| > 4.0
		-- 	comp1_res_s <= '1';
		-- else
		-- 	comp1_res_s <= '0';
		-- end if ;

		comp1_res_s <= '0';

		if comp1_op1_s(1)='1' or comp1_op1_s(0)='1' then -- |Z|^2 >= 4
			comp1_res_s <= '1';
		end if ;

		if (signed(comp1_op2_s) >= x"2000000000000000") or (signed(comp1_op2_s) <= x"E000000000000000") then -- -2 <= x <= 2
			comp1_res_s <= '1';
		end if ;

		if (signed(comp1_op3_s) >= x"2000000000000000") or (signed(comp1_op3_s) <= x"E000000000000000") then -- -2 <= x <= 2
			comp1_res_s <= '1';
		end if ;

		-- if 	( comp1_op2_s(63)='0' and (comp1_op2_s(62)='1' or comp1_op2_s(61) = '1') ) or ( comp1_op2_s(63)='1' and (comp1_op2_s(62)='0' or comp1_op2_s(61)='0' or (comp1_op2_s(60 downto 0) = (60 downto 0 => '0'))) ) then
		-- 	comp1_res_s <= '1';
		-- end if ;

		-- if 	( comp1_op3_s(63)='0' and (comp1_op3_s(62)='1' or comp1_op3_s(61) = '1') ) or ( comp1_op3_s(63)='1' and (comp1_op3_s(62)='0' or comp1_op3_s(61)='0' or (comp1_op3_s(60 downto 0) = (60 downto 0 => '0'))) ) then
		-- 	comp1_res_s <= '1';
		-- end if ;

		-- if (comp1_op2_s(2)='1' or comp1_op2_s(1)='1' or comp1_op2_s(0)='1') and (comp1_op2_s(2)='0' or comp1_op2_s(1)='0' or comp1_op2_s(0)='0') then -- |Zx| >= 2
		-- 	comp1_res_s <= '1';
		-- end if ;

		-- if (comp1_op3_s(2)='1' or comp1_op3_s(1)='1' or comp1_op3_s(0)='1') and (comp1_op3_s(2)='0' or comp1_op3_s(1)='0' or comp1_op3_s(0)='0') then -- |Zy| >= 2
		-- 	comp1_res_s <= '1';
		-- end if ;		
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