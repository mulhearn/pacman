library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity rx_registers_tb is
end rx_registers_tb;

architecture behaviour of rx_registers_tb is
  component rx_registers is
    port (
      CLK_I	          : in std_logic;
      RST_I	          : in std_logic;

      S_REGBUS_RB_RADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE : in  std_logic;
      S_REGBUS_RB_RACK    : out std_logic;

      S_REGBUS_RB_WUPDATE : in  std_logic;
      S_REGBUS_RB_WADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	  : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK    : out std_logic;

      UART_STATUS_I       : in  uart_reg_array_t;
      UART_CONFIG_O       : out uart_reg_array_t;
      UART_CHAN_O         : out uart_small_array_t;

      BUFFER_STATUS_I     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FIFO_COUNT_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BUFFER_CONFIG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BUFFER_ENABLES_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      PACMAN_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEARTBEAT_CONFIG_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ROLLOVER_CONFIG_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      WORD_TYPE_LUT_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEARTBEAT_HEADER_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ROLLOVER_HEADER_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      EOP_HEADER_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
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

  signal uconfig   : uart_reg_array_t;
  signal uchan     : uart_small_array_t;
  signal bconfig  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal pacman   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal wlut     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal fifo_count  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal show_output : std_logic := '0';
begin
  uut0: rx_registers port map (
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
    UART_STATUS_I       => (others => x"0000ABFF"),
    UART_CONFIG_O       => uconfig,
    UART_CHAN_O         => uchan,
    BUFFER_CONFIG_O     => bconfig,
    PACMAN_O            => pacman,
    WORD_TYPE_LUT_O     => wlut,
    BUFFER_STATUS_I     => x"AAAABBBB",
    FIFO_COUNT_I        => fifo_count,
    LOOK_UART_DATA_I    => x"BBBBBBBBAAAAAAAA"
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

  fifo_count_process : process
  begin
    fifo_count <= x"00000000";
    wait for 50 ns;
    fifo_count <= x"00000100";
    wait for 10 ns;
    fifo_count <= x"00000010";
    wait;
  end process;

  read_process : process
  begin
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 1 ns;
    wait for 100 ns;
    raddr   <= x"4C04";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4004";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4104";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"7FB4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FBC";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FC0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FC4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FC8";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"4C00";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4000";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"7FB0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"7FA0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FA4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FA8";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"7FF0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FF4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"4020";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4024";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4028";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"402C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4C20";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4C24";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4C28";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4C2C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4020";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4024";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4028";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"402C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"7FF0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FF4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"7FD0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FD4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FDC";
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
    waddr   <= x"7B04";
    wdata   <= x"00001002";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"4004";
    wdata   <= x"00001001";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FB4";
    wdata   <= x"0000AA55";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FC0";
    wdata   <= x"00001AAA";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FC4";
    wdata   <= x"00002BBB";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FC8";
    wdata   <= x"44444444";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FBC";
    wdata   <= x"00000011";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait for 270 ns;
    waddr   <= x"7FF8";
    wdata   <= x"00000000";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait;
  end process;

  show_output_process : process
  begin
    show_output<='1';
    wait until (count=53);
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
      --write (l, String'("clk: "));
      --write (l, clk);
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
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;


  comment_process : process
    variable l : line;
  begin
    write(l, String'("INFO:  Resetting:"));
    writeline(output, l);
    wait until (count=3);
    write(l, String'("INFO:  Setting RX config to 0x00001002 via broadcast, then channel 0 only to 0x00001002:"));
    writeline(output, l);
    wait until (count=5);
    write(l, String'("INFO:  Setting RX buffer config to 0xAA55"));
    writeline(output, l);
    wait until (count=6);
    write(l, String'("INFO:  Setting RX heartbeat config to 0x1AAA"));
    writeline(output, l);
    wait until (count=7);
    write(l, String'("INFO:  Setting RX sync config to 0x2BBB"));
    writeline(output, l);
    wait until (count=8);
    write(l, String'("INFO:  Setting RX LUT"));
    writeline(output, l);
    wait until (count=9);
    write(l, String'("INFO:  Setting PACMAN id"));
    writeline(output, l);
    wait until (count=11);
    write(l, String'("INFO:  Reading back RX config for several channels:"));
    writeline(output, l);
    wait until (count=15);
    write(l, String'("INFO:  Reading back RX buffer config, PACMAN ID, heatbeat config, sync config, and word type LUT:"));
    writeline(output, l);
    wait until (count=21);
    write(l, String'("INFO:  Reading RX status for several channels:  (Test pattern input: 0x0000ABFF)"));
    writeline(output, l);
    wait until (count=24);
    write(l, String'("INFO:  Reading RX buffer status:  (Test pattern input: 0xAAAABBBB)"));
    writeline(output, l);
    wait until (count=26);
    write(l, String'("INFO:  Reading RX look A,B,C,D for several channels:  (Test pattern, A = 0xAAAAAAAA, etc)"));
    writeline(output, l);
    wait until (count=31);
    write(l, String'("INFO:  Reading RX FIFO count and maximum:"));
    writeline(output, l);
    wait until (count=34);
    write(l, String'("INFO:  Reading RX counts repeatedly: (all counters increment by one each tick)"));
    writeline(output, l);
    wait until (count=37);
    write(l, String'("INFO:  Zero counters command (and counters reset)"));
    writeline(output, l);
    wait until (count=47);
    write(l, String'("INFO:  FIFO maximum is lower after zero counts"));
    writeline(output, l);
    wait until (count=50);
    write(l, String'("INFO:  read headers"));
    writeline(output, l);

    wait;
  end process;





end behaviour;
