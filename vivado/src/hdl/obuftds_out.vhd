library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity obuftds_out is
port
 (
   i  : in    std_logic;
   en  : in    std_logic;
   o_p : out  std_logic;
   o_n : out  std_logic
);
end obuftds_out;

architecture arch_imp of obuftds_out is
  component OBUFTDS is
    port (
      O : out std_logic;
      OB : out std_logic;
      I : in std_logic;
      T : in std_logic
      );
  end component;

  signal t : std_logic;
  
begin
  t <= not en;
  
  obuftds_inst : OBUFTDS port map (
    O => o_p,
    OB => o_n,
    I => i,
    T => t
    );
end arch_imp;

