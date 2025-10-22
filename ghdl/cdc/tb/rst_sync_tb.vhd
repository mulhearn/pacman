library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;

--  Defines a testbench (without any ports)
entity rst_sync_tb is
end rst_sync_tb;

architecture behaviour of rst_sync_tb is

  component rst_sync is
    port (
      CLK_I  : in   std_logic;
      RST_A  : in   std_logic;
      RST_O  : out  std_logic
    );
  end component;

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst_in   : std_logic;
  signal rst_out  : std_logic;

  signal show_output : std_logic := '0';

begin

  dut0: rst_sync
    port map (
      CLK_I  => clk,
      RST_A  => rst_in,
      RST_O  => rst_out
    );

  async_process : process
  begin
    rst_in <= '0';
    wait for 330 ns;
    rst_in <= '1';
    wait for 10 ns;
    rst_in <= '0';
    wait;
  end process;

  clk_process : process
  begin
    count <= count + 1;
    clk <= '1';
    wait for 50 ns;
    clk <= '0';
    wait for 50 ns;
  end process;

  show_output_process : process
  begin
    show_output<='1';
    wait until (count=6);
    wait for 90 ns;
    show_output<='0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    wait for 10 ns;
    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      write (l, String'(" "));
      write (l, clk);
      write (l, String'(" rst_in: "));
      write (l, rst_in);
      write (l, String'(" rst_out: "));
      write (l, rst_out);
      writeline(output, l);
    end if;
  end process;

end behaviour;
