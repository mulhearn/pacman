library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;

--  Defines a testbench (without any ports)
entity rising_edge_sync_tb is
end rising_edge_sync_tb;

architecture behaviour of rising_edge_sync_tb is

  component rising_edge_sync is
    generic ( DEBOUNCE_CYCLES : integer);

    port (
      CLK_I  : in  std_logic;
      RST_I  : in  std_logic;

      ASYNC_SIGNAL_I : in std_logic;
      POLARITY_I     : in std_logic;
      UPDATE_O       : out std_logic
      );
  end component;


  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal uclk     : std_logic;

  signal asig     : std_logic := '0';
  signal update   : std_logic := '0';


  signal show_output : std_logic := '0';


begin

  dut0: rising_edge_sync
    generic map(
      DEBOUNCE_CYCLES => 4
    )
    port map (
      CLK_I  => uclk,
      RST_I  => rst,
      ASYNC_SIGNAL_I => asig,
      POLARITY_I => '0',
      UPDATE_O => update
    );

  signal_process : process
  begin
    asig <= '0';
    wait for 160 ns;
    asig <= '1';
    wait for 100 ns;
    asig <= '0';
    wait for 100 ns;
    asig <= '1';
    wait for 200 ns;
    asig <= '0';
    wait for 100 ns;
    asig <= '1';
    wait for 200 ns;
    asig <= '0';
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
    wait until (count=120);
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
      write (l, String'(" asig: "));
      write (l, asig);
      write (l, String'(" update: "));
      write (l, update);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
