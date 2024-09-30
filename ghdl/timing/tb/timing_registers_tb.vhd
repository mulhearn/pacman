library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity timing_registers_tb is
end timing_registers_tb;

architecture behaviour of timing_registers_tb is
  component timing_registers is
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

      TRIG_UPDATE_O          : out std_logic;
      TRIG_CONFIG_O          : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      TRIG_BUSY_I            : in std_logic;

      SYNC_UPDATE_O          : out std_logic;
      SYNC_CONFIG_O          : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SYNC_BUSY_I            : in std_logic;

      STATUS_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      TIMESTAMP_I         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)    
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

  -- dut outputs
  signal trig_update    : std_logic;
  signal trig_config    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal sync_update    : std_logic;
  signal sync_config    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  signal show_output : std_logic := '0';
begin
  uut0: timing_registers port map (
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
    TRIG_UPDATE_O       => trig_update,
    TRIG_CONFIG_O       => trig_config,
    TRIG_BUSY_I         => '1',
    SYNC_UPDATE_O       => sync_update,
    SYNC_CONFIG_O       => sync_config,
    SYNC_BUSY_I         => '1',
    STATUS_I            => x"ABCDEF12",
    TIMESTAMP_I         => x"0000A435"
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
    raddr   <= x"FE00";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FE04";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FE20";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FE24";
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
    wait for 20 ns;
    waddr   <= x"FE20";
    wdata   <= x"000103FF";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"FE24";
    wdata   <= x"000403FF";
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
    wait until (count=15);
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
      write (l, String'(" | ra: 0x"));
      hwrite (l, raddr);
      write (l, String'(" ru:"));
      write (l, rupdate);
      write (l, String'(" rd: 0x"));
      hwrite (l, rdata);
      write (l, String'(" rk:"));
      write (l, rack);
      write (l, String'(" | wa: 0x"));
      hwrite (l, waddr);
      write (l, String'(" wu:"));
      write (l, wupdate);
      write (l, String'(" wd: 0x"));
      hwrite (l, wdata);
      write (l, String'(" wk:"));
      write (l, wack);
      write (l, String'(" | tu: "));
      write (l, trig_update);
      write (l, String'(" c: 0x"));
      hwrite (l, trig_config);
      write (l, String'(" | su: "));
      write (l, sync_update);
      write (l, String'(" c: 0x"));
      hwrite (l, sync_config);

      if (aresetn = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
