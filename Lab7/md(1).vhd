----------------------------------------------------------------------------------
-- Company: 		 Binghamton University
-- Engineer:		 
-- 
-- Create Date:    April 5, 2015 
-- Design Name: 	 Ethernet MAC Protocol
-- Module Name:    manchdecoder - Behavioral 
-- Project Name:   Lab7
-- Target Devices: 
-- Tool versions: 
-- Description: 	 Manchester Encoder
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity manchdecoder is
port (rst,clk,manin : in std_logic;
		dclk_out : out std_logic;
		frame_out : out std_logic;
		nrz_out : out std_logic );
end manchdecoder;

architecture behavioral of manchdecoder is

-- Manchester Clock:    1.5625 MHz  (640 ns clock period)
--          -----       -----       -----       -----       -----       -----
--         |     |     |     |     |     |     |     |     |     |     |     |
--  -------       -----       -----       -----       -----       -----       -----
-- Data:
--    |    1     |     0     |     1     |     0     |     1     |     1     |
-- Manchester Signal:
--          -----------             -----------             -----       ----- 
--         |           |           |           |           |     |     |     |
--  -------             -----------             -----------       -----       -----
-- Value of clkdiv 
--    	  0     16    32          0     16    32          0     16    32
-- 		              0     16    32          0     16    32          0     16
-- Re-Sync Window
--                  |-----|     |-----|     |-----|     |-----|     |-----|        
--                  24   40     24   40     24   40     24   40     24   40      
-- Value of clkdiv 
-- at sample points:
-- 1/4, 3/4 => 8    24    8     24    8     24    8     24    8     24    8 	
-- Decoded Data:
--             |     1      |      0      |      1      |      0      |      1      |
	
	constant CLKDIV_MAX : unsigned (5 downto 0) 	:= to_unsigned(48,6);
																	-- maximum count (48)
	constant CLKDIV_INIT : unsigned (5 downto 0) 	:= to_unsigned(0,6);
																	-- initial count (0)
	constant CLKDIV_SYNC : unsigned (5 downto 0) 	:= to_unsigned(0,6);
																	-- sync count (0)
	constant CLKDIV_14 : unsigned (5 downto 0) 	:= to_unsigned(24,6);
																	-- 1/4 data bit period (24)
	constant CLKDIV_34 : unsigned (5 downto 0)    := to_unsigned(8,6);
																	-- 3/4 data bit period (8)
	constant SYNC_WIN_MIN : unsigned (5 downto 0) := to_unsigned(24,6);
																	-- sync window min (24)
	constant SYNC_WIN_MAX : unsigned (5 downto 0) := to_unsigned(40,6);
																	-- sync window max (40)
	constant SYNC_LOST : unsigned (5 downto 0)    := to_unsigned(41,6);
																	-- sync lost (41)
	constant DECODE_DATA_BIT : unsigned (5 downto 0) := to_unsigned(16,6);
																	-- sample decoded data bit (16)
	constant GEN_DCLK_RISE : unsigned (5 downto 0)   := to_unsigned(0,6);
																	-- generate dclk rising edge (0)
	constant GEN_DCLK_FALL : unsigned (5 downto 0)   := to_unsigned(16,6);
																	-- generate dclk_falling edge (16)
	constant GEN_DCLK_RISE_LAST : unsigned (5 downto 0)  := to_unsigned(33,6);
																	-- generate last dclk_out (33)

	signal clkdiv : unsigned (5 downto 0) := "000000";
	signal manin_d1 : std_logic;
	signal manin_d2 : std_logic;
	signal manin_rise : std_logic;
	signal manin_fall : std_logic;
	signal manin_s14 : std_logic;  -- sample 1/4 data bit period into next data bit
	signal manin_s34 : std_logic;  -- sample 3/4 data bit period into next data bit
	signal sync_det : std_logic;   -- detect manchester data signal 
	signal nrz_out_reg : std_logic;
	signal frame_out_i : std_logic;

begin

	-- two registers (manin_d1, manin_d2)
	--	for detecting rising and falling edges of manchester data signal 
	process (clk)
	begin
		if rising_edge(clk) then 	
			manin_d1 <= manin;
			manin_d2 <= manin_d1;
		end if;
	end process;

	-- detect rising edge and falling edge of manchester data signal 
	-- from manin_d1 and manin_d2 (combinatorial logic)
	manin_rise <= manin_d1 AND NOT manin_d2;
	manin_fall <= (not manin_d1) and manin_d2;

	-- (clkdiv)  
	-- counter used to control timing of manchester decoding process
	-- continually increments on the rising edge of clk, except
	-- loads with CLKDIV_SYNC value when manchester clock is detected (manin_rise = '1') 
	--		and sync is not yet detected
	-- loads with CLKDIV_SYNC value if a rising or falling edge is detected on manin 
	--		within expected window (clkdiv between SYNC_WIN_MIN and SYNC_WIN_MAX)
	-- loads with CLKDIV_INIT value when "clkdiv" reaches CLKDIV_MAX if sync is lost

	--###########################################################--
	--#####             INSERT YOUR CODE HERE               #####--
	--###########################################################--


	-- (manin_s14)
	-- register that samples manchester input (manin) at 1/4 of the manchester bit period
	-- initalized to zero with reset
	-- use manin delayed two clock cycles to keep timing aligned properly 

	--###########################################################--
	--#####             INSERT YOUR CODE HERE               #####--
	--###########################################################--


	-- (manin_s34)
	-- register that samples manchester input (manin) at 3/4 of the manchester bit period
	-- initalized to zero with reset
	-- use manin delayed two clock cycles to keep timing aligned properly 

	--###########################################################--
	--#####             INSERT YOUR CODE HERE               #####--
	--###########################################################--


	-- (sync_det) 
	-- register that is '1' while manchester clock synchronism is maintained
	-- cleared with reset
	-- if inactive, goes active when manin_rise goes active
	-- and stays active if manin_rise or manin_fall occur before
	--    clkdiv reaches SYNC_LOST

	--###########################################################--
	--#####             INSERT YOUR CODE HERE               #####--
	--###########################################################--


	-- (nrz_out_reg) 
	-- register to hold decode of Manchester data bits and produce nrz data 
	--		using manin_s14 and manin_s34
	-- (nrz_out_reg = 0 if manin_s14 = 1 and manin_s34 = 0; 
	--		nrz_out_reg = 1 if manin_s14 = 0 and manin_s34 = 1)

	--###########################################################--
	--#####             INSERT YOUR CODE HERE               #####--
	--###########################################################--


	-- (frame_out_i)
	-- register for internal version of frame_out
	-- generate frame_out_i when first nrz data bit is decoded 
	--		(sync_det = '1' and clkdiv = DECODE_DATA_BIT)
	-- terminate frame_out_i when synchronization is lost 
	--		(sync_det = '0' and clkdiv = CLKDIV_MAX)
	--    note the last term is required to extend frame_out_i 
	--		to the end of the last bit period

	--###########################################################--
	--#####             INSERT YOUR CODE HERE               #####--
	--###########################################################--


	-- (dclk_out)
	-- generate dclk_out to be used to sample the nrz_out data signal
	-- set to '1' when clkdiv = GEN_DCLK_RISE or clkdiv = GEN_DCLK_RISE_LAST
	--    the last term is required to generate clock for last data bit in frame
	-- "stretch" the clock so it has a 50% duty cycle 
	--		(i.e. until clkdiv = GEN_DCLK_FALL)

	--###########################################################--
	--#####             INSERT YOUR CODE HERE               #####--
	--###########################################################--


	-- (nrz_out, frame_out)
	-- generate nrz_out and frame_out outputs
	-- use frame_out_i to keep nrz_out at '0' outside of the fame
	nrz_out <= nrz_out_reg and frame_out_i;
	frame_out <= frame_out_i;

end behavioral;