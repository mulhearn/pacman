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
      ACLK	          : in std_logic;
      ARESETN	          : in std_logic;

      LED_CONFIG_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      GLOBAL_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      LED_O               : out std_logic_vector(C_NUM_LED-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;

  signal config   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '1');
  signal status   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal leds     : std_logic_vector(C_NUM_LED-1 downto 0) := (others => '0');

  signal show_output : std_logic := '0';
begin
  uut0: global_status port map (
    ACLK             => aclk,
    ARESETN          => aresetn,
    LED_CONFIG_I     => config,
    GLOBAL_STATUS_O  => status,
    LED_O            => leds
    );

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 20 ns;
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
      --write (l, String'("aclk: "));
      --write (l, aclk);
      write (l, String'(" config: 0x"));
      hwrite (l, config);
      write (l, String'(" status: 0x"));
      hwrite (l, status);
      write (l, String'(" leds: "));
      write (l, leds(0));
      write (l, leds(1));
      if (aresetn = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
