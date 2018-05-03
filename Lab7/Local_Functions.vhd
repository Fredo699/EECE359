--
--	Package: Local_Functions
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 		constants, and functions 
--
-- Created: 04/11/2015
--				Function:  reverse
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package Local_Functions is

	-- define function to reverse the ordering of bits of a std_logic_vector signal
	function reverse (x : in std_logic_vector) return std_logic_vector; 

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--

end Local_Functions;

package body Local_Functions is

	function reverse (x : in std_logic_vector) return std_logic_vector is
	variable y : std_logic_vector (x'range);
	begin
		  for i in x'range loop
				y(i) := x(x'left - (i - x'right));
		  end loop;

		  return y;
	end; 

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end Local_Functions;
