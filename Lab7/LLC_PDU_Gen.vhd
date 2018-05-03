----------------------------------------------------------------------------------
-- Company: 		 Binghamton University
-- Engineer:	    
-- 
-- Create Date:    20:47:35 04/18/2011 
-- Design Name: 	 LLC PDU Generator
-- Module Name:    LLC_PDU_Gen - Behavioral 
-- Project Name:   Lab7
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Local_Functions.ALL;

entity LLC_PDU_Gen is
    Port ( rst : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           gen_PDU : in  STD_LOGIC;
           data_out : out  STD_LOGIC_VECTOR (7 downto 0);
           data_ready : out  STD_LOGIC;
           data_ack : in  STD_LOGIC;
           PDU_length : out  STD_LOGIC_VECTOR (7 downto 0));
end LLC_PDU_Gen;

architecture Behavioral of LLC_PDU_Gen is

	component Data_Buffer 
		 Port ( data_in : in  STD_LOGIC_VECTOR (7 downto 0);
				  data_out : out  STD_LOGIC_VECTOR (7 downto 0);
				  addr_in : in  unsigned (4 downto 0);
				  write_clk : in  STD_LOGIC;
				  write_enable : in  STD_LOGIC);
	end component;

	-- data_buffer constants
	-- these constants set the size of the data buffer 
	-- (32 memory locations deep by 8 bits wide)
	constant DATA_SIZE : integer := 8;
	constant ADDR_SIZE : integer := 5;
	constant MAX_ADDR : std_logic_vector (ADDR_SIZE-1 downto 0) := (others => '1');
	-- data_buffer interface signals
	signal buffer_data_in : std_logic_vector (DATA_SIZE-1 downto 0) := (others => '0');
	signal buffer_data_out : std_logic_vector (DATA_SIZE-1 downto 0);
	signal buffer_addr : unsigned (ADDR_SIZE-1 downto 0) := (others => '0');
	signal PDU_length_reg : unsigned (DATA_SIZE-1 downto 0) := (others => '0');

	-- random bit generator constants and signals
	constant SEED : std_logic_vector (DATA_SIZE-1 downto 0) 
											:= (DATA_SIZE-1 => '1', 0 => '1' , others => '0');		
	constant P : std_logic_vector(DATA_SIZE-1 downto 0) := "10111000"; 
											-- Primitive Polynomial for 8-bits
	signal shift_reg : std_logic_vector (DATA_SIZE-1 downto 0) := (others => '0');

	-- Signals for State Machine used to control the Data Buffer
	-- declare state and next_state
	type state_type is (st1_idle, st2_det_length, st3_load, stabilize, st4_write, st5_inc, st6_rst_addr, st7_notify, st8_inc, st9_check_done); 
	signal state, next_state : state_type := st1_idle; 
	-- declare state machine outputs
	signal rst_addr  : std_logic;  -- reset address register 
	signal increment_addr  : std_logic;  -- increment address register
	signal load_data_reg  : std_logic;  -- load data register
	signal buffer_we  : std_logic;  -- buffer write enable
	signal buffer_wclk  : std_logic;  -- buffer write clock
	signal load_PDU_length  : std_logic;  -- load PDU length register
	signal buffer_out_ready : std_logic := '0'; 
 
begin

	-- 32 x 8 bit RAM data buffer
	LLC_Data_Buffer : Data_Buffer
		 Port map ( data_in => buffer_data_in ,
						data_out => buffer_data_out ,
						addr_in => buffer_addr ,
						write_clk => buffer_wclk ,
						write_enable => buffer_we );

	-- (shift_reg)
	-- random number generator shift register
	-- size of shift_reg is DATA_SIZE (bits 0 to SIZE-1)
	-- shift_reg is initialized to the SEED value at reset
	-- implemented as Fibonacci LFSR

		process(clk)
			variable lsb_in : std_logic := '0';
		begin
			if rising_edge(clk) then
				if rst = '1' then
					shift_reg <= seed;
				else
					lsb_in := '0';
					for I in DATA_SIZE-1 downto 0 loop
						lsb_in := lsb_in xor (shift_reg(I) and P(I));
					end loop;

					for I in DATA_SIZE-1 downto 1 loop
						shift_reg(I) <= shift_reg(I - 1);
					end loop;
					shift_reg(0) <= lsb_in;
				end if;
			end if;
		end process;

	-- (buffer_data_in) 
	-- buffer input data register 
	-- samples the random bit generator shift register 
	--    to load random data into the data buffer

	process(clk) begin
		if rising_edge(clk) then
			if load_data_reg = '1' then
				buffer_data_in <= shift_reg;
			else
				buffer_data_in <= buffer_data_in;
			end if;
		end if;
	end process;

	-- (buffer_addr) 
	-- buffer address register 
	-- reset at beginning of writes to the buffer
	-- incremented after each write cycle

	process(clk) begin
		if rising_edge(clk) then
			if rst_addr = '1' then
				buffer_addr <= to_unsigned(0, buffer_addr'length);
			elsif increment_addr = '1' then
				buffer_addr <= buffer_addr + to_unsigned(1, buffer_addr'length);
			else
				buffer_addr <= buffer_addr;
			end if;
		end if;
	end process;


	-- (PDU_length_reg)
	-- PDU length register
	-- this register is one byte long, but we are limiting the number 
	-- 	of bytes of data to be in the range of 1 to 32
	-- therefore, load from the random number shift_reg bits
	-- load random number from bit 0 up to  bit ADDR_SIZE-1
	-- if random number is zero, load with a value of 32 
	-- 	set bit ADDR_SIZE to '1'
	-- 	set bits above bit ADDR_SIZE to '0'
	-- the register is loaded when control signal load_PDU_length = '1'

	process(clk) begin
		if rising_edge(clk) then
			PDU_length_reg(7 downto 6) <= "00";
			if load_PDU_length = '1' then
				PDU_length_reg(ADDR_SIZE-1 downto 0) <= unsigned(shift_reg(ADDR_SIZE-1 downto 0));
				if unsigned(shift_reg(ADDR_SIZE-1 downto 0)) = to_unsigned(0, ADDR_SIZE) then
					PDU_length_reg(ADDR_SIZE) <= '1';
				else
					PDU_length_reg(ADDR_SIZE) <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Data Buffer Controller FSM

	process(clk) begin
		if rising_edge(clk) then
			if rst='1' then
				state <= st1_idle;
			else
				state <= next_state;
			end if;
		end if;
	end process;
	
	process(state, gen_pdu, data_ack, buffer_addr, PDU_length_reg) begin
	
		buffer_we <= '0';
		buffer_out_ready <= '0';
		increment_addr <= '0';
		load_data_reg <= '0';
		buffer_wclk <= '0';
		load_pdu_length <= '0';
		rst_addr <= '0';
		case state is
			when st1_idle=>
				if gen_pdu = '1' then
					next_state <= st2_det_length;
				else
					next_state <= st1_idle;
				end if;
				
			when st2_det_length=>
				load_PDU_length <= '1';
				rst_addr <= '1';
				next_state <= st3_load;
			
			when st3_load=>
				buffer_we <= '1';
				load_data_reg <= '1';
				next_state <= stabilize;
			
			when stabilize=>
				buffer_we <= '1';
				next_state <= st4_write;
			
			when st4_write=>
				buffer_wclk <= '1';
				buffer_we <= '1';
				next_state <= st5_inc;
					
			when st5_inc=>
				increment_addr <= '1';
				buffer_we <= '1';
				if buffer_addr < PDU_length_reg - to_unsigned(1, 8) then
					next_state <= st3_load;
				else
					next_state <= st6_rst_addr;
				end if;
			
			when st6_rst_addr=>
				rst_addr <= '1';
				next_state <= st7_notify;
			
			when st7_notify=>
				buffer_out_ready <= '1';
				if data_ack = '0' then
					next_state <= st7_notify;
				else
					next_state <= st8_inc;
				end if;
				
			when st8_inc=>
				increment_addr <= '1';
				next_state <= st9_check_done;
			
			when st9_check_done=>
				if buffer_addr < PDU_length_reg then
					next_state <= st7_notify;
				else
					next_state <= st1_idle;
				end if;
			end case;
	end process;


	-- Outputs generated from internal signals
	process (PDU_length_reg, buffer_data_out, buffer_out_ready)
	begin
		PDU_length <= std_logic_vector(PDU_length_reg);
		data_out <= buffer_data_out;
		data_ready <= buffer_out_ready;
	end process;

end Behavioral;
