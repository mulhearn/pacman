library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hello_pin is
    Port ( one : out STD_LOGIC;
           zero : out STD_LOGIC);
end hello_pin;

architecture Behavioral of hello_pin is
begin
    one  <= '1';
    zero <= '0';
end Behavioral;
