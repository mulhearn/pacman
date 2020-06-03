library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_out is
port
 (
  i  : in    std_logic;  
  o_p : out  std_logic;
  o_n : out  std_logic
);
end clk_out;

architecture arch_imp of clk_out is
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

  component OBUFDS is
    port (
      O : out std_logic;
      OB : out std_logic;
      I : in std_logic
      );
  end component;

  signal o : std_logic;
  
begin

  oddr_inst : ODDR generic map (
      DDR_CLK_EDGE   => "SAME_EDGE", --"SAME_EDGE", --OPPOSITE_EDGE", -- "SAME_EDGE"
      INIT           => '0',
      SRTYPE         => "ASYNC")
    port map (
      D1             => '1',
      D2             => '0',
      C              => i,
      CE             => '1',
      Q              => o,
      R              => '0',
      S              => '0'
      );

  obufds_inst : OBUFDS port map (
    O => o_p,
    OB => o_n,
    I => o
    );
  
end arch_imp;

