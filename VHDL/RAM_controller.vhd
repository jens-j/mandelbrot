library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity RAM_controller is
 	port (
		RAM_clk 	: in  std_logic;
		reset 		: in  std_logic;
		RAM_ready 	: out std_logic; -- indicates if the ram is initialized 
		-- write port signals
		write_data 	: in  data_vector_t;
		write_addr 	: in  std_logic_vector(17 downto 0);
		write_start	: in  std_logic;
		-- read port
		read_addr 	: in  std_logic_vector(17 downto 0);
		read_start 	: in  std_logic;
		read_data	: out data_vector_t;
		-- RAM signal
		RAMWAIT 	: in  std_logic;
		RAMCRE 		: out std_logic;
		RAMADVN 	: out std_logic;
		RAMWEN 		: out std_logic;
		RAMCEN 		: out std_logic;
		MEMADR  	: out std_logic_vector(22 downto 0);
		MEMDB 		: inout std_logic_vector(15 downto 0)
  	) ;
end entity ; -- RAM_controller


architecture behavioural of RAM_controller is

	type state_t is (init0,init1,init2,init3,init4,init5,init6,init7,init8,idle,r0,r1,r2,r3,w0,w1,w2,w3);

	type RAM_cont_reg is record
		state 			: state_t;
		count 			: integer range 0 to 31;
		read_start 		: std_logic;
		write_start 	: std_logic;
		read_data 		: data_vector_t;
		read_addr 		: std_logic_vector(17 downto 0);
		write_data 		: data_vector_t;
		write_addr 		: std_logic_vector(17 downto 0);
		memadr 			: std_logic_vector(22 downto 0);
		RAM_ready 		: std_logic;
		ramcre 			: std_logic;
		ramadvn 		: std_logic;
		ramwen			: std_logic;
		ramcen 			: std_logic;
		init_counter 	: integer;
	end record;

	signal r 	: RAM_cont_reg;
	signal r_in : RAM_cont_reg;

begin


	comb_proc : process(r,write_data,write_start,write_addr,read_addr,read_start,RAMWAIT,MEMDB,RAM_clk)
		variable v 			: RAM_cont_reg;
		variable memdb_v  	: std_logic_vector(15 downto 0);

	begin
		v 			:= r;
		memdb_v 	:= (others => 'Z');

		if read_start = '1' and  not (v.read_start = '0') and r.RAM_ready = '1' then
			v.read_start 	:= '1';
			v.read_addr 	:= read_addr;	 	 	
		end if ;
		if write_start = '1' and not (v.write_start = '0') and r.RAM_ready = '1' then
			v.write_start 	:= '1';
			v.write_data 	:= write_data;
			v.write_addr 	:= write_addr; 
		end if ;


		case( r.state ) is

			when init0 => 
				v.RAM_ready 	:= '0';
				v.init_counter 	:= 0;
				v.ramcen 		:= '1';
				v.ramcre 		:= '0';
				v.ramadvn 		:= '0';
				v.ramwen 		:= '1';
				v.state 	  	:= init1;

			when init1 => -- wait 150 us for the RAM device to initialize
				if r.init_counter = 16000 then
					v.state 	:= init2;
				else
					v.init_counter := r.init_counter + 1;
				end if ;

			when init2 => -- set the RAM device to synchronous burst mode through an ansynchronous write to BCR 
				v.memadr 	:= "000" & "10" & "00" & x"1C1C";
				v.ramcre 	:= '1';
				v.ramadvn 	:= '0';
				v.ramwen 	:= '0';
				v.ramcen 	:= '0';
				v.state 	:= init3;

			when init3 =>
				v.ramadvn 		:= '1'; -- latch data on address bus
				v.init_counter 	:= 0;
				v.state 		:= init4;  

			when init4 =>
				if r.init_counter = 4 then -- wait ~50 ns (comply to tWP / write pulse width) 
					v.state 	:= init5;
				else
					v.init_counter := r.init_counter + 1;
				end if ;	   

			when init5 =>
				v.ramwen 		:= '1';
				v.ramcre 		:= '0';
				v.RAM_ready 	:= '1';
				v.state 		:= idle;
		
			when idle =>
				v.ramcen 		:= '1'; -- disable ram (required for refresh)
				if r.read_start = '1' then
					v.state 	:= r0;
				elsif r.write_start = '1' then
					v.state 	:= w0;

				end if ;
		
			when r0 =>
				v.memadr 	:= r.read_addr & "00000";
				v.ramcen 	:= '0';
				v.ramadvn 	:= '0';
				v.ramwen 	:= '1';
				v.count 	:= 0;
				v.state 	:= r1;

			when r1 =>
				v.ramadvn 	:= '1';
				if RAMWAIT = '0' then
					v.state := r2;
				end if ;

			when r2 =>
				v.read_data(r.count) 	:= MEMDB;	
				if r.count = 31 then
					v.ramcen 		:= '1';
					v.read_start 	:= '0';
					v.state 		:= idle;	
				else
					v.count 				:= r.count + 1;	
				end if ;

			when w0 =>
				v.memadr 	:= r.write_addr & "00000";
				v.ramcen 	:= '0';
				v.ramadvn 	:= '0';
				v.ramwen 	:= '0';
				v.count 	:= 1;
				v.state 	:= w1;

			when w1 =>
				v.ramadvn 	:= '1';
				v.ramwen 	:= '1';
				if RAMWAIT = '0' then
					v.state := w2;
					memdb_v := r.write_data(0);
				end if ;
				
			when w2 =>
				memdb_v 	:= r.write_data(r.count);
				if r.count = 31 then
					v.ramcen 		:= '1';
					v.write_start 	:= '0';
					v.state 		:= idle;
				else
					v.count 	:= r.count + 1;		
				end if ;

			when others =>
		
		end case ;

		--if r.RAM_ready = '1' then
		--	RAMCLK <= RAM_clk;
		--else
		--	RAMCLK <= '0';
		--end if ;

		RAMCEN 		<= r.ramcen;
		RAMCRE 		<= r.ramcre;
		RAMADVN 	<= r.ramadvn;
		RAMWEN 		<= r.ramwen;
		MEMADR 		<= r.memadr;
		MEMDB 		<= memdb_v;	
		RAM_ready 	<= r.RAM_ready;
		r_in 		<= v;
	end process;


	reg_proc : process(RAM_clk)
	begin
		if rising_edge(RAM_clk) then 
			if reset = '1' then
				r.state <= init0;
			else
		 		r <= r_in;				
			end if ;
		end if;
	end process;


end architecture ; -- behavioural