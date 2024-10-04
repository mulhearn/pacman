library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity registers_demo_tb is
end registers_demo_tb;
     
architecture behaviour of registers_demo_tb is
  component registers_demo is
    port (
      ACLK                 : in std_logic;
      ARESETN              : in std_logic;    
      S_REGBUS_RB_RUPDATE  : in   std_logic;
      S_REGBUS_RB_RADDR    : in   std_logic_vector(15 downto 0);
      S_REGBUS_RB_RDATA    : out  std_logic_vector(31 downto 0);      
      S_REGBUS_RB_RACK     : out  std_logic;
      
      S_REGBUS_RB_WUPDATE  : in   std_logic;
      S_REGBUS_RB_WADDR    : in   std_logic_vector(15 downto 0);
      S_REGBUS_RB_WDATA    : in   std_logic_vector(31 downto 0);
      S_REGBUS_RB_WACK     : out  std_logic
    );  
  end component;

  signal count    : integer := 0;  
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
  
  -- register BUS signals:
  signal raddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal rupdate : std_logic := '0';
  signal rdata   : std_logic_vector(31 downto 0);
  signal rack    : std_logic := '0';
  signal waddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal wupdate : std_logic := '0';
  signal wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal wack    : std_logic := '0';  
begin  
  uut: registers_demo port map (
    ACLK                => aclk,
    ARESETN             => aresetn,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,    
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack
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

  read_process : process
  begin
    wait for 1 ns;
    wait for 20 ns;
    rupdate <= '1';
    raddr <= x"FF00";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"FE04";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"FF08";
    wait for 10 ns;    
    rupdate <= '1';
    raddr <= x"FF0C";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"FF10";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"FF00";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"FE04";
    wait for 10 ns;    
    rupdate <= '0';
    raddr <= x"0000";
    wait for 10 ns;    
    rupdate <= '1';
    raddr <= x"0000";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"0004";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"0008";
    wait for 10 ns;    
    rupdate <= '1';
    raddr <= x"000C";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"0010";
    wait for 10 ns;
    rupdate <= '0';
    raddr <= x"0000";
    wait for 10 ns;    
    rupdate <= '1';
    raddr <= x"1000";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"1004";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"1008";
    wait for 10 ns;    
    rupdate <= '1';
    raddr <= x"100C";
    wait for 10 ns;
    rupdate <= '1';
    raddr <= x"1010";
    wait for 10 ns;
    rupdate <= '0';
    raddr <= x"0000";
    wait for 10 ns;    
    wait;
  end process;


  write_process : process
  begin
    wait for 1 ns;
    wait for 20 ns;
    wupdate <= '1';
    waddr <= x"FF00";
    wdata <= x"12345678";
    wait for 10 ns;
    wupdate <= '1';
    waddr <= x"FE04";
    wdata <= x"90ABCDEF";
    wait for 10 ns;
    wupdate <= '1';
    waddr <= x"0000";
    wdata <= x"AAAABBBB";
    wait for 10 ns;
    wupdate <= '1';
    waddr <= x"0004";
    wdata <= x"CCCCDDDD";
    wait for 10 ns;
    wupdate <= '1';
    waddr <= x"1000";
    wdata <= x"EEEEFFFF";
    wait for 10 ns;
    wupdate <= '1';
    waddr <= x"1004";
    wdata <= x"77777777";
    wait for 10 ns;
    wupdate <= '0';
    waddr <= x"0000";
    wdata <= x"00000000";
    wait;
  end process;
  
  output_process : process
    variable l : line;
  begin
    if (count < 24) then
      wait for 10 ns;   
    else
      wait;
    end if;

    write (l, String'("c: "));
    write (l, count, left, 4);
    --write (l, String'("aclk: "));
    --write (l, aclk);
    write (l, String'(" || ru: "));
    write (l, rupdate);
    write (l, String'(" raddr: 0x"));
    hwrite (l, raddr);
    write (l, String'(" rdata: 0x"));
    hwrite (l, rdata);    
    write (l, String'(" ra: "));
    write (l, rack);

    write (l, String'(" || wu: "));
    write (l, wupdate);
    write (l, String'(" waddr: 0x"));
    hwrite (l, waddr);
    write (l, String'(" wdata: 0x"));
    hwrite (l, wdata);    
    write (l, String'(" wa: "));
    write (l, wack);

    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;

  summary_process : process
    variable l : line;
    variable reads : integer := 0;
    type result_t is array (0 to 16) of std_logic_vector(31 downto 0);
    variable results : result_t;
  begin
    if (reads < 17) then      
      wait until ((rising_edge(aclk)) and (rack='1'));
      --write (l, String'("*** READ DETECTED *** "));
      --writeline(output, l);
      results(reads) := rdata;
      reads := reads + 1;
    else
      wait until (count > 25);
      write (l, String'("*** Simulation Summary ***"));
      writeline(output, l);
      for i in 0 to reads-1 loop
        write (l, i, right, 3);
        write (l, String'(": "));
        hwrite(l, results(i));
        if ((i mod 8) = 7) then
          writeline(output, l);
        end if;
      end loop;
      writeline(output, l);
      assert(results(0) = x"00000000") report("unexpected read result") severity failure;
      assert(results(1) = x"00000000") report("unexpected read result") severity failure;

      assert(results(0)  = x"00000000") report("unexpected read result") severity failure;
      assert(results(1)  = x"00000000") report("unexpected read result") severity failure;
      assert(results(2)  = x"1000F001") report("unexpected read result") severity failure;
      assert(results(3)  = x"11111111") report("unexpected read result") severity failure;
      assert(results(4)  = x"AAAAAAAA") report("unexpected read result") severity failure;
      assert(results(5)  = x"12345678") report("unexpected read result") severity failure;
      assert(results(6)  = x"90ABCDEF") report("unexpected read result") severity failure;
      assert(results(7)  = x"AAAABBBB") report("unexpected read result") severity failure;
      assert(results(8)  = x"CCCCDDDD") report("unexpected read result") severity failure;
      assert(results(9)  = x"1000F001") report("unexpected read result") severity failure;
      assert(results(10) = x"22222222") report("unexpected read result") severity failure;
      assert(results(11) = x"BBBBBBBB") report("unexpected read result") severity failure;
      assert(results(12) = x"EEEEFFFF") report("unexpected read result") severity failure;
      assert(results(13) = x"77777777") report("unexpected read result") severity failure;
      assert(results(14) = x"1000F001") report("unexpected read result") severity failure;
      assert(results(15) = x"33333333") report("unexpected read result") severity failure;
      assert(results(16) = x"CCCCCCCC") report("unexpected read result") severity failure;

      write (l, String'("*** Test results were all SUCCESSFUL!!! ***"));
      writeline(output, l);      
      wait;
    end if;
  end process;
end behaviour;
        
