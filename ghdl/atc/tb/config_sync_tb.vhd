library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;
use work.atc_pkg.all;

--  Defines a testbench (without any ports)
entity config_sync_tb is
end config_sync_tb;

architecture behaviour of config_sync_tb is
  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal uclk     : std_logic;

  signal update      : std_logic := '0';
  signal request     : std_logic;
  signal busy        : std_logic;
  signal reply       : std_logic;

  signal show_output : std_logic := '0';

  signal config      : atc_config_t;
  signal shadow      : atc_config_t;

  component update_request is
    port (
      CLK_I	 : in  std_logic;
      RST_I	 : in  std_logic;
      REQUEST_I  : in  std_logic;
      BUSY_O     : out std_logic;
      REQUEST_O  : out std_logic;
      REPLY_A    : in  std_logic
    );
  end component;

  component config_sync is
    port (
      CLK_I	 : in  std_logic;
      RST_I	 : in  std_logic;
      CONFIG_A   : in  atc_config_t;
      SHADOW_O   : out atc_config_t;
      REPLY_O    : out std_logic;
      REQUEST_A  : in  std_logic
    );
  end component;

begin
  dut0: update_request port map (
    CLK_I        => clk,
    RST_I        => rst,
    REQUEST_I    => update,
    BUSY_O       => busy,
    REQUEST_O    => request,
    REPLY_A      => reply
  );

  poke0: config_sync port map (
    CLK_I          => uclk,
    RST_I          => rst,
    CONFIG_A       => config,
    SHADOW_O       => shadow,
    REPLY_O        => reply,
    REQUEST_A      => request
  );

  update_process : process
  begin
    config.polarity <= x"CCCCDDDD";
    update <= '0';
    wait for 40 ns;
    update <= '1';
    wait for 10 ns;
    update <= '0';
    wait for 500 ns;
    config.polarity <= x"33334444";
    wait for 10 ns;
    update <= '1';
    wait for 10 ns;
    update <= '0';
    wait;
  end process;

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

  uclk_process : process
  begin
    uclk <= '1';
    wait for 50 ns;
    uclk <= '0';
    wait for 50 ns;
  end process;

  show_output_process : process
  begin
    show_output<='1';
    wait until (count=100);
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
      write (l, String'(" "));
      write (l, uclk);
      --write (l, String'("clk: "));
      --write (l, clk);
      write (l, String'(" fast: u: "));
      write (l, update);
      write (l, String'(" b: "));
      write (l, busy);
      write (l, String'(" pol: 0x"));
      hwrite (l, config.polarity);
      write (l, String'(" pol: 0x"));
      hwrite (l, shadow.polarity);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
