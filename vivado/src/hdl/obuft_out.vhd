library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity obuft_out is
port
 (
   i  : in    std_logic;
   en  : in    std_logic;
   o : out  std_logic
);
end obuft_out;

architecture arch_imp of obuft_out is
  component OBUFT is
    port (
      O : out std_logic;
      I : in std_logic;
      T : in std_logic
      );
  end component;

  signal t : std_logic;
  
begin
  t <= not en;
  
  obuft_inst : OBUFT port map (
    O => o,
    I => i,
    T => t
    );
end arch_imp;

