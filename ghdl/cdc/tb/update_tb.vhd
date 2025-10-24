library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;

entity update_tb is
end update_tb;

architecture behaviour of update_tb is

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal uclk     : std_logic;

  signal update_fast : std_logic := '0';
  signal update_slow : std_logic;
  signal update_comb : std_logic;
  signal request     : std_logic;
  signal busy        : std_logic;
  signal reply       : std_logic;
  signal done        : std_logic;

  signal show_output : std_logic := '0';

  component update_request is
    port (
      CLK_I	 : in  std_logic;
      RST_I	 : in  std_logic;
      REQUEST_I  : in std_logic;
      BUSY_O     : out std_logic;
      REQUEST_O  : out std_logic;
      REPLY_A    : in std_logic
      );
  end component;

  component update_reply is
    port (
      CLK_I	     : in  std_logic;
      RST_I	     : in  std_logic;
      UPDATE_O       : out std_logic;
      UPDATE_COMB_O  : out std_logic;
      DONE_I         : in  std_logic;
      REQUEST_A      : in  std_logic;
      REPLY_O        : out std_logic
    );
  end component;

begin
  dut0: update_request port map (
    CLK_I       => clk,
    RST_I       => rst,
    REQUEST_I   => update_fast,
    BUSY_O      => busy,
    REQUEST_O   => request,
    REPLY_A     => reply
    );

  dut2: update_reply port map (
    CLK_I           => uclk,
    RST_I           => rst,
    UPDATE_O        => update_slow,
    UPDATE_COMB_O   => update_comb,
    DONE_I          => done,
    REQUEST_A       => request,
    REPLY_O         => reply
  );

  update_process : process
  begin
    update_fast <= '0';
    wait for 70 ns;
    update_fast <= '1';
    wait for 10 ns;
    update_fast <= '0';
    wait;
  end process;

  done_process : process
  begin
    done <= '0';
    wait for 600 ns;
    done <= '1';
    wait for 100 ns;
    done <= '0';
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
      write (l, String'(" fast: update: "));
      write (l, update_fast);
      write (l, String'(" busy: "));
      write (l, busy);
      write (l, String'(" slow: u:"));
      write (l, update_slow);
      write (l, String'(" comb: "));
      write (l, update_comb);
      write (l, String'(" done: "));
      write (l, done);

      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
