library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iobuf_out is
port
 (
   ii  : in  std_logic;
   tt  : in  std_logic;
   oo  : out std_logic;
   iioo : inout std_logic
);
end iobuf_out;

architecture arch_imp of iobuf_out is
  component IOBUF is
    port (
      O : out std_logic;
      I : in std_logic;
      T : in std_logic;
      IO : inout std_logic
      );
  end component;

begin
  iobuf_inst : IOBUF port map (
    O => oo,
    I => ii,
    T => tt,
    IO => iioo
    );
end arch_imp;

