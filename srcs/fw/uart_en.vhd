----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Armin Karcher
-- 
-- Create Date: 06/23/2022 11:19:02 AM
-- Design Name: 
-- Module Name: uart_en - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_en is
    Port ( rx_en : in STD_LOGIC_VECTOR (31 downto 0);
           miso_in : in STD_LOGIC_VECTOR (31 downto 0);
           miso_out : out STD_LOGIC_VECTOR (31 downto 0));
end uart_en;

architecture arch_imp of uart_en is

begin
miso_out <= (rx_en AND miso_in );

end arch_imp;
