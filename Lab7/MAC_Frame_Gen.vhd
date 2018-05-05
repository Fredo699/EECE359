----------------------------------------------------------------------------------
-- Company: 		 Binghamton University
-- Engineer:	    
-- 
-- Create Date:    20:40:33 04/18/2011 
-- Design Name:    Ethernet MAC Frame Generator
-- Module Name:    MAC_Frame_Gen - Behavioral 
-- Project Name:   Lab7
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Revision 1.00 - April 17, 2014
--                 Corrected ordering of transmitted bits to begin with bit 0
--                 for all fields except preamble and SFD
--                 Defined "reverse" function to reverse ordering of bits when
--						 loaded into shift register
-- Revision 1.01 - April 13, 2016
--						 Added option to generate load_packet_sr signal in the FSM
--						 instead of a separate process.
-- Revision 1.02 - April 18, 2016
--						 Corrected Mealy output load_packet_sr to be always generated
--						 by dclk_rise and not dclk_fall.
--						 Declared a new signal for the FSM output called 
--						 load_packet_sr_FSM.
--						 Declared a constant, SEL_load_packet_sr, to select which
--						 method to use to generate the load_packet_sr signal.
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.Local_Functions.ALL;

entity MAC_Frame_Gen is
    Port ( rst : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           data_in : in  STD_LOGIC_VECTOR (7 downto 0);
           data_ready : in  STD_LOGIC;
           data_ack : out  STD_LOGIC := '0';
           PDU_length : in  STD_LOGIC_VECTOR (7 downto 0);
           source_addr : in  STD_LOGIC_VECTOR (7 downto 0);
           dest_addr : in  STD_LOGIC_VECTOR (7 downto 0);
           dclk_out : out  STD_LOGIC := '0';
           data_out : out  STD_LOGIC := '0';
           frame_out : out  STD_LOGIC := '0');
end MAC_Frame_Gen;

architecture Behavioral of MAC_Frame_Gen is

	component CRC 
		 generic ( fcs_length : integer ); 
		 port ( P : std_logic_vector (fcs_length downto 0);
				  data_in : in  STD_LOGIC;
				  dclk_in : in  STD_LOGIC;
				  frame_in : in  STD_LOGIC;
				  data_out : out  STD_LOGIC;
				  dclk_out : out  STD_LOGIC;
				  frame_out : out  STD_LOGIC;
				  error_out : out  STD_LOGIC;
				  mode : in  STD_LOGIC;
				  clk : in  STD_LOGIC;
				  rst : in  STD_LOGIC);
	end component;

	constant preamble : std_logic_vector (7 downto 0) := "10101010";
	constant SFD : std_logic_vector (7 downto 0) := "10101011";
	-- define length of frame check sequence 
	--		to be added to end of data being transmitted
	constant fcs_length : integer := 8;
	-- define the predetermined divisor for the CRC 
	constant P : std_logic_vector (fcs_length downto 0) := "100011101";

	signal clkdiv : unsigned (4 downto 0) := "00000";
	signal clkdiv4_d1 : std_logic; -- clkdiv bit 4 delayed one system clock cycle
	signal clkdiv4_d2 : std_logic; -- clkdiv bit 4 delayed two system clock cycles
	signal clkdiv4_d3 : std_logic; -- clkdiv bit 4 delayed three system clock cycles
	signal dclk_rise : std_logic; -- rising edge of the data clock
	signal dclk_fall : std_logic; -- rising edge of the data clock
	signal dclk_rise_d1 : std_logic; -- dclk_rise delayed one system clock cycle
	signal dclk_rise_d2 : std_logic; -- dclk_rise delayed two system clock cycle
	signal MAC_packet_sr : std_logic_vector(7 downto 0) := (others => '0'); 
											-- MAC packet shift register
	signal packet_sr_data : std_logic_vector(7 downto 0); 
													-- MAC packet shift register input data
	signal shift_count : unsigned(2 downto 0) := (others => '0'); 
													-- shift counter for MAC packet shift register
	signal byte_count : unsigned(5 downto 0) := (others => '0'); 
													-- byte counter for oounting multi-byte fields
	signal data_ack_i : std_logic; -- internal data acknowledge
	signal load_packet_sr : std_logic; -- load data into the MAC packet shift register
	signal CRC_data_in : std_logic;    -- CRC input data
	signal CRC_data_in_d1 : std_logic; -- CRC_data_in delayed one system clock cycle
	signal CRC_data_in_d2 : std_logic; -- CRC_data_in delayed two system clock cycles
	signal CRC_frame_in : std_logic; -- frame for CRC excludes preamble and SFD
	signal CRC_data_out : std_logic; 
	signal CRC_dclk_out : std_logic; 
	signal CRC_dclk_in : std_logic; 
	signal CRC_frame_out : std_logic; 
	signal frame_out_i_d1 : std_logic; -- frame_out_i delayed 1 system clock cycle
	signal frame_out_i_d2 : std_logic; -- frame_out_i delayed 2 system clock cycles
	signal frame_out_i_d3 : std_logic; -- frame_out_i delayed 3 system clock cycles

	-- Declare signals for state machine
	type state_type is (st1_idle, st2_send_preamble, st3_send_SFD, 
								st4_send_dest_addr, st5_send_source_addr, st6_send_length, 
								st7_send_PDU_data, st8_send_FCS); 
	signal state, next_state : state_type := st1_idle; 
	-- Declare state machine output signals
	signal en_shift_ctr : std_logic := '0'; -- enable shift register shift counter
	signal en_byte_ctr : std_logic := '0'; -- enable byte counter
	signal frame_out_i : std_logic; -- frame output internal signal
	signal sel_preamble : std_logic;  -- select preamble
	signal sel_SFD : std_logic;  -- select SFD
	signal sel_dest_addr : std_logic;  -- select destination address
	signal sel_source_addr : std_logic;  -- select source address
	signal sel_length : std_logic;  -- select length
	signal sel_PDU_data : std_logic;  -- select PDU data
	signal enable_CRC : std_logic := '0'; -- frame for CRC excludes preamble and SFD

begin

	-- Instantiated CRC module used to generate the FCS for the generated frame
	FCS_Gen : CRC 
		 Generic map ( fcs_length )
		 Port map ( 
				  P => P,	
				  data_in => CRC_data_in,
				  dclk_in => CRC_dclk_in,
				  frame_in => CRC_frame_in,
				  data_out => CRC_data_out,
				  dclk_out => CRC_dclk_out,
				  frame_out => CRC_frame_out,
				  error_out => open, 
				  mode => '1',
				  clk => clk,
				  rst => rst);
	
	-- (clkdiv)
	-- Clock divider counter used to set the MAC packet data rate
	-- the rate of dclk will be that of bit four of clkdiv
	process (clk)
	begin
		if rising_edge(clk) then
			clkdiv <= clkdiv + 1;
		end if;
	end process;

	-- generate clkdiv4_d1, clkdiv4_d2, clkdiv4_d3, dclk_rise, 
	-- 	dclk_rise_d1, and dclk_fall
	process (clk)
	begin
		if rising_edge(clk) then
			clkdiv4_d1 <= clkdiv(4);
			clkdiv4_d2 <= clkdiv4_d1;
			clkdiv4_d3 <= clkdiv4_d2;
			dclk_rise <= clkdiv(4) and (not clkdiv4_d1);
			dclk_rise_d1 <= dclk_rise;
			dclk_fall <= (not clkdiv(4)) and clkdiv4_d1;
		end if;
	end process;
	
	-- (packet_sr_data)
	-- MUX that selects parallel input data for MAC packet shift register
	-- the "reverse" function can be used to reverse the order of the
	--		bits in a byte of data when needed to put the data in the
	--		correct order (see provided "Bit Reversal in VHDL")

	with state select
		packet_sr_data <= (sfd) when st3_send_SFD,
								reverse(dest_addr) when st4_send_dest_addr,
								reverse(source_addr) when st5_send_source_addr,
								reverse(PDU_length) when st6_send_length,
								reverse(data_in) when st7_send_PDU_data,
								(preamble) when others;
	

	-- (load_packet_sr)
	-- process to generate the load signal for packet shift register
	-- this signal loads the MAC_packet_sr shift register
	--		with each byte of data (selected by the above MUX) before it is 
	--		shifted out at the rate set by dclk
	-- ALTERNATIVELY, this signal can be generated in the FSM
	-- 	as a Mealy output

	process(clk) begin
		if rising_edge(clk) then
			if shift_count = to_unsigned(0, 3) then
				load_packet_sr <= dclk_rise;
			else
				load_packet_sr <= '0';
			end if;
		end if;
	end process;

	
	-- (MAC_packet_sr)
	-- MAC packet shift register
	-- byte of data is parallel loaded into the register
	-- then the data is shifted out on the rise of dclk 
	--		(dclk rise delayed 1 clock cycle)

	process(clk) begin
		if rising_edge(clk) then
			if load_packet_sr = '1' then
				MAC_packet_sr <= packet_sr_data;
			elsif dclk_rise_d1 = '1' then
				if frame_out_i = '1' then
					for i in MAC_packet_sr'length-1 downto 1 loop
						MAC_packet_sr(i) <= MAC_packet_sr(i - 1);
					end loop;
					MAC_packet_sr(0) <= '0';
				end if;
			end if;
		end if;
	end process;

	
	-- (CRC_data_in)
	-- CRC data input is connected to the output of the MAC_packet_sr

	CRC_data_in <= MAC_packet_sr(MAC_packet_sr'length-1);


	-- (shift_count)
	-- shift counter for MAC packet shift register 
	-- resets to zero when not enabled
	-- increments on the rise of dclk

	process(clk) begin
		if rising_edge(clk) then
			if en_shift_ctr = '0' then
				shift_count <= to_unsigned(0, shift_count'length);
			elsif dclk_rise_d1 = '1' then
				shift_count <= shift_count + to_unsigned(1, shift_count'length);
			end if;
		end if;
	end process;


	-- (byte_count)
	-- byte counter for counting multi-byte fields
	-- resets to zero when not enabled
	-- incremented when byte of data is finished shifting 
	--		out of the MAC_packet_sr

	process(clk) begin
		if rising_edge(clk) then
			if en_byte_ctr = '0' then
				byte_count <= to_unsigned(0, byte_count'length);
			elsif shift_count = to_unsigned(0, 3) and dclk_rise_d1 = '1' then	
				byte_count <= byte_count + to_unsigned(1, byte_count'length);
			end if;
		end if;
	end process;


	-- (data_ack_i)
	-- PDU data handshake logic
	-- when data_ready is high and the MAC_packet_sr is loaded with
	--		a byte for the data field of the MAC frame, the data_ack_i is
	--		activated and held high until the data_ready goes low.
		
	process(clk) begin
		if rising_edge(clk) then
			if data_ready = '1' and load_packet_sr = '1' and (state=st6_send_length or state=st7_send_PDU_data) then
				data_ack_i <= '1';
			else
				data_ack_i <= '0';
			end if;
		end if;
	end process;
	


	-- (CRC_frame_in)
	-- create CRC_frame_in by syncing enable_CRC with dclk_rise_d1
	-- the signal becomes active when enable_CRC is active and 
	--    dclk_rise_d1 is active and goes inactive when enable_CRC
	--    is inactive and dclk_rise_d1 is active

	process(clk) begin
		if rising_edge(clk) then
			if dclk_rise_d1 = '1' then
				CRC_frame_in <= enable_CRC;
			end if;
		end if;
	end process;

	
	-- create delayed frame_out_i and CRC_data_in signals
	process (clk)
	begin
	if rising_edge(clk) then
		frame_out_i_d1 <= frame_out_i;
		frame_out_i_d2 <= frame_out_i_d1;
		frame_out_i_d3 <= frame_out_i_d2;
		CRC_data_in_d1 <= CRC_data_in;
		CRC_data_in_d2 <= CRC_data_in_d1;
	end if;
	end process;
	
	-- (data_out)
	-- output the complete MAC frame serial data
	-- sync it to clk (use register)
	-- consider the sources of all the parts of the frame
	--    and use register delays to line up the timing
	process (clk)
	begin
		if rising_edge(clk) then
			data_out <= (CRC_frame_out and CRC_data_out) or 
								(CRC_data_in_d2 and (not CRC_frame_out) 
									and frame_out_i_d3);
		end if;
	end process;
	
	-- (dclk_out)
	-- output the MAC frame data clock 
	-- sync it to clk (use register)
	-- use delays to align its timing with data_out
	process (clk)
	begin
		if rising_edge(clk) then
			dclk_out <= (not CRC_dclk_out) and (CRC_frame_out or frame_out_i_d3);
		end if;
	end process;
	
	-- (frame_out)
	-- output the MAC frame signal
	-- sync it to clk (use register)
	-- combine frame signals using logic to frame the
	--   entire MAC frame, and use delays to align frame_out with
	--   data_out and dclk_out signals.
	process (clk)
	begin
		if rising_edge(clk) then
			frame_out <= CRC_frame_out or frame_out_i_d3;  
		end if;
	end process;
		
	-- generate input clock for CRC
	-- CRC_dclk_in is the clkdiv4_d3 signal inverted
	CRC_dclk_in <= not clkdiv4_d3;
	
	-- output data acknowledge
	data_ack <= data_ack_i;

   -- MAC Frame Generator Controller FSM

	process(clk) begin
		if rising_edge(clk) then
			if rst = '1' then
				state <= st1_idle;
			else
				state <= next_state;
			end if;
		end if;
	end process;
	
	process(state, dclk_rise, dclk_fall, data_ready, byte_count, shift_count, pdu_length) begin
		frame_out_i <= '1';
		enable_crc <= '0';
		en_shift_ctr <= '0';
		en_byte_ctr <= '0';
		case state is
			when st1_idle=>
				frame_out_i <= '0';
				if data_ready = '1' and dclk_rise = '1' then
					next_state <= st2_send_preamble;
				else
					next_state <= st1_idle;
				end if;
			
			when st2_send_preamble=>
				en_shift_ctr <= '1';
				en_byte_ctr <= '1';
				if byte_count = to_unsigned(7, byte_count'length) and dclk_fall = '1' then
					next_state <= st3_send_SFD;
				else
					next_state <= st2_send_preamble;
				end if;
				
			when st3_send_SFD=>
				en_shift_ctr <= '1';
				if shift_count = to_unsigned(0, 3) and dclk_fall = '1' then
					next_state <= st4_send_dest_addr;
				else
					next_state <= st3_send_SFD;
				end if;
			
			when st4_send_dest_addr=>
				en_shift_ctr <= '1';
				if shift_count = to_unsigned(0, 3) and dclk_fall = '1' then
					next_state <= st5_send_source_addr;
				else
					next_state <= st4_send_dest_addr;
				end if;
				
			when st5_send_source_addr=>
				en_shift_ctr <= '1';
				if shift_count = to_unsigned(0,3) and dclk_fall = '1' then
					next_state <= st6_send_length;
				else
					next_state <= st5_send_source_addr;
				end if;
				
			when st6_send_length=>
				en_shift_ctr <= '1';
				if shift_count = to_unsigned(0, 3) and dclk_fall = '1' then
					next_state <= st7_send_PDU_data;
				else
					next_state <= st6_send_length;
				end if;
			
			when st7_send_PDU_data=>
				en_shift_ctr <= '1';
				en_byte_ctr <= '1';
				enable_crc <= '1';
				if byte_count = unsigned(PDU_length) then
					next_state <= st8_send_FCS;
				else
					next_state <= st7_send_PDU_data;
				end if;
			
			when st8_send_FCS=>
				en_shift_ctr <= '1';
				en_byte_ctr <= '1';
				if shift_count = to_unsigned(0, 3) and dclk_fall = '1' then
					next_state <= st1_idle;
				else
					next_state <= st8_send_FCS;
				end if;
		end case;
	end process;


end Behavioral;