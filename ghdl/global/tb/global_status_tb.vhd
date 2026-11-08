library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity global_status_tb is
end global_status_tb;

architecture behaviour of global_status_tb is
  component global_status is
    port (
      --clock and active-high reset
      CLK_I	          : in std_logic;
      RST_I	          : in std_logic;

      LED_CONFIG_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      GLOBAL_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      LED_O               : out std_logic_vector(C_NUM_LED-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal config   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '1');
  signal status   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal leds     : std_logic_vector(C_NUM_LED-1 downto 0) := (others => '0');

  signal show_output : std_logic := '0';
begin
  uut0: global_status port map (
    CLK_I            => clk,
    RST_I            => rst,
    LED_CONFIG_I     => config,
    GLOBAL_STATUS_O  => status,
    LED_O            => leds
    );

  rst_process : process
  begin
    rst <= '1';
    wait for 20 ns;
    rst <= '0';
    wait;
  end process;

  clk_process : process
  begin
    count <= count + 1;
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
  end process;

  config_process : process
  begin
    config<=(others => '0');
    wait until (count=5);
    config(0) <= '1';
    wait until (count=10);
    config(1) <= '1';
    wait;
  end process;

  show_output_process : process
  begin
    show_output<='1';
    wait until (count=15);
    wait for 10 ns;
    show_output<='0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    wait for 10 ns;
    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      --write (l, String'("clk: "));
      --write (l, clk);
      write (l, String'(" config: 0x"));
      hwrite (l, config);
      write (l, String'(" status: 0x"));
      hwrite (l, status);
      write (l, String'(" leds: "));
      write (l, leds(0));
      write (l, leds(1));
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;


  comment_process : process
    variable l : line;
  begin
    write(l, String'("INFO:   Resetting:"));
    writeline(output, l);
    wait until (count=3);
    write(l, String'("INFO:   Setting first LED on:"));
    writeline(output, l);
    wait until (count=10);
    write(l, String'("INFO:   Setting both LEDs on:"));
    writeline(output, l);
     wait;
  end process;

end behaviour;
