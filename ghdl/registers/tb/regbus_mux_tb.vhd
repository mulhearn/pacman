library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 

--  Defines a testbench (without any ports)
entity regbus_mux_tb is
end regbus_mux_tb;
     
architecture behaviour of regbus_mux_tb is
  component regbus_mux is
    port (
      ACLK	             : in std_logic;
      ARESETN	             : in std_logic;
      -- Secondary REGBUS:
      S_REGBUS_RB_RUPDATE  : in   std_logic;
      S_REGBUS_RB_RADDR    : in   std_logic_vector(15 downto 0);
      S_REGBUS_RB_RDATA    : out  std_logic_vector(31 downto 0);      
      S_REGBUS_RB_RACK     : out  std_logic;
      
      S_REGBUS_RB_WUPDATE  : in   std_logic;
      S_REGBUS_RB_WADDR    : in   std_logic_vector(15 downto 0);
      S_REGBUS_RB_WDATA    : in   std_logic_vector(31 downto 0);
      S_REGBUS_RB_WACK     : out  std_logic;

      -- Primary A REGBUS
      PA_REGBUS_RB_RUPDATE : out  std_logic;
      PA_REGBUS_RB_RADDR   : out  std_logic_vector(15 downto 0);
      PA_REGBUS_RB_RDATA   : in   std_logic_vector(31 downto 0);      
      PA_REGBUS_RB_RACK    : in   std_logic;
      PA_REGBUS_RB_WUPDATE : out  std_logic;
      PA_REGBUS_RB_WADDR   : out  std_logic_vector(15 downto 0);
      PA_REGBUS_RB_WDATA   : out  std_logic_vector(31 downto 0);
      PA_REGBUS_RB_WACK    : in   std_logic;
      
      -- Primary B REGBUS
      PB_REGBUS_RB_RUPDATE : out  std_logic;
      PB_REGBUS_RB_RADDR   : out  std_logic_vector(15 downto 0);
      PB_REGBUS_RB_RDATA   : in   std_logic_vector(31 downto 0);      
      PB_REGBUS_RB_RACK    : in   std_logic;    
      PB_REGBUS_RB_WUPDATE : out  std_logic;
      PB_REGBUS_RB_WADDR   : out  std_logic_vector(15 downto 0);
      PB_REGBUS_RB_WDATA   : out  std_logic_vector(31 downto 0);
      PB_REGBUS_RB_WACK    : in   std_logic;

      -- Primary C REGBUS
      PC_REGBUS_RB_RUPDATE : out  std_logic;
      PC_REGBUS_RB_RADDR   : out  std_logic_vector(15 downto 0);
      PC_REGBUS_RB_RDATA   : in   std_logic_vector(31 downto 0);      
      PC_REGBUS_RB_RACK    : in   std_logic;
    
      PC_REGBUS_RB_WUPDATE : out  std_logic;
      PC_REGBUS_RB_WADDR   : out  std_logic_vector(15 downto 0);
      PC_REGBUS_RB_WDATA   : out  std_logic_vector(31 downto 0);
      PC_REGBUS_RB_WACK    : in   std_logic;
      --
      DEBUG               : out  std_logic_vector(31 downto 0)
    );
  end component;

  signal show_write : std_logic := '0';
  signal show_read  : std_logic := '1';

  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
  -- secondary interface:
  signal s_raddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal s_rupdate : std_logic := '0';
  signal s_rdata   : std_logic_vector(31 downto 0);
  signal s_rack    : std_logic := '0';
  signal s_waddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal s_wupdate : std_logic := '0';
  signal s_wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal s_wack    : std_logic := '0';  
  -- primary interfaces:
  signal a_raddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal a_rupdate : std_logic := '0';
  signal a_rdata   : std_logic_vector(31 downto 0);
  signal a_rack    : std_logic := '0';
  signal a_waddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal a_wupdate : std_logic := '0';
  signal a_wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal a_wack    : std_logic := '0';  

  signal b_raddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal b_rupdate : std_logic := '0';
  signal b_rdata   : std_logic_vector(31 downto 0);
  signal b_rack    : std_logic := '0';
  signal b_waddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal b_wupdate : std_logic := '0';
  signal b_wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal b_wack    : std_logic := '0';  

  signal c_raddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal c_rupdate : std_logic := '0';
  signal c_rdata   : std_logic_vector(31 downto 0);
  signal c_rack    : std_logic := '0';
  signal c_waddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal c_wupdate : std_logic := '0';
  signal c_wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal c_wack    : std_logic := '0';  

begin
  uut: regbus_mux port map (
      ACLK           => aclk,
      ARESETN        => aresetn,      
      S_REGBUS_RB_RUPDATE => s_rupdate,
      S_REGBUS_RB_RADDR   => s_raddr,
      S_REGBUS_RB_RDATA   => s_rdata,
      S_REGBUS_RB_RACK    => s_rack,
      S_REGBUS_RB_WUPDATE => s_wupdate,
      S_REGBUS_RB_WADDR   => s_waddr,
      S_REGBUS_RB_WDATA   => s_wdata,
      S_REGBUS_RB_WACK    => s_wack,

      PA_REGBUS_RB_RUPDATE => a_rupdate,
      PA_REGBUS_RB_RADDR   => a_raddr,
      PA_REGBUS_RB_RDATA   => a_rdata,
      PA_REGBUS_RB_RACK    => a_rack,
      PA_REGBUS_RB_WUPDATE => a_wupdate,
      PA_REGBUS_RB_WADDR   => a_waddr,
      PA_REGBUS_RB_WDATA   => a_wdata,
      PA_REGBUS_RB_WACK    => a_wack,

      PB_REGBUS_RB_RUPDATE => b_rupdate,
      PB_REGBUS_RB_RADDR   => b_raddr,
      PB_REGBUS_RB_RDATA   => b_rdata,
      PB_REGBUS_RB_RACK    => b_rack,
      PB_REGBUS_RB_WUPDATE => b_wupdate,
      PB_REGBUS_RB_WADDR   => b_waddr,
      PB_REGBUS_RB_WDATA   => b_wdata,
      PB_REGBUS_RB_WACK    => b_wack,

      PC_REGBUS_RB_RUPDATE => c_rupdate,
      PC_REGBUS_RB_RADDR   => c_raddr,
      PC_REGBUS_RB_RDATA   => c_rdata,
      PC_REGBUS_RB_RACK    => c_rack,
      PC_REGBUS_RB_WUPDATE => c_wupdate,
      PC_REGBUS_RB_WADDR   => c_waddr,
      PC_REGBUS_RB_WDATA   => c_wdata,
      PC_REGBUS_RB_WACK    => c_wack
      );
  
  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 12 ns;
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

  secondary_output_process : process
  begin
    s_waddr   <= x"0000";
    s_wdata   <= x"00000000";
    s_wupdate <= '0';
    s_raddr   <= x"0000";
    s_rupdate <= '0';
    wait for 20 ns;
    s_waddr   <= x"F100";
    s_wdata   <= x"AAAAAAAA";
    s_wupdate <= '1';
    s_raddr   <= x"FF00";
    s_rupdate <= '1';
    wait for 10 ns;
    s_waddr   <= x"F104";
    s_wdata   <= x"BBBBBBBB";
    s_wupdate <= '1';
    s_raddr   <= x"FF04";
    s_rupdate <= '1';    
    wait for 10 ns;
    s_waddr   <= x"F108";
    s_wdata   <= x"CCCCCCCC";
    s_wupdate <= '1';
    s_raddr   <= x"FF08";
    s_rupdate <= '1';    
    wait for 10 ns;
    s_waddr   <= x"F10C";
    s_wdata   <= x"11111111";
    s_wupdate <= '1';
    s_raddr   <= x"FF0C";
    s_rupdate <= '1';
    wait for 10 ns;
    s_waddr   <= x"F110";
    s_wdata   <= x"22222222";
    s_wupdate <= '1';
    s_raddr   <= x"FF10";
    s_rupdate <= '1';
    wait for 10 ns;    
    s_waddr   <= x"0000";
    s_wdata   <= x"00000000";
    s_wupdate <= '0';
    s_raddr   <= x"0000";
    s_rupdate <= '0';
    wait;
  end process;

  primary_output_process : process
  begin
    a_rdata   <= x"00000000";
    a_rack    <= '0';
    a_wack    <= '0';
    b_rdata   <= x"00000000";
    b_rack    <= '0';
    b_wack    <= '0';
    c_rdata   <= x"00000000";
    c_rack    <= '0';
    c_wack    <= '0';    
    wait for 20 ns;
    a_rdata   <= x"00000000";
    a_rack    <= '0';
    a_wack    <= '0';
    b_rdata   <= x"FEEDDADA";
    b_rack    <= '1';
    b_wack    <= '0';
    c_rdata   <= x"00000000";
    c_rack    <= '0';
    c_wack    <= '1';    
    wait for 10 ns;
    a_rdata   <= x"CAFEF00D";
    a_rack    <= '1';
    a_wack    <= '0';
    b_rdata   <= x"00000000";
    b_rack    <= '0';
    b_wack    <= '1';
    c_rdata   <= x"00000000";
    c_rack    <= '0';
    c_wack    <= '0';    
    wait for 10 ns;
    a_rdata   <= x"11111111";
    a_rack    <= '1';
    a_wack    <= '1';
    b_rdata   <= x"00000000";
    b_rack    <= '0';
    b_wack    <= '0';
    c_rdata   <= x"22222222";
    c_rack    <= '0';
    c_wack    <= '0';    
    -- priority should go to :
    wait for 10 ns;
    a_rdata   <= x"11111111";
    a_rack    <= '0';
    a_wack    <= '1';
    b_rdata   <= x"00000000";
    b_rack    <= '0';
    b_wack    <= '0';
    c_rdata   <= x"22222222";
    c_rack    <= '1';
    c_wack    <= '0';    
    wait for 10 ns;
    a_rdata   <= x"11111111";
    a_rack    <= '1';
    a_wack    <= '0';
    b_rdata   <= x"00000000";
    b_rack    <= '0';
    b_wack    <= '0';
    c_rdata   <= x"22222222";
    c_rack    <= '1';
    c_wack    <= '1';    
    wait for 10 ns;
    a_rdata   <= x"00000000";
    a_rack    <= '0';
    a_wack    <= '0';
    b_rdata   <= x"00000000";
    b_rack    <= '0';
    b_wack    <= '0';
    c_rdata   <= x"00000000";
    c_rack    <= '0';
    c_wack    <= '0';    
    wait;
  end process;
  
  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    if (count < 10) then
      wait for 10 ns;
    else
      wait;
    end if;
    
    write (l, String'("c: "));
    write (l, count, left, 4);  
    write (l, String'("aclk: "));
    write (l, aclk);
    if (show_read='1') then
       write (l, String'(" || ra: 0x"));
       hwrite(l, s_raddr);
       write (l, String'(" ru:"));
       write (l, s_rupdate);
       write (l, String'(" rd: 0x"));
       hwrite(l, s_rdata);
       write (l, String'(" rk:"));
       write (l, s_rack);
       write (l, String'(" ark:"));
       write (l, a_rack);
       write (l, String'(" brk:"));
       write (l, b_rack);
       write (l, String'(" crk:"));
       write (l, c_rack);
       write (l, String'(" ra: 0x"));
       hwrite(l, a_rdata);
       write (l, String'(" rb: 0x"));
       hwrite(l, b_rdata);
       write (l, String'(" rc: 0x"));
       hwrite(l, c_rdata);
       write (l, String'(" || ra: 0x"));
       hwrite(l, a_raddr);
       write (l, String'(" rb: 0x"));
       hwrite(l, b_raddr);
       write (l, String'(" rc: 0x"));
       hwrite(l, c_raddr);       
    end if;
    if (show_write='1') then
       write (l, String'(" || wa: 0x"));
       hwrite (l,s_waddr);
       write (l, String'(" wu:"));
       write (l, s_wupdate);
       write (l, String'(" wd: 0x"));
       hwrite (l,s_wdata);
       write (l, String'(" wk:"));
       write (l, s_wack);
       write (l, String'(" awk:"));
       write (l, a_wack);
       write (l, String'(" bwk:"));
       write (l, b_wack);
       write (l, String'(" cwk:"));
       write (l, c_wack);
       write (l, String'(" wa: 0x"));
       hwrite(l, a_wdata);
       write (l, String'(" wb: 0x"));
       hwrite(l, b_wdata);
       write (l, String'(" wc: 0x"));
       hwrite(l, c_wdata);
       write (l, String'(" || wa: 0x"));
       hwrite(l, a_waddr);
       write (l, String'(" wb: 0x"));
       hwrite(l, b_waddr);
       write (l, String'(" wc: 0x"));
       hwrite(l, c_waddr);       
       
    end if;                   
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
