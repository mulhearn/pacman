library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity regbus_demo_tb is
end regbus_demo_tb;
     
architecture behaviour of regbus_demo_tb is
  component regbus_demo is
    port (
      S_AXI_ACLK         : in std_logic;
      S_AXI_ARESETN      : in std_logic;
      S_AXI_ARADDR       : in std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_AXI_ARPROT       : in std_logic_vector(2 downto 0) := (others => '0');                 
      S_AXI_ARVALID      : in std_logic;
      S_AXI_ARREADY      : out std_logic;    
      S_AXI_RDATA        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP        : out std_logic_vector(1 downto 0);
      S_AXI_RVALID       : out std_logic;
      S_AXI_RREADY       : in std_logic;
      S_AXI_AWADDR       : in std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);      
      S_AXI_AWPROT       : in std_logic_vector(2 downto 0) := (others => '0');                 
      S_AXI_AWVALID      : in std_logic;                                    
      S_AXI_AWREADY      : out std_logic;
      S_AXI_WDATA        : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      S_AXI_WSTRB        : in std_logic_vector((C_RB_DATA_WIDTH/8)-1 downto 0) := (others => '0');                 
      S_AXI_WVALID       : in std_logic;                                    
      S_AXI_WREADY       : out std_logic;                                           
      S_AXI_BRESP        : out std_logic_vector(1 downto 0);
      S_AXI_BVALID       : out std_logic;
      S_AXI_BREADY       : in std_logic
    );
  end component;
  signal count    : integer := 0;  
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
  -- read signals:
  signal araddr   : std_logic_vector(15 downto 0) := (others => '0');
  signal arvalid  : std_logic := '0';
  signal arready  : std_logic;
  signal rdata    : std_logic_vector(31 downto 0);
  signal rvalid   : std_logic := '0';  
  signal rready   : std_logic;  
  -- write signals:
  signal awaddr   : std_logic_vector(15 downto 0)  := (others => '0');
  signal awvalid  : std_logic := '0';
  signal awready  : std_logic;
  signal wdata    : std_logic_vector(31 downto 0) := (others => '0');
  signal wvalid   : std_logic:= '0';
  signal wready   : std_logic;  
  signal bvalid   : std_logic;  
  signal bready   : std_logic:='0';
begin
  uut: regbus_demo port map (
    S_AXI_ACLK     => aclk,
    S_AXI_ARESETN  => aresetn,
    S_AXI_ARADDR   => araddr,
    S_AXI_ARVALID  => arvalid,
    S_AXI_ARREADY  => arready,    
    S_AXI_RDATA    => rdata,
    S_AXI_RVALID   => rvalid,
    S_AXI_RREADY   => rready,
    S_AXI_AWADDR   => awaddr,
    S_AXI_AWVALID  => awvalid,
    S_AXI_AWREADY  => awready,    
    S_AXI_WDATA    => wdata,
    S_AXI_WVALID   => wvalid,
    S_AXI_WREADY   => wready,
    S_AXI_BVALID   => bvalid,
    S_AXI_BREADY   => bready
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

  rapid_read_process : process
  begin
    araddr <= x"0000";
    arvalid  <= '0';
    rready <= '0';
    wait for 20 ns;
    araddr <= x"0000";
    arvalid  <= '1';
    rready <= '1';
    wait for 10 ns;
    araddr <= x"0004";
    arvalid  <= '1';
    rready <= '1';
    wait for 20 ns;
    araddr <= x"0008";
    arvalid  <= '1';
    rready <= '1';
    wait for 20 ns;
    araddr <= x"000C";
    arvalid  <= '1';
    rready <= '1';
    wait for 20 ns;
    araddr <= x"0000";
    arvalid  <= '1';
    rready <= '1';
    wait for 20 ns;
    araddr <= x"0004";
    arvalid  <= '1';
    rready <= '1';
    wait for 20 ns;
    araddr <= x"0000";
    arvalid  <= '0';    
    wait for 20 ns;
    rready <= '0';
    wait;    
  end process;
  
  simple_write_process : process
  begin
    awaddr <= x"0000";
    awvalid  <= '0';
    wdata  <= x"00000000";
    wvalid  <= '0';
    bready <= '0';    
    wait for 20 ns;
    awaddr <= x"0000";
    awvalid  <= '1';
    wdata  <= x"11117777";
    wvalid  <= '1';
    bready <= '1';
    wait for 20 ns;
    awaddr <= x"0004";
    awvalid  <= '1';
    wdata  <= x"3333CCCC";
    wvalid  <= '1';
    wait for 30 ns;
    awaddr <= x"0000";
    awvalid  <= '0';
    wdata  <= x"00000000";
    wvalid  <= '0';
    wait for 10 ns;
    bready <= '0';
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
    --write (l, String'("aclk: "));
    --write (l, aclk);
    write (l, String'(" || ar: 0x"));
    hwrite (l, araddr);
    write (l, String'(" v:"));
    write (l, arvalid);
    write (l, String'(" r: "));
    write (l, arready);    
    write (l, String'(" || r: 0x"));
    hwrite (l, rdata);
    write (l, String'(" "));
    write (l, rdata(0));
    write (l, String'(" v: "));
    write (l, rvalid);
    write (l, String'(" r: "));
    write (l, rready);
    write (l, String'(" || aw: 0x"));
    hwrite (l, awaddr);
    write (l, String'(" v: "));
    write (l, awvalid);
    write (l, String'(" r: "));
    write (l, awready);    
    write (l, String'(" || w: 0x"));
    hwrite (l, wdata);
    write (l, STring'(" "));
    write (l, wdata(0));
    write (l, String'(" v: "));
    write (l, wvalid);
    write (l, String'(" r: "));
    write (l, wready);
    write (l, String'(" || b:   v: "));
    write (l, bvalid);
    write (l, String'(" r: "));
    write (l, bready);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;

  summary_process : process
    variable l : line;
    variable reads : integer := 0;
    type result_t is array (0 to 5) of std_logic_vector(31 downto 0);
    variable results : result_t;


  begin
    if (reads < 6) then      
      wait until ((rising_edge(aclk)) and (rvalid='1') and (rready='1'));
      --write (l, String'("*** READ DETECTED ***"));
      --writeline(output, l);
      results(reads) := rdata;
      reads := reads + 1;
    else
      wait until (count > 30);
      write (l, String'("*** Simulation Summary ***"));
      writeline(output, l);
      write (l, String'("READS:"));
      writeline(output, l);

      for i in 0 to 5 loop
        write (l, i, right, 2);
        write (l, String'(": "));
        hwrite(l, results(i));
      end loop;
      writeline(output, l);

      assert(results(0) = x"11111111") report("read 1 failed") severity failure;
      assert(results(1) = x"00000000") report("read 2 failed") severity failure;
      assert(results(2) = x"AAAAAAAA") report("read 3 failed") severity failure;
      assert(results(3) = x"BBBBBBBB") report("read 4 failed") severity failure;
      assert(results(4) = x"11117777") report("read 5 failed") severity failure;
      assert(results(5) = x"3333CCCC") report("read 6 failed") severity failure;

      write (l, String'("*** Test results were all SUCCESSFUL!!! ***"));
      writeline(output, l);

      
      wait;
    end if;      
  end process;
    
  
end behaviour;
        
