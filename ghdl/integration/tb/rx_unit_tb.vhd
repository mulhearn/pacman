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
      ACLK	        : in std_logic;
      ARESETN	        : in std_logic;
      
      S_REGBUS_RB_RADDR	     : in  std_logic_vector(15 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(31 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;
      
      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(15 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(31 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      LOOPBACK_I             : in std_logic_vector(C_NUM_UART-1 downto 0);
      PISO_I                 : in std_logic_vector(C_NUM_UART-1 downto 0);
      --
      DEBUG_O                : out  std_logic_vector(31 downto 0)
  );
  end component;
  
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
  -- read signals:
  signal raddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal rupdate : std_logic := '0';
  signal rdata   : std_logic_vector(31 downto 0);
  signal rack    : std_logic := '0';
  -- write signals:
  signal waddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal wupdate : std_logic := '0';
  signal wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal wack    : std_logic := '0';  

  signal output_registers : std_logic :='1';
  signal output_tx        : std_logic :='1';

  signal debug  : std_logic_vector(31 downto 0);
  
begin
  uut0: rx_unit port map (
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
    PISO_I              => (others => '0'),
    LOOPBACK_I          => (others => '0'),
    DEBUG_O             => debug
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
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  rapid_read_process : process
  begin
    wait for 1 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 30 ns;
    raddr   <= x"0200";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0204";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0210";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0214";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0218";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"021C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0240";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0640";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0A40";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0E40";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0204";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 10 ns;

    wait;
  end process;

  rapid_write_process : process
  begin
    wait for 1 ns;
    wait for 50 ns;
    waddr   <= x"0204";
    wdata   <= x"ABCDABCD";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';    
    wait for 50 ns;
    waddr   <= x"0220";
    wdata   <= x"00000005";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0620";
    wdata   <= x"00000005";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    wait for 10 ns;
    --wait for 100 ns;
    if (output_registers='1') then 
      write (l, String'("aclk: "));
      write (l, aclk);
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
      write (l, String'(" wk: "));
      write (l, wack);
    end if;
    if (output_tx='1') then 
      --write (l, String'(" posi: "));
      --hwrite (l, posi);
      --write (l, String'(" 0: "));
      --write (l, posi(0));
    end if;  
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
