library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity rx_timestamp_mux_tb is
end rx_timestamp_mux_tb;

architecture behaviour of rx_timestamp_mux_tb is
  component rx_timestamp_mux is
    port (
      CLK_I       : in std_logic;
      RST_I       : in std_logic;
      SEL_I       : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      TIMESTAMP_I : in  rx_timestamp_array_t;
      TIMESTAMP_O : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
    );
  end component;

  signal count     : integer := 0;
  signal clk       : std_logic;
  signal rst       : std_logic;
  signal sel       : std_logic_vector(C_SELECT_WIDTH-1 downto 0) := (others => '0');
  signal timestamp : rx_timestamp_array_t;
  signal tso       : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);

begin

  uut: rx_timestamp_mux port map (
    CLK_I           => clk,
    RST_I           => rst,
    SEL_I           => sel,
    TIMESTAMP_I     => timestamp,
    TIMESTAMP_O     => tso
  );

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

  data_process : process
  begin
    timestamp <= (others => (others => '0'));
    timestamp(0)(15 downto 0) <= x"1234";
    timestamp(8)(15 downto 0) <= x"AAAA";
    timestamp(9)(15 downto 0) <= x"BBBB";
    timestamp(10)(15 downto 0) <= x"CCCC";
    wait;
  end process;

  select_process : process
  begin
    sel <= (others => '0');
    wait for 1 ns;
    wait for 20 ns;
    sel(3 downto 0) <= x"8";
    wait for 10 ns;
    sel(3 downto 0) <= x"9";
    wait for 10 ns;
    sel(3 downto 0) <= x"A";
    wait for 10 ns;
    sel <= (others => '1');
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    wait for 10 ns;

    write (l, String'("c: "));
    write (l, count, left, 4);

    write (l, String'(" sel: 0x"));
    hwrite (l, "00" & sel);

    write (l, String'(" ts: 0x"));
    hwrite (l, tso);
    if (rst = '1') then
      write (l, String'(" (RESET)"));
    end if;

    writeline(output, l);
  end process;

end behaviour;
