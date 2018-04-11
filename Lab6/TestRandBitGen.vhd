--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:15:34 03/22/2018
-- Design Name:   
-- Module Name:   /home/fred/git/EECE359/Lab5/TestRandBitGen.vhd
-- Project Name:  Lab5
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: RandBitGen
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY TestRandBitGen IS
END TestRandBitGen;
 
ARCHITECTURE behavior OF TestRandBitGen IS 
 
	constant TEST_NUMBER : integer := 3;
	constant LARGEST_SIZE : integer := 8;
	
	type param_set is record
		RBGsize : integer;
		RBG_P : std_logic_vector(LARGEST_SIZE downto 1);
		RBGseed : std_logic_vector(LARGEST_SIZE downto 1);
		FRAME_LENGTH : integer;
		NUM_FRAMES : integer;
	end record;
 
	type param_array_type is array (positive range <>) of param_set;
	constant PARAM_ARRAY: param_array_type :=
		(
			(4, "00001100", "00001001", 15, 2),
			(5, "00010100", "00010001", 31, 2),
			(8, "10111000", "10000001", 8, 6)
		); 
		
    -- uut component declaration
    COMPONENT RandBitGen
	 Generic (size : integer := 4);
    PORT(
         P : IN  std_logic_vector(size downto 1);
         seed : IN  std_logic_vector(size downto 1);
         frame_in : IN  std_logic;
         dclk_in : IN  std_logic;
         data_out : OUT  std_logic;
         dclk_out : OUT  std_logic;
         frame_out : OUT  std_logic;
         clk : IN  std_logic;
         rst : IN  std_logic
        );
    END COMPONENT;
    
	 
	signal size : integer := PARAM_ARRAY(TEST_NUMBER).RBGsize;
   --Inputs
   signal P : std_logic_vector(size downto 1) := (others=>'0');
   signal seed : std_logic_vector(size downto 1) := (others=>'0');
   signal frame_in : std_logic := '0';
   signal dclk_in : std_logic := '0';
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';

 	--Outputs
   signal data_out : std_logic;
   signal dclk_out : std_logic;
   signal frame_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 31.25 ns;
   constant dclk_period : time := 32*clk_period;
	
	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: RandBitGen 
	Generic Map (size=>PARAM_ARRAY(TEST_NUMBER).RBGsize)
	PORT MAP (
          P => P,
          seed => seed,
          frame_in => frame_in,
          dclk_in => dclk_in,
          data_out => data_out,
          dclk_out => dclk_out,
          frame_out => frame_out,
          clk => clk,
          rst => rst
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
	
	dclk_process :process
	begin
		dclk_in <= '0';
		wait for dclk_period/2;
		dclk_in <= '1';
		wait for dclk_period/2;
	end process;
 

   -- Stimulus process
   stim_proc: process
   begin	
		P <= std_logic_vector(resize(unsigned(PARAM_ARRAY(TEST_NUMBER).RBG_P),PARAM_ARRAY(TEST_NUMBER).RBGsize));
		seed <= std_logic_vector(resize(unsigned(PARAM_ARRAY(TEST_NUMBER).RBGseed),PARAM_ARRAY(TEST_NUMBER).RBGsize));
      -- hold reset state for 100 ns.
		rst <= '1';
      wait for 50 ns;	
		rst <= '0';
		
      wait for clk_period*5;
		
		for I in PARAM_ARRAY(TEST_NUMBER).NUM_FRAMES downto 1 loop
			frame_in <= '1';
			wait for dclk_period * PARAM_ARRAY(TEST_NUMBER).FRAME_LENGTH;
			frame_in <= '0';
			wait for dclk_period * 5;
		end loop;
		
		
      wait;
   end process;

END;
