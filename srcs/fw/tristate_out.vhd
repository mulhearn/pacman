----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/10/2022 10:43:26 AM
-- Design Name: 
-- Module Name: tristate_out - Behavioral
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

entity tristate_out is
    Port ( d_in : in STD_LOGIC_VECTOR (31 downto 0);
           t_out : inout STD_LOGIC_VECTOR (5 downto 0));
end tristate_out;

architecture arch_imp of tristate_out is
 component IOBUF is
    port (
      O : out std_logic;
      I : in std_logic;
      T : in std_logic;
      IO : inout std_logic
      );
  end component;

 
begin
  iobuf_1 : IOBUF port map (
    O => open,
    I => d_in(16),
    T => d_in(8),
    IO => t_out(0)
    );
  iobuf_2 : IOBUF port map (
    O => open,
    I => d_in(17),
    T => d_in(9),
    IO => t_out(1)
    );
  iobuf_3 : IOBUF port map (
    O => open,
    I => d_in(18),
    T => d_in(10),
    IO => t_out(2)
    );
  iobuf_4 : IOBUF port map (
    O => open,
    I => d_in(19),
    T => d_in(11),
    IO => t_out(3)
    );
  iobuf_5 : IOBUF port map (
    O => open,
    I => d_in(20),
    T => d_in(12),
    IO => t_out(4)
    );
  iobuf_6 : IOBUF port map (
    O => open,
    I => d_in(21),
    T => d_in(13),
    IO => t_out(5)
    );

end arch_imp;
