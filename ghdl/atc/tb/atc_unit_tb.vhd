library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity atc_unit_tb is
end atc_unit_tb;

architecture behaviour of atc_unit_tb is
  component atc_unit is
    port (
    ACLK                 : in std_logic; -- fast clock
    RST_I                : in std_logic;
    UCLK_I               : in std_logic; -- slow clock

    S_REGBUS_RB_RADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RUPDATE   : in  std_logic;
    S_REGBUS_RB_RACK      : out std_logic;

    S_REGBUS_RB_WUPDATE   : in  std_logic;
    S_REGBUS_RB_WADDR	    : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK      : out std_logic;

    LEMO_A_I              : in std_logic;
    LEMO_B_I              : in std_logic;

    TIMESTAMP_O           : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    UCLK_O                : out std_logic;
    G_O                   : out std_logic_vector(C_NUM_TILE-1 downto 0);
    H_O                   : out std_logic_vector(C_NUM_TILE-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal clk     : std_logic;
  signal rst  : std_logic;
  signal uclk     : std_logic;
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

-- dut inputs:
  signal lemo_a   :  std_logic := '0';
  signal lemo_b   :  std_logic := '0';

  -- dut outputs
  signal timestamp  : std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
  signal atc_h      :  std_logic_vector(9 downto 0) := (others => '0');
  signal atc_g      :  std_logic_vector(9 downto 0) := (others => '0');

  signal show_output : std_logic := '0';
begin
  uut0: atc_unit port map (
    ACLK                => clk,
    RST_I               => rst,
    UCLK_I              => uclk,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack,
    LEMO_A_I            => lemo_a,
    LEMO_B_I            => lemo_b,
    TIMESTAMP_O         => timestamp,
    G_O                 => atc_g,
    H_O                 => atc_h
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

  uclk_process : process
  begin
    uclk <= '1';
    wait for 50 ns;
    uclk <= '0';
    wait for 50 ns;
  end process;

  lemo_a_process : process
  begin
    lemo_a   <= '0';
    wait for 200 ns;
    lemo_a   <= '1';
    wait for 200 ns;
    lemo_a   <= '0';
    wait for 200 ns;
  end process;

  lemo_b_process : process
  begin
    lemo_b   <= '0';
    wait for 200 ns;
    lemo_b   <= '1';
    wait for 200 ns;
    lemo_b   <= '0';
    wait for 200 ns;
  end process;

  read_process : process
  begin
    raddr   <= x"E204";
    --raddr   <= x"E004";
    rupdate <= '1';
    wait;
  end process;

  write_process : process
  begin
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait for 20 ns;
    -- polarity configuration
    waddr   <= x"E108";
    wdata   <= x"03FF0000";
    wupdate <= '1';
    wait for 10 ns;
    -- destination configuratin for LEMO A
    waddr   <= x"E110";
    wdata   <= x"03FF0031";
    wupdate <= '1';
    wait for 10 ns;
    -- destination configuratin for LEMO B
    waddr   <= x"E114";
    wdata   <= x"00000000";
    wupdate <= '1';
    wait for 10 ns;
    -- destination configuratin for POKE C
    waddr   <= x"E118";
    wdata   <= x"03FF0012";
    wupdate <= '1';
    wait for 10 ns;
    -- destination configuratin for POKE D
    waddr   <= x"E11C";
    wdata   <= x"00000000";
    wupdate <= '1';
    wait for 10 ns;
    -- request config update in detector clock domain:
    waddr   <= x"E100";
    wdata   <= x"00000000";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait for 500 ns;
    waddr   <= x"E0C0";
    wdata   <= x"0000000F";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait until (count=100);
    waddr   <= x"E200";
    wdata   <= x"00000050";
    wupdate <= '1';


    wait;
  end process;

  show_output_process : process
  begin
    show_output<='1';
    wait until (count=200);
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
      write (l, String'(" "));
      write (l, uclk);
      write (l, String'(" la: "));
      write (l, lemo_a);
      write (l, String'(" | ra: 0x"));
      hwrite (l, raddr);
      write (l, String'(" u:"));
      write (l, rupdate);
      write (l, String'(" d: 0x"));
      hwrite (l, rdata);
      write (l, String'(" k:"));
      write (l, rack);
      write (l, String'(" | wa: 0x"));
      hwrite (l, waddr);
      write (l, String'(" u:"));
      write (l, wupdate);
      write (l, String'(" d: 0x"));
      hwrite (l, wdata);
      write (l, String'(" k:"));
      write (l, wack);
      write (l, String'(" | G: "));
      write (l, atc_g);
      write (l, String'("  H: "));
      write (l, atc_h);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
