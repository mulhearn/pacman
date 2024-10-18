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
      ACLK          : in  std_logic;
      ARESETN       : in  std_logic;
      EN_I          : in  std_logic;
      CYCLES_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DATA_O        : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);
      VALID_O       : out std_logic;
      READY_I       : in  std_logic;
      TIMESTAMP_I   : in  std_logic_vector(31 downto 0);
      DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal count      : integer := 0;
  signal tstep_ns   : integer := 10;
  signal aclk      : std_logic;
  signal aresetn   : std_logic;
  signal uclk      : std_logic;
  signal status    : std_logic_vector(31  downto 0);
  signal data      : std_logic_vector(127 DOWNTO 0);
  signal rx        : std_logic := '1';

  signal timestamp : std_logic_vector(31 downto 0) := (others => '0');
  signal valid     : std_logic;
  signal ready     : std_logic;

  signal show_output : std_logic := '0';

begin
  ts_process: process

  begin
    timestamp <= std_logic_vector(to_unsigned(count, timestamp'length))
                 and std_logic_vector(to_unsigned(16#F#, timestamp'length));
    wait for 10 ns;
  end process;


  uut: rollover port map (
    ACLK        => aclk,
    ARESETN     => aresetn,
    EN_I        => '1',
    CYCLES_I    => x"00000000",
    DATA_O      => data,
    VALID_O     => valid,
    READY_I     => ready,
    TIMESTAMP_I => timestamp
  );

  aclk_process : process
  begin
    count <= count + 1;
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 20 ns;
    aresetn <= '1';
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
      hwrite (l, timestamp);
      --write  (l, String'("aclk: "));
      --write  (l, aclk);
      write  (l, String'(" v: "));
      write (l, valid);
      write  (l, String'(" r: "));
      write (l, ready);
      write  (l, String'(" | d: 0x"));
      hwrite (l, data);
      if (aresetn = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;





end behaviour;
