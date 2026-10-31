library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_ddr_en is
port
 (
   i    : in  std_logic;
   hi    : in  std_logic;
   lo    : in  std_logic;
   local_clk : out std_logic;
   o    : out std_logic
);
end clk_ddr_en;

architecture arch_imp of clk_ddr_en is
  component ODDR is
    generic (
      DDR_CLK_EDGE : string;
      INIT : std_logic;
      SRTYPE : string
      );
    port (
      D1 : in std_logic;
      D2 : in std_logic;
      C : in std_logic;
      CE : in std_logic;
      Q : out std_logic;
      R : in std_logic;
      S : in std_logic
      );
  end component;

begin
    local_clk <= i AND (hi XOR lo);
  oddr_inst : ODDR generic map (
      DDR_CLK_EDGE   => "SAME_EDGE", --"SAME_EDGE", --OPPOSITE_EDGE", -- "SAME_EDGE"
      INIT           => '0',
      SRTYPE         => "ASYNC")
    port map (
      D1             => hi,
      D2             => lo,
      C              => i,
      CE             => '1',
      Q              => o,
      R              => '0',
      S              => '0'
      );
end arch_imp;

