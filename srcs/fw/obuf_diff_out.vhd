library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity obuff_diff_out is
port
 (
  i  : in    std_logic;
  o_p : out  std_logic;
  o_n : out  std_logic
);
end obuff_diff_out;

architecture arch_imp of obuff_diff_out is
  component OBUFDS is
    port (
      O : out std_logic;
      OB : out std_logic;
      I : in std_logic
      );
  end component;
  
begin
  obufds_inst : OBUFDS port map (
    O => o_p,
    OB => o_n,
    I => i
    );
end arch_imp;

