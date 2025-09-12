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
      ACLK	           : in std_logic;
      ARESETN	           : in std_logic;

      S_REGBUS_RB_RADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE  : in  std_logic;
      S_REGBUS_RB_RACK     : out std_logic;

      S_REGBUS_RB_WUPDATE  : in  std_logic;
      S_REGBUS_RB_WADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK     : out std_logic;

      UART_LOOK_I          : in rx_data_array_t;
      UART_STATUS_I        : in uart_reg_array_t;
      UART_CONFIG_O        : out uart_reg_array_t;
      BUFFER_CONFIG_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEARTBEAT_CONFIG_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ROLLOVER_CONFIG_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BUFFER_STATUS_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FIFO_COUNT_I         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
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
  signal gconfig  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal fifo_count  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal show_output : std_logic := '0';
begin
  uut0: rx_registers port map (
    ACLK                => aclk,
    ARESETN             => aresetn,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack,
    UART_LOOK_I         => (others => x"BBBBBBBBAAAAAAAA"),
    UART_STATUS_I       => (others => x"0000ABFF"),
    UART_CONFIG_O       => config,
    BUFFER_CONFIG_O     => gconfig,
    BUFFER_STATUS_I     => x"AAAABBBB",
    FIFO_COUNT_I        => fifo_count
  );

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 20 ns;
    aresetn <= '1';
    wait;
  end process;

  aclk_process : process
  begin
    count <= count + 1;
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
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
    wait for 80 ns;
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
    raddr   <= x"7FA4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FC0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FC4";
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
    raddr   <= x"7FA0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"4010";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4014";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4110";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4114";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"7FB0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FB4";
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
    raddr   <= x"7FB0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FB4";
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
    waddr   <= x"7FA4";
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
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait for 280 ns;
    waddr   <= x"7FA8";
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
    wait until (count=45);
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
      --write (l, String'("aclk: "));
      --write (l, aclk);
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
      if (aresetn = '0') then
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
    wait until (count=2);
    write(l, String'("INFO:  Setting RX config to 0x00001002 via broadcast, then channel 0 only to 0x00001002:"));
    writeline(output, l);
    wait until (count=5);
    write(l, String'("INFO:  Setting RX global config to 0xAA55"));
    writeline(output, l);
    wait until (count=6);
    write(l, String'("INFO:  Setting RX Heartbeat Cycles to 0x1AAA"));
    writeline(output, l);
    wait until (count=7);
    write(l, String'("INFO:  Setting RX Sync Cycles to 0x2BBB"));
    writeline(output, l);
    wait until (count=9);
    write(l, String'("INFO:  Reading back RX config for several channels:"));
    writeline(output, l);
    wait until (count=13);
    write(l, String'("INFO:  Reading back RX global config, heatbeat cycles, and sync cycles."));
    writeline(output, l);
    wait until (count=17);
    write(l, String'("INFO:  Reading RX status for several channels:  (Test pattern input: 0x0000ABFF)"));
    writeline(output, l);
    wait until (count=20);
    write(l, String'("INFO:  Reading RX global status:  (Test pattern input: 0xAAAABBBB)"));
    writeline(output, l);
    wait until (count=22);
    write(l, String'("INFO:  Reading RX look A,B,C,D for several channels:  (Test pattern, A = 0xAAAAAAAA, etc)"));
    writeline(output, l);
    wait until (count=27);
    write(l, String'("INFO:  Reading RX FIFO count and maximum:"));
    writeline(output, l);
    wait until (count=30);
    write(l, String'("INFO:  Reading RX counts repeatedly: (all counters increment by one each tick)"));
    writeline(output, l);
    wait until (count=30);
    write(l, String'("INFO:  zero counters applied"));
    writeline(output, l);
    wait until (count=30);
    write(l, String'("INFO:  FIFO maximum is lower after zero counts"));
    writeline(output, l);
    wait;
  end process;





end behaviour;
