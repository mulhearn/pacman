library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity global_unit_tb is
end global_unit_tb;

architecture behaviour of global_unit_tb is
  component global_unit is
    port (
      -- clock and active-high reset
      ACLK                 : in std_logic;
      RST_I                : in std_logic;

      S_REGBUS_RB_RADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE  : in  std_logic;
      S_REGBUS_RB_RACK     : out std_logic;

      S_REGBUS_RB_WUPDATE  : in  std_logic;
      S_REGBUS_RB_WADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK     : out std_logic;

      ANALOG_PWR_EN_O      : out std_logic;
      TILE_EN_O            : out std_logic_vector(C_NUM_TILE-1 downto 0);
      LED_O                : out std_logic_vector(C_NUM_LED-1 downto 0)
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

  signal analog_pwr_en  : std_logic;
  signal tile_en        : std_logic_vector(C_NUM_TILE-1 downto 0);
  signal leds           : std_logic_vector(C_NUM_LED-1 downto 0) := (others => '0');

  signal show_output : std_logic := '0';
begin
  uut0: global_unit port map (
    ACLK                => clk,
    RST_I               => rst,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack,
    ANALOG_PWR_EN_O     => analog_pwr_en,
    TILE_EN_O           => tile_en,
    LED_O => leds
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
    wait for 20 ns;
    raddr   <= x"F020";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"F024";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"F020";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"F024";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;
    raddr   <= x"FF10";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FF14";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FF18";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FF20";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FF24";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FF28";
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
    waddr   <= x"F020";
    wdata   <= x"AAAAAAAA";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"F024";
    wdata   <= x"BBBBBBBB";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"F010";
    wdata   <= x"001103FF";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"F014";
    wdata   <= x"00000003";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait for 10 ns;
    wait;
  end process;

  show_output_process : process
  begin
    show_output<='1';
    wait until (count=100);
    wait for 10 ns;
    show_output<='0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    wait for 10 ns;
    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      --write (l, String'("clk: "));
      --write (l, clk);
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
      write (l, String'(" | ae: "));
      write (l, analog_pwr_en);
      write (l, String'(" | te: 0x"));
      hwrite (l, "00" & tile_en);
      write (l, String'(" | leds: "));
      write (l, leds(0));
      write (l, leds(1));
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
    wait until (count=2);
    write(l, String'("INFO:  Write Scratch A,B,Enables,and LED Config, and read them back"));
    writeline(output, l);
    write(l, String'("INFO:  Check that analog power enable (ae), tile enables (te), and LEDs (leds) turn on as expected"));
    writeline(output, l);
    wait until (count=8);
    write(l, String'("INFO:  Check RO registers: Status, and Firmware version (Major, Minor, Build)"));
    writeline(output, l);
    wait;
  end process;



end behaviour;
