library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;
use work.register_map.all;

--  Defines a testbench (without any ports)
entity timing_registers_tb is
end timing_registers_tb;

architecture behaviour of timing_registers_tb is
  component timing_registers is
    port (
     ACLK	                 : in std_logic;
    ARESETN	               : in std_logic;

    S_REGBUS_RB_RUPDATE    : in  std_logic;
    S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK       : out std_logic;
    
    S_REGBUS_RB_WUPDATE    : in  std_logic;
    S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK       : out std_logic;

    ATC_POKE_C             : out std_logic;
    ATC_POKE_D             : out std_logic;
    ATC_CONFIG_G           : out ATC_array := (others => (others => '0'));
    ATC_CONFIG_H           : out ATC_array := (others => (others => '0'));
    ATC_CONFIG_TS          : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    ATC_POLARITY           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    STATUS_I               : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    TIMESTAMP_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);   
    --count of input in fast domain
    LEMO_A_COUNT           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    LEMO_B_COUNT           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    --count of input in slow domain
    LEMO_A_COUNT_S         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    LEMO_B_COUNT_S         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    POKE_C_COUNT_S         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    POKE_D_COUNT_S         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    --count of output
    ATC_G_COUNT           :  in  ATC_array;
    ATC_H_COUNT           :  in  ATC_array;
    ATC_TS_COUNT          :  in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
 
    );
  end component;

  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
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

  -- poke config and output
  signal atc_g_cfg      : ATC_array  ;
  signal atc_h_cfg      : ATC_array  ;
  signal atc_ts_cfg     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal polarity_cfg   : std_logic_vector(31 downto 0) ;
  signal poke_c         : std_logic;
  signal poke_d         : std_logic;

  signal atc_g_c     : ATC_array;
  signal atc_h_c     : ATC_array;
  signal atc_ts_c    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  --lemo_count
  signal lemo_a_c       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal lemo_b_c       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

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
    ATC_POKE_C          => poke_c,
    ATC_POKE_D          => poke_d,
    ATC_CONFIG_G        => atc_g_cfg,
    ATC_CONFIG_H        => atc_h_cfg,
    ATC_CONFIG_TS       => atc_ts_cfg,
    ATC_POLARITY        => polarity_cfg,
    STATUS_I            => x"ABCDEF12",
    TIMESTAMP_I         => x"0000A435",
    LEMO_A_COUNT        => lemo_a_c,
    LEMO_B_COUNT        => lemo_b_c,
    LEMO_A_COUNT_S      =>  x"0000B435",
    LEMO_B_COUNT_S       => x"0000A335",  
    POKE_C_COUNT_S        => x"0000A235", 
    POKE_D_COUNT_S       => x"0000A135",  

    --count of output
    ATC_G_COUNT          => atc_g_c,  
    ATC_H_COUNT          => atc_h_c, 
    ATC_TS_COUNT         => atc_ts_c  
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
    wait for 80 ns;   
    raddr   <= x"FE20";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FE24";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FE64";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FE60";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FE70";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FE74";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"FEA4";
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
    waddr   <= x"FE70";
    wdata   <= x"00000101";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"FE74";
    wdata   <= x"0000031F";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"FEA4";
    wdata   <= x"00000111";
    wupdate <= '1';    
    wait for 10 ns;
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
      write (l, String'(" | poke_c: "));
      write (l, poke_c);
      write (l, String'(" poke_d: "));
      write (l, poke_d);
      if (aresetn = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
