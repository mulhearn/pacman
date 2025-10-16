library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;

--  Defines a testbench (without any ports)
entity timestamp_tb is
end timestamp_tb;

architecture behaviour of timestamp_tb is

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal tzero    : std_logic;
  signal rst_or   : std_logic;
  signal uclk     : std_logic;

  -- dut output:
  signal ts_fast  : std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
  signal ts_slow  : std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
  signal toggle   : std_logic;
  signal tsync    : std_logic;

  signal show_output : std_logic := '0';

  component timestamp_simple is
    port (
      CLK_I	        : in  std_logic;
      RST_I	        : in  std_logic;
      TIMESTAMP_O         : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      TOGGLE_O            : out std_logic;
      TSYNC_O             : out std_logic
    );
  end component;

  component timestamp_sync is
    port (
      CLK_I	        : in  std_logic;
      RST_I	        : in  std_logic;
      TIMESTAMP_O         : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      TOGGLE_A            : in std_logic;
      TSYNC_A             : in std_logic
      );
  end component;

begin
  dut0: timestamp_simple port map (
    CLK_I              => uclk,
    RST_I              => rst_or,
    TIMESTAMP_O        => ts_slow,
    TOGGLE_O           => toggle,
    TSYNC_O            => tsync
  );

  dut2: timestamp_sync port map (
    CLK_I              => clk,
    RST_I              => rst,
    TIMESTAMP_O        => ts_fast,
    TOGGLE_A           => toggle,
    TSYNC_A            => tsync
  );

  rst_or <= rst or tzero;

  rst_process : process
  begin
    rst   <= '1';
    tzero <= '0';
    wait for 20 ns;
    rst <= '0';
    wait until count=30;
    tzero <= '1';
    wait for 20 ns;
    tzero <= '0';
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
      --write (l, String'("clk: "));
      --write (l, clk);
      write (l, String'(" "));
      write (l, uclk);
      write (l, String'(" slow: 0x"));
      hwrite (l, ts_slow);
      write (l, String'(" fast: 0x"));
      hwrite (l, ts_fast);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
