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
      CLK_I      : in std_logic;
      RST_I      : in std_logic;
      SEL_I      : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      WTYPE_I    : in  std_logic_vector(C_BYTE-1 downto 0);
      HEADER_A_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEADER_B_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEADER_C_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEADER_D_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      PACMAN_I   : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CHAN_I     : in uart_small_array_t;
      HEADER_O   : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
    );
  end component;

  signal count      : integer := 0;
  signal clk        : std_logic;
  signal rst        : std_logic;
  signal rst_z      : std_logic;
  signal header     : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
  signal cselect    : std_logic_vector(C_SELECT_WIDTH-1 downto 0) := (others => '0');
  signal wtype      : std_logic_vector(C_BYTE-1 downto 0);

  signal chan       : uart_small_array_t;
begin
  --tstamp_in <= std_logic_vector(to_unsigned(count, tstamp_in'length));

  uut: rx_header port map (
    CLK_I      => clk,
    RST_I      => rst,
    SEL_I      => cselect,
    WTYPE_I    => wtype,
    HEADER_A_I => x"00481553",
    HEADER_B_I => x"00531553",
    HEADER_C_I => x"0000CCCC",
    HEADER_D_I => x"0000DDDD",
    PACMAN_I   => x"00000015",
    CHAN_I     => chan,
    HEADER_O   => header
  );

  chan_process : process
  begin
    for i in 0 to 39 loop
      chan(i) <= std_logic_vector(to_unsigned(i + 1, 16));
    end loop;
    wait;
  end process;

  cselect_process : process
  begin
    wait for 2 ns;
    cselect <= std_logic_vector(to_unsigned(count, cselect'length));
    wait for 8 ns;
  end process;

  wtype_process : process
  begin
    wait for 1 ns;
    if (rst='1') or (rst_z='1') then
      wtype <= x"00";
    else
      if (to_integer(unsigned(cselect)) < 40) then
        wtype <= x"44";
      else
        wtype <= x"00";
      end if;
    end if;
    wait for 9 ns;
  end process;

  clk_process : process
  begin
    rst_z <= rst;
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


  output_process : process
    variable l : line;
    variable start   : std_logic := '0';
    variable update  : std_logic := '0';
    variable lost    : std_logic := '0';
  begin
    wait for 10 ns;

    write (l, String'("c: "));
    write (l, count, left, 5);
    write  (l, String'(" | chan: 0x"));
    hwrite (l, "00" & cselect);
    write  (l, String'(" | h: 0x"));
    hwrite (l, header);
    if (rst = '1') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;

end behaviour;
