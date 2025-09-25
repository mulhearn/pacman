library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity rx_header_tb is
end rx_header_tb;

architecture behaviour of rx_header_tb is
  component rx_header is
    port (
      ACLK        : in std_logic;
      ARESETN     : in std_logic;
      PACMAN_I    : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LUT_I       : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CHAN_I      : in uart_reg_array_t;
      DATA_I      : in uart_data_array_t;
      HEADER_O    : out uart_reg_array_t;
      DEBUG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal count      : integer := 0;
  signal aclk       : std_logic;
  signal aresetn    : std_logic;
  signal headers    : uart_reg_array_t;
  signal data       : uart_data_array_t := (others => (others => '0'));
begin
  --tstamp_in <= std_logic_vector(to_unsigned(count, tstamp_in'length));

  uut: rx_header port map (
    ACLK        => aclk,
    ARESETN     => aresetn,
    CHAN_I      => (others => x"00000011"),
    LUT_I       => x"DDCCBBAA",
    PACMAN_I    => x"00000015",
    DATA_I      => data,
    HEADER_O    => headers
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

  data_process : process
  begin
    data(0)(1 downto 0) <= "00";
    wait for 10 ns;
    data(0)(1 downto 0) <= "01";
    wait for 10 ns;
    data(0)(1 downto 0) <= "10";
    wait for 10 ns;
    data(0)(1 downto 0) <= "11";
    wait for 10 ns;
  end process;

  output_process : process
    variable l : line;
    variable start   : std_logic := '0';
    variable update  : std_logic := '0';
    variable lost    : std_logic := '0';
  begin
    wait for 10 ns;

    write (l, String'("c: "));
    write (l, count, left, 5);
    write  (l, String'(" | h0: 0x"));
    hwrite (l, headers(0));
    write  (l, String'(" | h1: 0x"));
    hwrite (l, headers(1));
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;

end behaviour;
