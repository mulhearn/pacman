library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity tx_chan_tb is
end tx_chan_tb;

architecture behaviour of tx_chan_tb is
  component tx_chan is
    port (
      CLK_I         : in  std_logic;
      RST_I         : in  std_logic;
      UCLK_I        : in  std_logic;
      CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DATA_I        : in  std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
      VALID_I       : in  std_logic;
      READY_O       : out std_logic;
      TX_O          : out std_logic;
      DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  signal count     : integer := 0;
  signal clk       : std_logic;
  signal uclk      : std_logic;
  signal rst       : std_logic;
  signal config    : std_logic_vector(31  downto 0);
  signal status    : std_logic_vector(31  downto 0);
  signal valid     : std_logic := '0';
  signal ready     : std_logic;
  signal tx        : std_logic;

  signal data      : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
begin
  uut: tx_chan port map (
      CLK_I    => clk,
      RST_I    => rst,
      UCLK_I   => uclk,
      CONFIG_I => config,
      DEBUG_O  => status,  -- DEBUG_O is non-delayed status.
      DATA_I   => data,
      VALID_I  => valid,
      READY_O  => ready,
      TX_O     => tx
  );

  rst_process : process
  begin
    rst <= '1';
    wait for 10 ns;
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

  config_process : process
  begin
    config <= x"00001601";
    --config <= x"000A1601";
    wait;
  end process;

  tx_process : process
    variable l : line;
  begin
    data  <= (others => '0');
    valid <= '0';
    wait for 1 ns;
    wait for 20 ns;
    data  <= x"00FF00FF00FF00FF";
    valid <= '1';
    wait until ((rising_edge(clk)) and (ready='1'));
    wait for 1 ns;
    data  <= (others => '0');
    valid <= '0';
    wait for 40 ns;
    valid <= '1';
    data  <= x"AAAAAAAAAAAAAAAA";
    wait until ((rising_edge(clk)) and (ready='1'));
    wait for 1 ns;
    data  <= (others => '0');
    valid <= '0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;

    if (count < 30) then
      wait for 10 ns;
    elsif (count < 680) then
      wait for 100 ns;
    elsif (count < 1500) then
      wait for 100 ns;
    else
      wait;
    end if;

    write (l, String'("c: "));
    write (l, count, left, 4);
    write  (l, String'(" uclk: "));
    write  (l, uclk);
    write  (l, String'("| valid: "));
    write  (l, valid);
    write  (l, String'(" ready: "));
    write  (l, ready);
    write  (l, String'(" busy: "));
    write  (l, status(0));
    write  (l, String'(" start: "));
    write  (l, status(3));
    write  (l, String'(" rested: "));
    write  (l, status(9));
    write  (l, String'(" | tx: "));
    write  (l, tx);

    if (status(3) = '1') then
      write (l, String'(" (START) "));
    end if;

    if ((valid = '1') and (ready = '1')) then
      write (l, String'(" (BEAT) "));
    end if;


    if (rst = '1') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;

  comment_process : process
    variable l : line;
  begin
    write(l, String'("INFO:  Resetting:"));
    writeline(output, l);
    wait until (count=3);
    write(l, String'("INFO:  Config is 0x"));
    hwrite(l, config);
    writeline(output, l);
    wait until (count=21);
    write(l, String'("INFO:  Start bit (TX goes low):"));
    writeline(output, l);
    wait until (count=30);
    write(l, String'("INFO:  only displaying every 10 clock cycles (10 MHz):"));
    writeline(output, l);
    wait until (count=40);
    write(l, String'("INFO:  begin transmitting payload 0xFF (8 ones):"));
    writeline(output, l);
    wait until (count=120);
    write(l, String'("INFO:  payload continues 0x00 (8 zero):"));
    writeline(output, l);
    wait until (count=200);
    write(l, String'("INFO:  payload continues 0xFF (8 ones):"));
    writeline(output, l);
    wait until (count=280);
    write(l, String'("INFO:  payload continues 0x00 (8 zeros):"));
    writeline(output, l);
    wait until (count=360);
    write(l, String'("INFO:  payload continues 0xFF (8 ones):"));
    writeline(output, l);
    wait until (count=440);
    write(l, String'("INFO:  payload continues 0x00 (8 zero):"));
    writeline(output, l);
    wait until (count=520);
    write(l, String'("INFO:  payload continues 0xFF (8 ones):"));
    writeline(output, l);
    wait until (count=600);
    write(l, String'("INFO:  payload continues 0x00 (8 zeros):"));
    writeline(output, l);
    wait until (count=680);
    write(l, String'("INFO:  stop bit:"));
    writeline(output, l);
    wait until (count=690);
    write(l, String'("INFO:  this extra bit is unecessary, but we are keeping legacy UART firmware for now:"));
    writeline(output, l);
    wait until (count=700);
    write(l, String'("INFO:  start bit:"));
    writeline(output, l);
    wait until (count=710);
    write(l, String'("INFO:  payload (0xAAAAAAAAAAAAAAAA) alternates between 0 and 1 for 64 bits:"));
    writeline(output, l);
    wait until (count=1350);
    write(l, String'("INFO:  stop bit:"));
    writeline(output, l);
    wait;
  end process;


end behaviour;
