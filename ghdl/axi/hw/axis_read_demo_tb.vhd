library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity axis_read_demo_tb is
end axis_read_demo_tb;
     
architecture behaviour of axis_read_demo_tb is
  component axis_read_demo is
    port (
      S_AXIS_ACLK        : in std_logic;
      S_AXIS_ARESETN     : in std_logic;
      S_AXIS_TDATA       : in std_logic_vector(511 downto 0);      
      S_AXIS_TVALID      : in std_logic;
      S_AXIS_TREADY      : out std_logic;
      S_AXIS_TKEEP       : in std_logic_vector(63 downto 0);      
      S_AXIS_TLAST       : in std_logic;

      S_REGBUS_RB_RUPDATE : in  std_logic;
      S_REGBUS_RB_RADDR   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      S_REGBUS_RB_RACK    : out  std_logic;
    
      S_REGBUS_RB_WUPDATE : in  std_logic;
      S_REGBUS_RB_WADDR   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK    : out  std_logic
    );
  end component;
  signal count    : integer := 0;  
  signal aclk     : std_logic;
  signal aresetn  : std_logic;

  signal tdata       : std_logic_vector(511 downto 0) := (others=> '0');
  signal tvalid      : std_logic := '0';
  signal tready      : std_logic;
  signal tlast       : std_logic := '0';

  signal rupdate  : std_logic := '0';
  signal raddr    : std_logic_vector(15 downto 0) := (others => '0');
  signal rdata    : std_logic_vector(31 downto 0);
  signal rack     : std_logic;

  signal wupdate  : std_logic := '0';
  signal waddr    : std_logic_vector(15 downto 0) := (others => '0');
  signal wdata    : std_logic_vector(31 downto 0) := (others => '0');
  signal wack     : std_logic;

begin
  uut: axis_read_demo port map (
    S_AXIS_ACLK         => aclk,
    S_AXIS_ARESETN      => aresetn,
    S_AXIS_TDATA        => tdata,
    S_AXIS_TVALID       => tvalid,
    S_AXIS_TREADY       => tready,
    S_AXIS_TKEEP        => (others => '1'),
    S_AXIS_TLAST        => tlast,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,    
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack
  );
    
  aclk_process : process
  begin
    count <= count + 1;
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 10 ns;
    wait until (rising_edge(aclk));
    aresetn <= '1';    
    wait;
  end process;

  read_process : process
  begin
    wait for 1 ns;
    wait for 20 ns;
    raddr   <= x"0200";
    rupdate <= '1';
    wait for 50 ns;
    raddr   <= x"0000";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0040";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0080";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"00C0";
    rupdate <= '1';    
    wait for 10 ns;
    raddr   <= x"0100";
    rupdate <= '1';    
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';    
    wait;
  end process;

  
  write_process : process
  begin
    wait for 1 ns;
    wait for 20 ns;
    tdata(15 downto 0) <= x"AAAA";
    tvalid <= '1';
    tlast  <= '0';
    wait for 10 ns;
    tdata(15 downto 0) <= x"BBBB";
    tvalid <= '1';
    tlast  <= '0';
    wait for 10 ns;
    tdata(15 downto 0) <= x"CCCC";
    tvalid <= '1';
    tlast  <= '0';
    wait for 10 ns;
    tdata(15 downto 0) <= x"DDDD";
    tvalid <= '1';
    tlast  <= '0';
    wait for 10 ns;
    tdata(15 downto 0) <= x"EEEE";
    tvalid <= '1';
    tlast  <= '1';
    wait for 10 ns;
    tdata(15 downto 0) <= x"0000";
    tvalid <= '0';
    tlast  <= '0';    
    wait;
  end process;
  
  output_process : process
    variable l : line;
  begin
    if (count < 18) then
      wait for 10 ns;   
    else
      wait;
    end if;

    write (l, String'("c: "));
    write (l, count, left, 4);
    write (l, String'("aclk: "));
    write (l, aclk);
    write (l, String'(" || tdata: 0x"));
    hwrite (l, tdata(7 downto 0));
    write (l, String'("..."));
    hwrite (l, tdata(511 downto 504));
    write (l, String'(" v:"));
    write (l, tvalid);
    write (l, String'(" r: "));
    write (l, tready);
    write (l, String'(" l: "));
    write (l, tlast);
    write (l, String'(" || ru: "));
    write (l, rupdate);
    write (l, String'(" raddr: 0x"));
    hwrite (l, raddr);
    write (l, String'(" rdata: 0x"));
    hwrite (l, rdata);    
    write (l, String'(" ra: "));
    write (l, rack);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
