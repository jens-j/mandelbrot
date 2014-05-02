library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity RAM_controller is
 	port (
		clk 		: in  std_logic;
		RAM_clk 	: out std_logic; -- for use in fifo's etc.
		burst_en 	: in  std_logic; -- set to change to burst mode
		-- write port signals
		write_data 	: in  data_vector_t;
		write_addr 	: in  std_logic_vector(22 downto 0);
		write_start	: in  std_logic;
		write_ready : out std_logic;
		-- read port
		read_addr 	: in  std_logic_vector(22 downto 0);
		read_start 	: in  std_logic;
		read_ready  : out std_logic;
		read_data	: out data_vector_t;
		-- RAM signal
		RAMWAIT 	: in  std_logic;
		RAMOEN 		: out std_logic;
		RAMCRE 		: out std_logic;
		RAMADVN 	: out std_logic;
		RAMWEN 		: out std_logic;
		RAMCEN 		: out std_logic;
		RAMUBN 		: out std_logic;
		RAMLBN 		: out std_logic;
		RAMCLK 		: out std_logic;
		MEMADR  	: out std_logic_vector(22 downto 0);
		MEMDB 		: inout std_logic_vector(15 downto 0)
  	) ;
end entity ; -- RAM_controller


architecture behavioural of RAM_controller is

	type state_t is (init,idle,ar0,ar1,ar2,br0,br1,br2,aw0,aw1,aw2,bw0,bw1,bw2);

	type RAM_cont_reg is record
		state 			: state_t;
		burst_mode 		: std_logic;
		count 			: integer range 0 to 31;
		read_start 		: std_logic;
		write_start 	: std_logic;
		set_burst_mode 	: std_logic;
		read_data 		: data_vector_t;
		read_addr 		: std_logic_vector(22 downto 0);
		write_data 		: data_vector_t;
		write_addr 		: std_logic_vector(22 downto 0);
		memadr 			: std_logic_vector(22 downto 0);
		ramoen 			: std_logic;
		ramcre 			: std_logic;
		ramadvn 		: std_logic;
		ramwen			: std_logic;
		ramcen 			: std_logic;
		counter 		: integer range 0 to 16000;
	end record;

	signal r 			: RAM_cont_reg;
	signal r_in 		: RAM_cont_reg;
	signal clk_int 		: std_logic := '0';
	signal clk_ext 		: std_logic := '0';
	signal clk_ext_ce 	: std_logic := '0';

begin


	clk_gen : entity work.RAM_clk_gated
	port map(
		CLK_IN1 		=> clk,
		CLK_OUT1		=> clk_int,
		CLK_OUT2_CE		=> clk_ext_ce, -- exeption when asynchronously setting to burstmode
		CLK_OUT2 		=> clk_ext
	);


	comb_proc : process(r,write_data,write_start,write_addr,read_addr,read_start,RAMWAIT,MEMDB,burst_en,clk_ext)
		variable v 			: RAM_cont_reg;
		variable memdb_v  	: std_logic_vector(15 downto 0);

	begin
		v 			:= r;
		memdb_v 	:= (others => 'Z');

		if burst_en = '1' and not (r.burst_mode = '1') then
			v.burst_mode 		:= '1';
			v.set_burst_mode 	:= '1';
 			v.write_start 		:= '1';
			v.write_addr 		:= "000" & x"81D1C"; 		
			v.ramcre 			:= '1';	
		elsif write_start = '1' and not (r.write_start = '1') then
			v.write_start 	:= '1';
			v.write_data 	:= write_data;
			v.write_addr 	:= write_addr; 
		end if ;
		if read_start = '1' and  not (r.read_start = '1') then
			v.read_start 	:= '1';
			v.read_addr 	:= read_addr;	 	 	
		end if ;


		if r.counter = 16000 then
			v.counter := 0;
		else
			v.counter := r.counter + 1;
		end if ;
		

		case( r.state ) is
			when init =>
				v.ramwen 		:= '1';
				v.ramoen 		:= '1';
				v.ramcen 		:= '1';
				v.ramcre 		:= '0';
				v.ramadvn 		:= '0';
				v.burst_mode 	:= '0';
				--if r.counter = 16000 then
					v.state 		:= idle;
				--end if ;

			when idle =>
				if r.set_burst_mode = '1' then
					v.state := aw0;
				elsif r.read_start = '1' then
					if r.burst_mode = '1' then
						v.state := br0;
					else
						v.state := ar0;	
					end if ;
				elsif r.write_start = '1' then
					if r.burst_mode = '1' and not (r.ramcre = '1') then -- exeption when asynchronously setting to burstmode
						v.state := bw0;
					else
						v.state := aw0;
					end if ;
				end if ;		

			when ar0 =>
				v.ramcen 		:= '0';
				v.ramoen 		:= '0';
				v.memadr 		:= r.read_addr;
				v.counter 		:= 0;
				v.state  		:= ar1;
			when ar1 =>
				if r.counter = 4 then
					v.state := ar2;
					v.read_data(0) := MEMDB;
				else
					v.counter := r.counter + 1;
				end if;
			when ar2 =>
				v.ramcen 		:= '1';
				v.ramoen 		:= '1';
				v.ramcre 		:= '0';
				v.read_start 	:= '0';
				v.state 		:= idle;

			when aw0 =>
				v.ramcen 		:= '0';
				v.ramoen 		:= '1';
				v.ramwen 		:= '0';
				v.counter 		:= 0;
				v.MEMADR 		:= r.write_addr;
				memdb_v 		:= r.write_data(0);
				v.state 		:= aw1;

			when aw1 =>
				memdb_v 		:= r.write_data(0);
				if r.counter = 4 then
					v.state := aw2;
				else
					v.counter := r.counter + 1;
				end if;

			when aw2 => 
				memdb_v 			:= r.write_data(0);
				v.ramcen 			:= '1';
				v.ramwen 			:= '1';
				v.ramcre 			:= '0';
				v.write_start 		:= '0';
				v.set_burst_mode 	:= '0';
				v.state 			:= idle;

			when bw0 =>
				v.ramcen 		:= '0';
				v.ramoen 		:= '1';
				v.ramadvn 		:= '0';
				v.ramwen 		:= '0';
				v.memadr 		:= r.write_addr;
				v.state 		:= bw1;

			when bw1 =>
				v.ramadvn 		:= '1';
				v.ramwen 		:= '1';
				if RAMWAIT = '0' then
					v.counter 	:= 0;
					v.state 	:= bw2;
				end if ;

			when bw2 =>
				if r.counter = 32 then
					v.ramcen 		:= '1';
					v.write_start 	:= '0';
					v.state 		:= idle;
				else
					memdb_v 		:= r.write_data(r.counter); 
					v.counter 		:= r.counter + 1;	
				end if ;
				
			when br0 =>
				v.ramcen 		:= '0';
				v.ramoen 		:= '0';
				v.ramadvn 		:= '0';
				v.ramwen 		:= '1';
				v.memadr 		:= r.read_addr;
				v.state 		:= br1;

			when br1 =>
				v.ramadvn 		:= '1';
				if RAMWAIT = '0' then
					v.counter 	:= 0;
					v.state 		:= br2; 
				end if ;

			when br2 =>
				if r.counter = 32 then
					v.ramcen 		:= '1';
					v.ramoen 		:= '1';
					v.read_start 	:= '0';
					v.state 		:= idle;
				else
					v.read_data(r.counter) := MEMDB;
					v.counter := r.counter + 1; 
				end if ;

		end case;

		RAM_clk  	<= clk_int;
		clk_ext_ce  <= r.burst_mode and not r.ramcre;
		RAMCLK 		<= clk_ext;
		RAMCEN 		<= r.ramcen;
		RAMCRE 		<= r.ramcre;
		RAMADVN 	<= r.ramadvn;
		RAMWEN 		<= r.ramwen;
		RAMOEN 		<= r.ramoen;
		RAMUBN 		<= '0';
		RAMLBN 		<= '0';
		MEMADR 		<= r.memadr;
		MEMDB 		<= memdb_v;	
		read_ready 	<= not r.read_start;
		write_ready <= not r.write_start;
		read_data 	<= r.read_data;
		r_in 		<= v;
	end process;


	reg_proc : process(clk_int)
	begin
		if rising_edge(clk_int) then 
		 	r <= r_in;				
		end if;
	end process;


end architecture ; -- behavioural