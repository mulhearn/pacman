library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity tx_registers_tb is
end tx_registers_tb;

architecture behaviour of tx_registers_tb is
  component tx_registers is
    port (
      CLK_I	             : in std_logic;
      RST_I	             : in std_logic;

      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;

      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      UART_STATUS_I          : in uart_reg_array_t;
      UART_CONFIG_O          : out uart_reg_array_t;
      BUFFER_STATUS_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LOOK_SELECT_O       : out std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      LOOK_UART_DATA_I    : in std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;
  -- read signals:
  signal raddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rupdate  : std_logic := '0';
  signal rdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rack     : std_logic := '0';
  -- write signals:
  signal waddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wupdate  : std_logic := '0';
  signal wdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal wack     : std_logic := '0';

  signal config   : uart_reg_array_t;

begin
  uut0: tx_registers port map (
    CLK_I               => clk,
    RST_I               => rst,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack,
    LOOK_UART_DATA_I  => x"DDDDDDDDCCCCCCCC",
    UART_STATUS_I  => (others => x"1234ABCD"),
    BUFFER_STATUS_I  => x"AABBCCDD",
    UART_CONFIG_O  => config
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

  read_process : process
  begin
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 1 ns;
    wait for 40 ns;
    raddr   <= x"0C04";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0004";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0104";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"3FA0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"3FA4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"3FA8";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0C00";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"0020";
    rupdate <= '1';
    wait for 80 ns;
    raddr   <= x"0C20";
    rupdate <= '1';
    wait for 50 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"3FB0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait;
  end process;

  write_process : process
  begin
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait for 1 ns;
    wait for 20 ns;
    waddr   <= x"3B04";
    wdata   <= x"00001601";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0004";
    wdata   <= x"AAAA1601";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait for 130 ns;
    waddr   <= x"3FF8";
    wdata   <= x"00000000";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    wait for 10 ns;
    write (l, String'("c: "));
    write (l, count, left, 4);
    write (l, String'(" || ra: 0x"));
    hwrite (l, raddr);
    write (l, String'(" ru:"));
    write (l, rupdate);
    write (l, String'(" rd: 0x"));
    hwrite (l, rdata);
    write (l, String'(" rk:"));
    write (l, rack);
    write (l, String'(" || wa: 0x"));
    hwrite (l, waddr);
    write (l, String'(" wu:"));
    write (l, wupdate);
    write (l, String'(" wd: 0x"));
    hwrite (l, wdata);
    write (l, String'(" wk:"));
    write (l, wack);
    write (l, String'(" || cfg(0):  0x"));
    hwrite (l, config(0));
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
    write(l, String'("INFO:  Setting TX config to 0x00001601 via broadcast, then channel 0 only to 0xAAAA1601:"));
    writeline(output, l);
    wait until (count=5);
    write(l, String'("INFO:  Reading back TX config for several channels:"));
    writeline(output, l);
    wait until (count=9);
    write(l, String'("INFO:  Reading TX look for several channels:  (Test pattern input: 0xCCCCCCCC 0xDDDDDDDD)"));
    writeline(output, l);
    wait until (count=14);
    write(l, String'("INFO:  Reading TX status for several channels: (Test pattern input:  0x1234ABCD)"));
    writeline(output, l);
    wait until (count=17);
    write(l, String'("INFO:  Reading TX counts repeatedly, it should increment and restart at zero with write to zero count register"));
    writeline(output, l);
    wait until (count=31);
    write(l, String'("INFO:  Reading TX global status: (Test pattern input:  0xAABBCCDD)"));
    writeline(output, l);
    wait;
  end process;

end behaviour;

