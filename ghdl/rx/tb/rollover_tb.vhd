library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity rollover_tb is
end rollover_tb;

architecture behaviour of rollover_tb is
  component rollover is
    port (
      CLK_I         : in  std_logic;
      RST_I         : in  std_logic;
      EN_I          : in  std_logic;
      CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      TIMESTAMP_O   : out  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      VALID_O       : out std_logic;
      READY_I       : in  std_logic;
      TIMESTAMP_I   : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal count      : integer := 0;
  signal tstep_ns   : integer := 10;
  signal clk        : std_logic;
  signal rst        : std_logic;
  signal uclk       : std_logic;
  signal tstamp     : std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
  signal tstamp_in  : std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0) := (others => '0');
  signal valid     : std_logic;
  signal ready     : std_logic;

  signal show_output : std_logic := '0';

begin
  ts_process: process

  begin
    tstamp_in <= std_logic_vector(to_unsigned(count, tstamp_in'length))
                 and std_logic_vector(to_unsigned(16#F#, tstamp_in'length));
    wait for 10 ns;
  end process;


  uut: rollover port map (
    CLK_I       => clk,
    RST_I       => rst,
    EN_I        => '1',
    CONFIG_I    => x"00000003",
    TIMESTAMP_O => tstamp,
    VALID_O     => valid,
    READY_I     => ready,
    TIMESTAMP_I => tstamp_in
  );

  clk_process : process
  begin
    count <= count + 1;
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
  end process;

  rst_process : process
  begin
    rst <= '1';
    wait for 20 ns;
    rst <= '0';
    wait;
  end process;

  ready_process : process
  begin
    ready <= '0';
    wait until (count=15);
    wait for 1 ns;
    ready <='1';
    wait;
  end process;

  show_process : process
  begin
    show_output <= '1';
    wait until (count = 35);
    show_output <= '0';
    wait;
  end process;

  output_process : process
    variable l : line;
    variable start   : std_logic := '0';
    variable update  : std_logic := '0';
    variable lost    : std_logic := '0';
  begin
    wait for 10 ns;

    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 5);
      write (l, String'("ts: "));
      hwrite (l, tstamp_in);
      --write  (l, String'("clk: "));
      --write  (l, clk);
      write  (l, String'(" v: "));
      write (l, valid);
      write  (l, String'(" r: "));
      write (l, ready);
      write  (l, String'(" | ts: 0x"));
      hwrite (l, tstamp);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;





end behaviour;
