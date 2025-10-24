library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;

--  Defines a testbench (without any ports)
entity toggle_only_sync_tb is
end toggle_only_sync_tb;

architecture behaviour of toggle_only_sync_tb is

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal uclk     : std_logic;

  signal toggle      : std_logic := '0';
  signal update      : std_logic;
  signal update_comb : std_logic;

  signal show_output : std_logic := '0';

  component toggle_only_sync is
    port (
      CLK_I	             : in  std_logic;
      RST_I	             : in  std_logic;
      UPDATE_O               : out std_logic;
      UPDATE_COMB_O          : out std_logic;
      ASYNC_TOGGLE_I         : in  std_logic
    );
  end component;

begin

  dut2: toggle_only_sync port map (
    --CLK_I             => clk,
    CLK_I             => uclk,
    RST_I             => rst,
    UPDATE_O          => update,
    UPDATE_COMB_O     => update_comb,
    ASYNC_TOGGLE_I    => toggle
  );

  toggle_process : process
  begin
    toggle <= '0';
    wait for 60 ns;
    toggle <= '1';
    wait for 220 ns;
    toggle <= '0';
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
    wait until (count=60);
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
      write (l, String'(" toggle: "));
      write (l, toggle);
      write (l, String'(" update:"));
      write (l, update);
      write (l, String'(" comb: "));
      write (l, update_comb);

      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
