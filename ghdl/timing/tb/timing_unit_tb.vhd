library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity timing_unit_tb is
end timing_unit_tb;

architecture behaviour of timing_unit_tb is
  component timing_unit is
    port (
    ACLK                 : in std_logic; -- fast clock
    ARESETN              : in std_logic;
    UCLK                 : in std_logic; -- slow clock


    --lemo signal
    LEMO_A                : in std_logic;
    LEMO_B                : in std_logic;

    S_REGBUS_RB_RADDR	    : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RUPDATE   : in  std_logic;
    S_REGBUS_RB_RACK      : out std_logic;
    
    S_REGBUS_RB_WUPDATE   : in  std_logic;
    S_REGBUS_RB_WADDR	    : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK      : out std_logic;

    TIMESTAMP_O           : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    GLB_CLK_O             : out std_logic;
    G_O                   : out std_logic_vector(C_NUM_TILE-1 downto 0);
    H_O                   : out std_logic_vector(C_NUM_TILE-1 downto 0);
    TS_SYNC               : out std_logic;
    DEBUG                 : out std_logic_vector(7 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
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

  signal lemo_a   :  std_logic := '0';
  signal lemo_b   :  std_logic := '0';
  -- dut outputs
  signal glb_clk    : std_logic;
  signal atc_h      :  std_logic_vector(9 downto 0) := (others => '0'); 
  signal atc_g      :  std_logic_vector(9 downto 0) := (others => '0'); 
  signal ts_sy      :  std_logic;
  signal timestamp  : std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
  signal  debug           :  std_logic_vector(7 downto 0);
  signal show_output : std_logic := '0';
begin
  uut0: timing_unit port map (
    ACLK                => aclk,
    ARESETN             => aresetn,
    UCLK                => uclk,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,   
    S_REGBUS_RB_WDATA   => wdata,   
    S_REGBUS_RB_WACK    => wack,
    TIMESTAMP_O         => timestamp,
    GLB_CLK_O           => glb_clk,
    G_O                 => atc_g ,
    H_O                 => atc_h,
    TS_SYNC             => ts_sy, 
    LEMO_A              => lemo_a,
    LEMO_B              => lemo_b,
    DEBUG               => debug                        
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
    wait for 10 ns;
    lemo_a   <= '1';
    wait for 10 ns;
    lemo_a   <= '0';
    wait;
  end process;  
  
  lemo_b_process : process
  begin   
    lemo_b   <= '1';
    wait for 100 ns;
    lemo_b  <= '0';
    wait for 10 ns;
    lemo_b   <= '1';
    wait;
  end process; 
  read_process : process
  begin
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 1 ns;
    wait for 20 ns;
    raddr   <= x"E440";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"E444";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"E450";
    rupdate <= '1';
    wait for 300 ns;
    raddr   <= x"E250";
    rupdate <= '1';
    wait for 300 ns;
    raddr   <= x"E244";
    rupdate <= '1';
    wait for 300 ns;
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
    waddr   <= x"E440";
    wdata   <= x"00000001";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"E444";
    wdata   <= x"00000312";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"E450";
    wdata   <= x"00000302";
    wupdate <= '1';
    wait for 10 ns;
    --waddr   <= x"FE70";
    --wdata   <= x"00000302";
    --wupdate <= '1';
    --wait for 10 ns;
    --waddr   <= x"FE74";
    --wdata   <= x"00000212";
    --wupdate <= '1';
    --wait for 10 ns;
    --waddr   <= x"FE78";
    --wdata   <= x"00000412";
    --wupdate <= '1';
    --wait for 10 ns;
    --waddr   <= x"FE7C";
    --wdata   <= x"00000112";
    --wupdate <= '1';
    --wait for 10 ns;
    --waddr   <= x"FE80";
    --wdata   <= x"00000312";
    --wupdate <= '1';
    --wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';

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
      write (l, String'("aclk: "));
      write (l, aclk);
      write (l, String'(" uclk: "));
      write (l, uclk);
      --write (l, String'(" lemo_a: "));
      --write (l, lemo_a);
      write (l, String'(" lemo_b: "));
      write (l, lemo_b);
       write (l, String'(" lemo_b_f: "));
      write (l, debug(0));
       write (l, String'(" lemo_b_s: "));
      write (l, debug(1));
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
      write (l, String'(" | ts: "));
      write (l, timestamp);
      write (l, String'(" | G_O: "));
      write (l, atc_g);

      write (l, String'("  H_O: "));
      write (l, atc_h);
      --if (sync(0) = '0') then
      --  write (l, String'(" --- "));
      --end if;
      --if (trig(0) = '1') then
      --  write (l, String'(" *** "));
      --end if;
      if (aresetn = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
