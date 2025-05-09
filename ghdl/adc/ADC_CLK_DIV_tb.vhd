library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity ADC_CLK_DIV_tb is
end ADC_CLK_DIV_tb;

architecture behaviour of ADC_CLK_DIV_tb is
  component ADC_CLK_DIV is
    port (
      ACLK    : in std_logic;
      CLK_DIV : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ARESETN : in std_logic;

      ADC_CLK : out std_logic
    );
  end component;
  signal count   : integer := 0;
  signal aclk    : std_logic;
  signal aresetn : std_logic;
  signal adc_clk : std_logic;
  signal clk_div : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

begin
  uut: ADC_CLK_DIV port map (
    ACLK    => aclk,
    ARESETN => aresetn,
    ADC_CLK => adc_clk,
    CLK_DIV => clk_div
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

  clk_div_process : process
  begin
    clk_div <= x"00000000";
    wait for 52 ns;
    clk_div <= x"00000004";
    wait for 100 ns;
    clk_div <= x"00000010";
    wait for 1000 ns;
    clk_div <= x"00000001";
  end process;
end behaviour;
