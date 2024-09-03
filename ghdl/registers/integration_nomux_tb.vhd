library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 

--  Defines a testbench (without any ports)
entity integration_nomux_tb is
end integration_nomux_tb;
     
architecture behaviour of integration_nomux_tb is
  component axil_to_regbus is
    port (
      S_AXI_ACLK          : in std_logic;
      S_AXI_ARESETN       : in std_logic;
      S_AXI_ARADDR        : in std_logic_vector(15 downto 0);
      S_AXI_ARVALID       : in std_logic;
      S_AXI_ARREADY       : out std_logic;    
      S_AXI_RDATA         : out std_logic_vector(31 downto 0);
      S_AXI_RRESP         : out std_logic_vector(1 downto 0);
      S_AXI_RVALID        : out std_logic;
      S_AXI_RREADY        : in std_logic;
      S_AXI_AWADDR        : in std_logic_vector(15 downto 0);      
      S_AXI_AWVALID       : in std_logic;                                    
      S_AXI_AWREADY       : out std_logic;
      S_AXI_WDATA         : in std_logic_vector(31 downto 0);      
      S_AXI_WVALID        : in std_logic;                                    
      S_AXI_WREADY        : out std_logic;                                           
      S_AXI_BRESP         : out std_logic_vector(1 downto 0);
      S_AXI_BVALID        : out std_logic;
      S_AXI_BREADY        : in std_logic;
      P_REGBUS_RB_RUPDATE      : out std_logic;
      P_REGBUS_RB_RADDR	       : out std_logic_vector(15 downto 0);
      P_REGBUS_RB_RDATA	       : in  std_logic_vector(31 downto 0);      
      P_REGBUS_RB_WUPDATE      : out std_logic;
      P_REGBUS_RB_WADDR	       : out std_logic_vector(15 downto 0);
      P_REGBUS_RB_WDATA	       : out  std_logic_vector(31 downto 0)
      );
  end component;

  component registers_scratch is
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
      --
      DEBUG     	: out  std_logic_vector(31 downto 0)
      );
  end component;
  
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
  -- AXI read signals:
  signal xraddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal xarvalid  : std_logic := '0';
  signal xarready  : std_logic;
  signal xrdata    : std_logic_vector(31 downto 0) := (others => '0');
  signal xrvalid   : std_logic := '0';  
  signal xrready   : std_logic;  
  -- AXI write signals:
  signal xwaddr   : std_logic_vector(15 downto 0)  := (others => '0');
  signal xawvalid  : std_logic := '0';
  signal xawready  : std_logic;
  signal xwdata    : std_logic_vector(31 downto 0) := (others => '0');
  signal xwvalid   : std_logic:= '0';
  signal xwready   : std_logic;  
  signal xbvalid   : std_logic;  
  signal xbready   : std_logic:='0';
  
  -- register BUS read signals:
  signal raddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal rupdate : std_logic := '0';
  signal rdata   : std_logic_vector(31 downto 0);
  signal rack    : std_logic := '0';
  -- register BUS write signals
  signal waddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal wupdate : std_logic := '0';
  signal wdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal wack    : std_logic := '0';  

  signal debug   : std_logic_vector(31 downto 0) := (others => '0');
  
begin
  uuta: axil_to_regbus port map (
      S_AXI_ACLK          => aclk,
      S_AXI_ARESETN       => aresetn,
      S_AXI_ARADDR        => xraddr,
      S_AXI_ARVALID       => xarvalid,
      S_AXI_ARREADY       => xarready,    
      S_AXI_RDATA         => xrdata,
      S_AXI_RVALID        => xrvalid,
      S_AXI_RREADY        => xrready,
      S_AXI_AWADDR        => xwaddr,
      S_AXI_AWVALID       => xawvalid,
      S_AXI_AWREADY       => xawready,    
      S_AXI_WDATA         => xwdata,
      S_AXI_WVALID        => xwvalid,
      S_AXI_WREADY        => xwready,
      S_AXI_BVALID        => xbvalid,
      S_AXI_BREADY        => xbready,
      
      P_REGBUS_RB_RUPDATE      => rupdate,
      P_REGBUS_RB_RADDR        => raddr,
      P_REGBUS_RB_RDATA        => rdata,
      P_REGBUS_RB_WUPDATE      => wupdate,
      P_REGBUS_RB_WADDR        => waddr,
      P_REGBUS_RB_WDATA        => wdata
      );

  uutb: registers_scratch port map (
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
      DEBUG          => debug      
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
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  rapid_read_process : process
  begin
    xraddr <= x"F100";
    xarvalid  <= '0';
    xrready <= '0';
    wait for 40 ns;
    xraddr <= x"F100";
    xarvalid  <= '1';
    xrready <= '1';
    wait for 10 ns;
    xraddr <= x"F104";
    xrready <= '1';
    wait for 10 ns;
    wait for 10 ns;
    xraddr <= x"F108";
    xrready <= '1';
    wait for 10 ns;
    wait for 10 ns;
    xraddr <= x"F10C";
    xrready <= '1';
    wait for 10 ns;
    wait for 10 ns;
    xraddr <= x"0000";
    xarvalid  <= '0';
    xrready <= '0';
    wait for 30 ns;
    xraddr <= x"F110";
    xarvalid  <= '1';
    xrready <= '1';
    wait for 10 ns;
    wait for 10 ns;
    xraddr <= x"F100";
    xrready <= '1';
    wait for 10 ns;
    wait for 10 ns;
    xraddr <= x"F104";
    xrready <= '1';
    wait for 10 ns;
    wait for 10 ns;
    xraddr <= x"F108";
    xrready <= '1';
    wait for 10 ns;
    wait for 10 ns;
    xraddr <= x"F10C";
    xrready <= '1';
    wait for 10 ns;
    wait for 10 ns;
    xraddr <= x"F110";
    xrready <= '1';
    wait for 10 ns;
    wait for 10 ns;
    xraddr <= x"F100";
    xarvalid  <= '0';
    xrready <= '0';
    wait for 40 ns;
    xrready <= '1';
    wait for 10 ns;
    xrready <= '0';
    wait;
  end process;

    three_tick_write_process : process
  begin
    xwaddr <= x"0000";
    xawvalid  <= '0';
    xwdata  <= x"00000000";
    xwvalid  <= '0';
    wait for 20 ns;
    xwaddr <= x"F100";
    xawvalid  <= '1';
    xwdata  <= x"12345678";
    xwvalid  <= '1';
    xbready <= '1';
    wait for 20 ns;
    xwaddr <= x"F104";
    xawvalid  <= '1';
    xwdata  <= x"ABCDEF09";
    xwvalid  <= '1';
    xbready <= '1';
    wait for 30 ns;
    xwaddr <= x"F100";
    xawvalid  <= '1';
    xwdata  <= x"FEEDDADA";
    xwvalid  <= '1';
    xbready <= '1';
    wait for 30 ns;
    xwaddr <= x"F104";
    xawvalid  <= '1';
    xwdata  <= x"CAFEDADA";
    xwvalid  <= '1';
    xbready <= '1';
    wait for 30 ns;
    xawvalid  <= '0';
    xwdata  <= x"00000000";
    xwvalid  <= '0';
    xbready <= '0';    
    wait for 10 ns;               
    xbready <= '0';
    wait;
  end process;

  --challenging_write_process : process
  --begin    
    --xwaddr <= x"0000";
    --xawvalid  <= '0';
    --xwdata  <= x"00000000";
    --xwvalid  <= '0';
    --xbready <= '0';
    --wait for 20 ns;
    --xwaddr <= x"F100";
    --xawvalid  <= '1';
    --xwdata    <= x"12345678";
    --xwvalid   <= '1';
    --xbready   <= '1';
    --wait for 20 ns;
    --xwaddr <= x"0000";
    --xawvalid  <= '0';
    --xwdata    <= x"FFFFFFFF";
    --xwvalid   <= '0';
    --wait;
  --end process;



  
  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    wait for 10 ns;
    write (l, aclk);
    write (l, String'(" || ar: 0x"));
    hwrite (l, xraddr);
    write (l, String'(" v:"));
    write (l, xarvalid);
    write (l, String'(" r: "));
    write (l, xarready);    
    write (l, String'(" | r: 0x"));
    hwrite (l, xrdata);
    write (l, String'(" v: "));
    write (l, xrvalid);
    write (l, String'(" r: "));
    write (l, xrready);
    write (l, String'(" | aw: 0x"));
    hwrite (l, xwaddr);
    write (l, String'(" v: "));
    write (l, xawvalid);
    write (l, String'(" r: "));
    write (l, xawready);    
    write (l, String'(" | w: 0x"));
    hwrite (l,xwdata);
    write (l, String'(" v: "));
    write (l, xwvalid);
    write (l, String'(" r: "));
    write (l, xwready);
    write (l, String'(" | bv: "));
    write (l, xbvalid);
    write (l, String'(" br: "));
    write (l, xbready);
    write (l, String'(" | ru: "));
    write (l, rupdate);
    write (l, String'(" rk:"));
    write (l, rack);
    write (l, String'(" wu: "));
    write (l, wupdate);
    write (l, String'(" wk:"));
    write (l, wack);
    write (l, String'(" | d: 0x"));
    hwrite (l,debug);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
