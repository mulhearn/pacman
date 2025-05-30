library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity adc_clk_div_tb is
end adc_clk_div_tb;
     
architecture behaviour of adc_clk_div_tb is
  component adc_clk_div is
    port (
      ACLK	   : in  std_logic;
      ARESETN	   : in  std_logic;
      CLKPAR_I     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      ADC_CLK_O    : out std_logic
      );
  end component;
  signal count     : integer := 0;
  signal aclk      : std_logic;
  signal aresetn   : std_logic;
  signal clkpar    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal clk_o     : std_logic;
  
begin
  uut: adc_clk_div port map (
      ACLK         => aclk,
      ARESETN      => aresetn,
      CLKPAR_I     => clkpar,
      ADC_CLK_O    => clk_o
      );
  
  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 12 ns;
    aresetn <= '1';    
    wait;
  end process;
  
  aclk_process : process
  begin
    count <= count + 1;    
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  write_clk_par : process
  begin
    clkpar <= x"00000000";
    wait for 22 ns;
    clkpar <= x"00000001";
    wait for 50 ns;
    clkpar <= x"00000002";
    wait for 100 ns;
    clkpar <= x"00000004";
    wait for 100 ns;
    clkpar <= x"00000000";
    wait;
  end process;
  
end behaviour;
