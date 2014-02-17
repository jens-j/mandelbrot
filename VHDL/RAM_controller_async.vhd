library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.mandelbrot_pkg.all;


entity RAM_controller_async is
 	port (
		CLK 		: in  std_logic;
		reset 		: in  std_logic;
		RAM_ready 	: out std_logic; -- indicates if the ram is initialized 
		-- write port signals
		write_data 	: in  std_logic_vector(15 downto 0);
		write_addr 	: in  std_logic_vector(22 downto 0);
		write_start	: in  std_logic;
		write_done 	: out std_logic;
		-- read port
		read_data	: out std_logic_vector(15 downto 0);
		read_addr 	: in  std_logic_vector(22 downto 0);
		read_start 	: in  std_logic;
		read_done 	: out std_logic;
		-- RAM signal
		RAMCLK 		: out std_logic;
		RAMCRE 		: out std_logic;
		RAMADVN 	: out std_logic;
		RAMWEN 		: out std_logic;
		RAMCEN 		: out std_logic;
		RAMOEN 		: out std_logic;
		RAMLBN 		: out std_logic;
		RAMUBN 		: out std_logic;
		MEMADR  	: out std_logic_vector(22 downto 0);
		MEMDB 		: inout std_logic_vector(15 downto 0)
  	) ;
end entity ; -- RAM_controller


architecture behavioural of RAM_controller_async is

	type state_t is (init0,init1,idle,waiting,reading,writing);

	type RAM_cont_reg is record
		state 			: state_t;
		count 			: integer;
		read_start 		: std_logic;
		write_start 	: std_logic;
		read_done 		: std_logic;
		write_done 		: std_logic;
		read_data 		: std_logic_vector(15 downto 0);
		read_addr 		: std_logic_vector(22 downto 0);
		write_data 		: std_logic_vector(15 downto 0);
		write_addr 		: std_logic_vector(22 downto 0);
		memadr 			: std_logic_vector(22 downto 0);
		RAM_ready 		: std_logic;
		ramwen			: std_logic;
		ramcen 			: std_logic;
		ramoen 			: std_logic;
		rw 				: std_logic; -- indicates if a read or write is done. used in the statemachine
	end record;

	signal r 	: RAM_cont_reg;
	signal r_in : RAM_cont_reg;

begin


	comb_proc : process(r,write_data,read_start,write_start,write_addr,read_addr,MEMDB)
		variable v 			: RAM_cont_reg;
		variable memdb_v  	: std_logic_vector(15 downto 0);

	begin
		v 			:= r;
		memdb_v 	:= (others => 'Z');

		if read_start = '1' and  not (v.read_start = '0') and r.RAM_ready = '1' then
			v.read_start 	:= '1';
			v.read_done 	:= '0';
			v.read_addr 	:= read_addr;	 	 	
		end if ;
		if write_start = '1' and not (v.write_start = '0') and r.RAM_ready = '1' then
			v.write_start 	:= '1';
			v.write_done 	:= '0';
			v.write_data 	:= write_data;
			v.write_addr 	:= write_addr; 
		end if ;


		case( r.state ) is

			when init0 => 
				v.RAM_ready 	:= '0';
				v.count			:= 0;
				v.ramcen 		:= '1';
				v.ramoen 		:= '1';
				v.ramwen 		:= '1';
				v.state 	  	:= init1;

			when init1 => -- wait 150 us for the RAM device to initialize
				if r.count = 16000 then
					v.RAM_ready 	:= '1';
					v.state 	:= idle;
				else
					v.count := r.count + 1;
				end if ;
		
			when idle =>
				if r.read_start = '1' then
					v.memadr 	:= r.read_addr;
					v.ramcen 	:= '0';
					v.ramoen 	:= '0';
					v.ramwen 	:= '1';
					v.count 	:= 0;
					v.rw 		:= '0';
					v.state 	:= waiting;
				elsif r.write_start = '1' then
					v.memadr 	:= r.write_addr;
					v.ramcen 	:= '0';
					v.ramoen 	:= '1';
					v.ramwen 	:= '0';
					v.count 	:= 0;
					v.rw 		:= '1';
					v.state 	:= waiting;
				end if ;
		
			when waiting =>
				if r.rw = '1' then
					memdb_v 	:= r.write_data;
				end if ;
				if r.count = 6 then
					if r.rw = '0' then
						v.state := reading;
					else
						v.state := writing;
					end if ;
				else
					v.count := r.count + 1;
				end if ;

			when reading =>
				v.read_data 	:= MEMDB;
				v.ramcen 		:= '1';
				v.ramoen 		:= '1';
				v.read_start 	:= '0';
				v.read_done 	:= '1';
				v.state 		:= idle;

			when writing =>
				memdb_v 		:= r.write_data;
				v.ramcen 		:= '1';
				v.ramwen 		:= '1';
				v.write_start 	:= '0';
				v.write_done 	:= '1';
				v.state 		:= idle;
			when others =>
		
		end case ;

		-- constants
		RAMCLK 		<= '0';
		RAMADVN 	<= '0';
		RAMUBN 		<= '0';
		RAMLBN 		<= '0';
		RAMCRE 		<= '0';
		-- interface signals
		RAM_ready 	<= r.RAM_ready;
		read_data 	<= r.read_data;
		read_done 	<= r.read_done;
		write_done 	<= r.write_done;
		-- RAM signals
		RAMOEN 		<= r.ramoen;
		RAMCEN 		<= r.ramcen;
		RAMWEN 		<= r.ramwen;
		MEMADR 		<= r.memadr;
		MEMDB 		<= memdb_v;	
		
		r_in 		<= v;
	end process;


	reg_proc : process(CLK)
	begin
		if rising_edge(CLK) then 
			if reset = '1' then
				r.state <= init0;
			else
		 		r <= r_in;				
			end if ;
		end if;
	end process;


end architecture ; -- behavioural