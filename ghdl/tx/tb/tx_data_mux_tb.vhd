library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity tx_data_mux_tb is
end tx_data_mux_tb;

architecture behaviour of tx_data_mux_tb is
  component tx_data_mux is
    port (
      CLK_I      : in std_logic;
      RST_I      : in std_logic;
      SEL_I      : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      DATA_I     : in  uart_data_array_t;
      DATA_O     : out std_logic_vector(C_UART_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal sel      : std_logic_vector(C_SELECT_WIDTH-1 downto 0) := (others => '0');
  signal data     : uart_data_array_t := (others => (others => '0'));
  signal dout     : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);

begin

  uut: tx_data_mux port map (
    CLK_I           => clk,
    RST_I           => rst,
    SEL_I           => sel,
    DATA_I          => data,
    DATA_O          => dout
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
    data <= (others => (others => '0'));
    data(0)(15 downto 0) <= x"1234";
    data(8)(15 downto 0) <= x"AAAA";
    data(9)(15 downto 0) <= x"BBBB";
    data(10)(15 downto 0) <= x"CCCC";
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
    write (l, String'(" out: 0x"));
    hwrite (l, dout);
    if (rst = '1') then
      write (l, String'(" (RESET)"));
    end if;

    writeline(output, l);
  end process;

end behaviour;
