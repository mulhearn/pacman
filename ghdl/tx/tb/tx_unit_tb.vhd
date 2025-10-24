library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity tx_unit_tb is
end tx_unit_tb;

architecture behaviour of tx_unit_tb is
  component tx_unit is
    port (
      ACLK                   : in std_logic;
      RST_I                  : in std_logic;
      UCLK_I                 : in  std_logic;

      S_AXIS_TDATA           : in std_logic_vector(C_TX_AXIS_WIDTH-1 downto 0);
      S_AXIS_TVALID          : in std_logic;
      S_AXIS_TREADY          : out std_logic;
      S_AXIS_TKEEP           : in std_logic_vector(C_TX_AXIS_WIDTH/8-1 downto 0);
      S_AXIS_TLAST           : in std_logic;

      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;

      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      POSI_O                 : out std_logic_vector(C_NUM_UART-1 downto 0);
      DEBUG_O                : out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  signal count    : integer := 0;
  signal clk      : std_logic  := '0';
  signal rst      : std_logic  := '0';
  signal uclk     : std_logic  := '0';

  signal tdata    : std_logic_vector(C_TX_AXIS_WIDTH-1 downto 0) := (others => '0');
  signal tvalid   : std_logic := '0';
  signal tready   : std_logic := '0';
  signal tlast    : std_logic := '0';

  -- read signals:
  signal raddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rupdate  : std_logic := '0';
  signal rdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal rack     : std_logic := '0';
  -- write signals:
  signal waddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wupdate  : std_logic := '0';
  signal wdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal wack     : std_logic := '0';

  signal posi     : std_logic_vector(C_NUM_UART-1 downto 0);

  signal debug    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  -- control the output for different stages of the demo:
  signal show_regbus_output : std_logic := '0';
  signal show_axis_output   : std_logic := '0';
  signal show_tx_output     : std_logic := '0';

begin
  uut: tx_unit port map (
    ACLK            => clk,
    RST_I           => rst,
    UCLK_I          => uclk,
    S_AXIS_TDATA    => tdata,
    S_AXIS_TVALID   => tvalid,
    S_AXIS_TREADY   => tready,
    S_AXIS_TKEEP    => (others => '1'),
    S_AXIS_TLAST    => tlast,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack,
    POSI_O              => posi,
    DEBUG_O             => debug
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

  uclk_process : process
  begin
    uclk <= '1';
    wait for 50 ns;
    uclk <= '0';
    wait for 50 ns;
  end process;

  runshow_process : process
  begin
    show_tx_output <= '0';
    wait for 600 ns;
    show_tx_output <= '1';
    wait for 7200 ns;
    show_tx_output <= '0';
    wait;
  end process;

  stream_process : process
    variable ibuf : integer := 0;
  begin
    tvalid <= '0';
    tdata(63 downto 0)    <= (others => '0');
    tlast                 <= '0';
    wait for 1 ns;
    wait for 90 ns;
    show_axis_output<='1';
    tvalid <= '1';
    tdata(63 downto 0)    <= x"000000FFFFFFFFFF";
    tlast                 <= '0';
    wait for 10 ns;
    for i in 0 to 40-1 loop
      tvalid <= '1';
      tdata <= (others => '0');
      ibuf := 16#1111CC00# + 2*i;
      tdata(31 downto 0)    <= std_logic_vector(to_unsigned(ibuf, 32));
      ibuf := 16#1111DD00# + 2*i;
      tdata(63 downto 32)    <= std_logic_vector(to_unsigned(ibuf, 32));
      if (i < 40-1) then
        tlast <= '0';
      else
        tlast <= '1';
      end if;
      wait for 10 ns;
    end loop;
    tvalid                <= '0';
    tdata                 <= (others => '0');
    tlast                 <= '0';
    wait for 10 ns;
    show_axis_output<='0';
    wait;
  end process;

  read_process : process
  begin
    show_regbus_output <= '1';
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 1 ns;
    wait for 30 ns;
    raddr   <= x"0004";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0C04";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0020";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0C20";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    show_regbus_output <= '0';
    wait for 8000 ns;
    show_regbus_output <= '1';
    wait for 10 ns;
    raddr   <= x"0020";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0C20";
    rupdate <= '1';
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
    show_regbus_output <= '0';
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
    waddr   <= x"3FA0";
    wdata   <= x"0000000A";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait;
  end process;

  regbus_output_process : process
    variable l : line;
  begin
    wait for 10 ns;
    if (show_regbus_output='1') then
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
      write (l, String'(" || debug: 0x"));
      hwrite (l, debug);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

  axis_output_process : process
    variable l : line;
  begin
    wait for 10 ns;
    if (show_axis_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      --write (l, String'("aclk: "));
      --write (l, aclk);
      write (l, String'("|| tdata: 0x"));
      hwrite (l, tdata(15 downto 0));
      write (l, String'("..."));
      write (l, String'(" tval: "));
      write (l, tvalid);
      write (l, String'(" trdy: "));
      write (l, tready);
      write (l, String'(" ltast: "));
      write (l, tlast);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

  tx_output_process : process
    variable l : line;
  begin
    wait for 100 ns;
    if (show_tx_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      --write (l, String'("aclk: "));
      --write (l, aclk);
      write (l, String'("|| POSI: 0x"));
      hwrite (l, posi);
      --write (l, String'("|| NOT: 0x"));
      --hwrite (l, not posi);
      writeline(output, l);
    end if;
  end process;

  comment_process : process
    variable l : line;
  begin
    write(l, String'("INFO:  DEBUG output at start: 0x"));
    hwrite(l, debug);
    writeline(output, l);
    write(l, String'("INFO:  Resetting:"));
    writeline(output, l);
    wait until (count=3);
    write(l, String'("INFO:  Setting TX config via broadcast (0x3B04), reading back config, and checking counts are zero:"));
    writeline(output, l);
    wait until (count=10);
    write(l, String'("INFO:  TX data arrives on AXI Stream:  21 beats of 128 bits each (40 64-bit uart packets plus one 128-bit header) "));
    writeline(output, l);
    wait until (count=60);
    write(l, String'("INFO:  TX begins with start bit (0) on each uart channel:"));
    writeline(output, l);
    wait until (count=730);
    write(l, String'("INFO:  TX ends with stop bit (1) on each uart channel:"));
    writeline(output, l);
    write(l, String'("INFO:  TX output remains high until the next transmission:"));
    writeline(output, l);
    wait until (count=800);
    write(l, String'("INFO:  Read the TX count and look registers for several UART channels:"));
    writeline(output, l);
    wait;
  end process;


end behaviour;

