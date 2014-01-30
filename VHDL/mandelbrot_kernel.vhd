library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity mandelbrot_kernel is
  port (
	clk 		: in  std_logic;
	orig_real	: in  std_logic_vector(63 downto 0);
	orig_imag 	: in  std_logic_vector(63 downto 0);
	pix_size 	: in  std_logic_vector(63 downto 0);
	max_iter 	: in  integer range 0 to 65535;
	start 		: in  std_logic;
	done 		: out std_logic;
	result 		: out kernel_output_t
	);
end entity ; -- mandelbrot_kernel


architecture arch of mandelbrot_kernel is

	type state_t is (idle,busy,ready);
	type iteration_t is array (PIPELINE_DEPTH-1 downto 0) of integer range 0 to 65535;
	type taskid_t is array(PIPELINE_DEPTH-1 downto 0) of integer range 0 to 479; 
	
	type kernel_reg is record
		-- latched input data. constant during calculation of one scanline
		z0_imag 		: std_logic_vector(63 downto 0); -- is the same for each pixel in a row
		pix_size 		: std_logic_vector(63 downto 0);
		max_iter 		: integer range 0 to 65535;
		-- algorithm data
		z_real 			: kernel_data_t;
		z_imag 			: kernel_data_t;
		z0_real 		: kernel_data_t;
		iteration		: iteration_t; 
		state 			: state_t;
		pipeline_state 	: integer range 0 to PIPELINE_DEPTH-1;
		startup			: std_logic; -- bit indicating the pipeline is doing the first run of a scanline; meaning the pipeline produces no results yet
		--pipeline registers
		sub_res 		: std_logic_vector(63 downto 0);
		comp0_res  		: std_logic;
		comp1_res  		: std_logic;
		add0_res 		: std_logic_vector(63 downto 0);
		add1_res 		: std_logic_vector(63 downto 0);
		add2_res 		: std_logic_vector(63 downto 0);
		add3_res 		: std_logic_vector(63 downto 0);
		inc_res 		: integer range 0 to 65535;
		imag_temp 		: std_logic_vector(63 downto 0); -- the product 2*x*y is kept idle for one stage  
		-- input feeder data
		p_x 			: integer range 0 to 479; -- relative pixel x/real coordinate
		next_real 		: std_logic_vector(63 downto 0);
		-- output
		result 			: kernel_output_t;
		tasks 			: taskid_t; -- keeps track of which pipeline stage does which pixel
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
	-- next_real = z0_real + pixsize
	signal add3_op1_s 		: std_logic_vector(63 downto 0);
	signal add3_op2_s 		: std_logic_vector(63 downto 0);
	signal add3_res_s 		: std_logic_vector(63 downto 0);
	-- interation++
	signal inc0_op_s 		: integer range 0 to 65535;
	signal inc0_res_s 		: integer range 0 to 65535;
	-- increment pixel counter 
	signal inc1_op_s 		: integer range 0 to DISPLAY_WIDTH-1;
	signal inc1_res_s 		: integer range 0 to DISPLAY_WIDTH-1;
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
      a     => mult0_op1,
      b     => mult0_op2,
      p 	=> mult0_res
    );

    multiplier1 : entity work.mult64x64
    port map (
      clk   => clk,
      a     => mult1_op1,
      b     => mult1_op2,
      p 	=> mult1_res
    );

    multiplier2 : entity work.mult64x64
    port map (
      clk   => clk,
      a     => mult2_op1,
      b     => mult2_op2,
      p 	=> mult2_res
    );



	comb_prov : process(r, orig_imag, orig_real, pix_size, max_iter, start, mult0_res_s, mult1_res_s, mult2_res_s, add0_res_s, add1_res_s, add2_res_s, add3_res_s, inc0_res_s, sub_res_s, comp0_res_s, comp1_res_s) 
		variable v 							: kernel_reg;
		variable inc0_op_v 					: integer range 0 to DISPLAY_WIDTH-1;
		variable inc1_op_v 					: integer range 0 to 65535;  
		variable comp1_op_v 				: std_logic_vector(3 downto 0); 
		variable sub_op1_v, sub_op2_v 		: std_logic_vector(63 downto 0);
		variable comp0_op1_v, comp0_op2_v 	: integer range 0 to 65535;
		variable mult0_op1_v, mult0_op2_v, mult1_op1_v, mult1_op2_v, mult2_op1_v, mult2_op2_v 					: std_logic_vector(63 downto 0);
		variable add0_op1_v, add0_op2_v, add1_op1_v, add1_op2_v, add2_op1_v, add2_op2_v, add3_op1_v, add3_op2_v : std_logic_vector(63 downto 0);

	begin
		v 			:= r;
		sub_op1_v 	:= (others => '0');
		sub_op2_v 	:= (others => '0');
		comp0_op1_v := 0;
		comp0_op2_v	:= 0;
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
		add3_op1_v 	:= (others => '0');
		add3_op2_v 	:= (others => '0');
		inc0_op_v 	:= 0;
		inc1_op_v 	:= 0;


		case( r.state ) is

			when idle =>
				v.pipeline_state 	:= 0;
				v.iteration 		:= (0,0,0,0,0,0,0);
				v.p_x 				:= 0;
				v.startup 			:= '1';
				if start = '1' then
					v.next_real := orig_real;
					v.z0_imag 	:= orig_imag;
					v.pix_size 	:= pix_size;
					v.state 	:= busy;
				end if ;
		
			when busy =>

				-- this part is independent of the pipeline stage
				if (r.comp0_res='1' or r.comp1_res='1') then
					-- create new next z0
					add3_op1_v 		:= r.next_real;
					add3_op2_v 		:= r.pix_size;
					v.next_real 	:= add3_res_s;
					-- increment pixel counter 
					if r.p_x = DISPLAY_WIDTH-1 then
						v.state 	:= ready;
					else
						inc1_op_v 	:= r.p_x;
						v.p_x 		:= inc1_res_s;
					end if ;
				end if ;
				

				case( r.pipeline_state ) is

					when 0 =>
						if (r.comp0_res='1' or r.comp1_res='1' or r.startup='1') then
							-- store result
							if r.startup = '0' then
								v.result(r.tasks(0)) := std_logic_vector(to_unsigned(r.iteration(0),16));								
							end if ;
							-- input next z0 in pipeline slot
							v.z_real(0) 		:= r.next_real;
							v.z_imag(0) 		:= r.z0_imag;
							v.z0_real(0)		:= r.next_real;
						else
							v.z_real(0) 		:= r.add1_res;
							v.z_imag(0) 		:= r.add2_res;
						end if ;

						mult0_op1_v := v.z_real(0);
						mult0_op1_v := v.z_real(0);
						mult1_op1_v := v.z_imag(0);
						mult1_op1_v := v.z_imag(0);
						mult2_op1_v := v.z_real(0);
						mult2_op1_v := v.z_imag(0);

					when 1 =>

					when 2 =>
						add0_op1_v 		:= mult0_res_s;
						add0_op2_v 		:= mult1_res_s;
						sub_op1_v 		:= mult0_res_s;
						sub_op2_v 		:= mult1_res_s;
						inc0_op_v 		:= r.iteration(0);
						v.iteration(0) 	:= inc0_res_s;	

					when 3 =>
						add1_op1_v 	:= r.sub_res;
						add1_op2_v 	:= r.z0_real(0);
						add2_op1_v 	:= r.imag_temp;
						add2_op2_v 	:= r.z0_imag;
						comp0_op1_v := r.iteration(0);
						comp0_op2_v := r.max_iter;
						comp1_op_v 	:= r.add0_res(63 downto 60);
				
				end case ;

				if r.pipeline_state = 20 then
					v.pipeline_state 	:= 0;
					v.startup 			:= '0';
				else
					v.pipeline_state := r.pipeline_state+1;
				end if ;

			when ready =>

		
		end case ;

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
		add3_op1_s 	<= add2_op1_v;
		add3_op2_s 	<= add2_op2_v;
		inc0_op_s 	<= inc0_op_v;
		inc1_op_s 	<= inc1_op_v;
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
		if comp0_op1_s > comp0_op2_s then
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

	adder3 : process(add3_op1_s, add3_op2_s)
	variable res : std_logic_vector(64 downto 0);
	begin
		add3_res_s <= std_logic_vector(signed(add3_op1_s) + signed(add3_op2_s));
	end process;

	incrementer0 : process(inc0_op_s)
	begin
		inc0_res_s <= inc0_op_s + 1;
	end process;

	incrementer1 : process(inc1_op_s)
	begin
		inc1_res_s <= inc1_op_s + 1;
	end process;

end architecture ; -- arch