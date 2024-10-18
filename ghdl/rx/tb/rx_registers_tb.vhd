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
      ACLK	        : in std_logic;
      ARESETN	        : in std_logic;

      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;

      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      LOOK_I                 : in uart_rx_data_array_t;
      STATUS_I               : in uart_reg_array_t;
      CONFIG_O               : out uart_reg_array_t;
      GFLAGS_O               : out std_logic_vector(C_RX_GFLAGS_WIDTH-1 downto 0);
      HEARTBEAT_CYCLES_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SYNC_CYCLES_O          : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      GSTATUS_I              : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FIFO_RCNT_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FIFO_WCNT_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DMA_ITR_I              : in  std_logic
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
  signal gflags   : std_logic_vector(C_RX_GFLAGS_WIDTH-1 downto 0);

  signal show_output : std_logic := '0';
begin
  uut0: rx_registers port map (
    ACLK           => aclk,
    ARESETN        => aresetn,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack,
    LOOK_I    => (others => x"DDDDDDDDCCCCCCCCBBBBBBBBAAAAAAAA"),
    STATUS_I  => (others => x"0000ABFF"),
    CONFIG_O  => config,
    GFLAGS_O  => gflags,
    GSTATUS_I => x"AAAABBBB",
    FIFO_RCNT_I => x"000A0001",
    FIFO_WCNT_I => x"000B0001",
    DMA_ITR_I => '1'
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

  read_process : process
  begin
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 1 ns;
    wait for 20 ns;
    raddr   <= x"4000";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4004";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FC0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FC4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4204";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4104";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FA0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FA4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FB0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FB4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FB8";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FC0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FC4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4010";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4014";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4018";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"401C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4C00";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4C04";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4C50";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4020";
    rupdate <= '1';
    wait for 50 ns;
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
    wait;
  end process;

  write_process : process
  begin
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait for 1 ns;
    wait for 30 ns;
    waddr   <= x"7B04";
    wdata   <= x"0BB01001";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"4004";
    wdata   <= x"0AA01001";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"4104";
    wdata   <= x"0CC01101";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FA4";
    wdata   <= x"0000FFFF";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FC0";
    wdata   <= x"00011000";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FC4";
    wdata   <= x"00000010";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait for 120 ns;
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
    wait until (count=30);
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

end behaviour;
