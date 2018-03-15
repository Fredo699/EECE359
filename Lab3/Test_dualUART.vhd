--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:50:58 02/01/2018
-- Design Name:   
-- Module Name:   /home/fred/git/EECE359/Lab2/Test_dualUART.vhd
-- Project Name:  Lab2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: dualUART
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
--USE ieee.numeric_std.ALL;
 
ENTITY Test_dualUART IS
END Test_dualUART;
 
ARCHITECTURE behavior OF Test_dualUART IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT dualUART
	 Generic (debounceDELAY : integer := 640000); -- debounceDELAY = 20 mS / clk_period);
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         RXD_A : IN  std_logic;
         RXD_B : IN  std_logic;
         XMT_A : IN  std_logic;
         SWITCH : IN  std_logic_vector(7 downto 0);
         TXD_A : OUT  std_logic;
         TXD_B : OUT  std_logic;
         LED : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RST : std_logic := '0';
   signal RXD_A : std_logic := '0';
   signal RXD_B : std_logic := '0';
   signal XMT_A : std_logic := '0';
   signal SWITCH : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal TXD_A : std_logic;
   signal TXD_B : std_logic;
   signal LED : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 31.25 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: dualUART 
	Generic MAP (debounceDELAY => 3)
	PORT MAP (
          CLK => CLK,
          RST => RST,
          RXD_A => RXD_A,
          RXD_B => RXD_B,
          XMT_A => XMT_A,
          SWITCH => SWITCH,
          TXD_A => TXD_A,
          TXD_B => TXD_B,
          LED => LED
        );
		  
	-- connect the UARTs
	RXD_B <= TXD_A;
	RXD_A <= TXD_B;

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_period*10;
		
		SWITCH <= "01010110";
		
		RST <= '1';
		wait for 20 us;
		RST <= '0';
		wait for 20 us;
		
		XMT_A <= '1';
		wait for 20 us;
		XMT_A <= '0';
		wait for 20 us;

      wait;
   end process;

END;
