library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity rx_unit_tb is
end rx_unit_tb;

architecture behaviour of rx_unit_tb is
  component rx_unit is
    port (
      M_AXIS_ACLK            : in std_logic;
      M_AXIS_ARESETN         : in std_logic;
      M_AXIS_TDATA           : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      M_AXIS_TVALID          : out std_logic;
      M_AXIS_TREADY          : in std_logic;
      M_AXIS_TKEEP           : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
      M_AXIS_TLAST           : out std_logic;

      S_REGBUS_RB_RADDR      : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;

      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR      : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      TIMESTAMP_I            : in  std_logic_vector(31 downto 0);
      FIFO_RCNT_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FIFO_WCNT_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DMA_ITR_I              : in  std_logic;

      PISO_I                 : in  std_logic_vector(C_NUM_UART-1 downto 0);
      LOOPBACK_I             : in  std_logic_vector(C_NUM_UART-1 downto 0)
      );
  end component;

  signal timestamp : std_logic_vector(31 downto 0);
  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
  signal uclk     : std_logic;

  signal tdata    : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
  signal tvalid   : std_logic;
  signal tready   : std_logic := '0';
  signal tlast    : std_logic;

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

  signal piso     : std_logic_vector(C_NUM_UART-1 downto 0) := (others => '0');
  signal rx       : std_logic := '1';

  -- control the output for different stages of the demo:
  signal show_regbus_output : std_logic := '0';
  signal show_axis_output   : std_logic := '0';
  signal show_rx_output     : std_logic := '0';

begin
  uut: rx_unit port map (
    M_AXIS_ACLK     => aclk,
    M_AXIS_ARESETN  => aresetn,
    M_AXIS_TDATA    => tdata,
    M_AXIS_TVALID   => tvalid,
    M_AXIS_TREADY   => tready,
    M_AXIS_TLAST    => tlast,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack,
    TIMESTAMP_I         => timestamp,
    FIFO_RCNT_I         => x"CCCCCCCC",
    FIFO_WCNT_I         => x"CCCCCCCC",
    DMA_ITR_I           => '1',
    PISO_I              => piso,
    LOOPBACK_I          => (others => '1')
  );

  aclk_process : process
  begin
    count <= count + 1;
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  timestampe_process : process
  begin
    timestamp <= x"00000000";
    wait until count=1100;
    timestamp <= x"00000ABC";
    wait;
  end process;

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 10 ns;
    aresetn <= '1';
    wait;
  end process;

  uclk_process : process
  begin
    uclk <= '1';
    wait for 50 ns;
    uclk <= '0';
    wait for 50 ns;
  end process;

  read_process : process
  begin
    show_regbus_output <= '1';
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 1 ns;
    wait for 30 ns;
    raddr   <= x"4000";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FA0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FA4";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4004";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"4020";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    show_regbus_output <= '0';
    wait for 20 us;
    show_regbus_output <= '1';
    raddr   <= x"4000";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FA0";
    rupdate <= '1';
    wait for 30 ns;
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
    raddr   <= x"7FC0";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"7FC4";
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
    waddr   <= x"7B04";
    wdata   <= x"00001001";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FA4";
    wdata   <= x"00000003";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FA8";
    wdata   <= x"00000000";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FC0";
    wdata   <= x"00000001";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"7FC4";
    wdata   <= x"00000ABC";
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
      if (aresetn = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;



  axis_process : process
  begin
    tready <= '1';
    wait;
  end process;

  show_axis_output_process : process
  begin
    show_axis_output<='0';
    wait until (count=740);
    show_axis_output<='1';
    wait until (count=1610);
    wait for 10 ns;
    show_axis_output<='0';
    wait;
  end process;


  axis_output_process : process
    variable suppress_zero : std_logic := '1';
    variable l : line;
  begin
    wait for 10 ns;
    if (show_axis_output='1') then
      if (suppress_zero='0' or ((tvalid='1') and (tready='1'))) then
        write (l, String'("c: "));
        write (l, count, left, 4);
        --write (l, String'("aclk: "));
        --write (l, aclk);
        write (l, String'("|| tdata: 0x"));
        hwrite (l, tdata);
        write (l, String'("..."));
        write (l, String'(" tval: "));
        write (l, tvalid);
        write (l, String'(" trdy: "));
        write (l, tready);
        write (l, String'(" ltast: "));
        write (l, tlast);
        if ((tvalid='1') and (tready='1')) then
          write (l, String'(" - "));
        end if;

        if (tlast = '1') then
          write (l, String'(" *** "));
        end if;
        if (aresetn = '0') then
          write (l, String'(" (RESET)"));
        end if;
        writeline(output, l);
      end if;
    end if;
  end process;

  piso(39 downto 32) <= (others => '0');
  piso(31 downto 0)  <= (others => rx);

  rx_process : process
    variable i      : integer := 0;
    variable rxdata : std_logic_vector(159 downto 0) := x"FF33332222000011117FFF33331111000011117F";
  begin
    wait for 20 ns;
    wait until rising_edge(uclk);
    wait for 1 ns;
    if (i<160) then
      rx <= rxdata(i);
      i := i+1;
    else
      rx <= '1';
      wait;
      wait for 500 ns;
      i := 0;
    end if;
  end process;

  show_rx_process : process
  begin
    show_rx_output<='0';
    wait until (count=100);
    show_rx_output<='1';
    wait until (count=700);
    wait for 10 ns;
    show_rx_output<='0';
    wait;
  end process;

  rx_output_process : process
    variable l : line;
  begin
    wait for 100 ns;
    if (show_rx_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      --write (l, String'("aclk: "));
      --write (l, aclk);
      write (l, String'("|| PISO: 0x"));
      hwrite (l, piso);
      --write (l, String'("|| NOT: 0x"));
      --hwrite (l, not piso);
      writeline(output, l);
    end if;
  end process;




end behaviour;
