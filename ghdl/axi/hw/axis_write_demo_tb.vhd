library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity axis_write_demo_tb is
end axis_write_demo_tb;
     
architecture behaviour of axis_write_demo_tb is
  component axis_write_demo is
    port (
      M_AXIS_ACLK        : in std_logic;
      M_AXIS_ARESETN     : in std_logic;      
      M_AXIS_TDATA       : out std_logic_vector(127 downto 0);      
      M_AXIS_TVALID      : out std_logic;
      M_AXIS_TREADY      : in std_logic;
      M_AXIS_TKEEP       : out std_logic_vector(15 downto 0);      
      M_AXIS_TLAST       : out std_logic;

      S_REGBUS_RB_RUPDATE : in  std_logic;
      S_REGBUS_RB_RADDR   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      S_REGBUS_RB_RACK    : out  std_logic;
    
      S_REGBUS_RB_WUPDATE : in  std_logic;
      S_REGBUS_RB_WADDR   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK    : out  std_logic;

      REGA_I              : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      REGB_I              : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)      
    );
  end component;
  signal count    : integer := 0;  
  signal aclk     : std_logic;
  signal aresetn  : std_logic;

  signal tdata       : std_logic_vector(127 downto 0);      
  signal tvalid      : std_logic;
  signal tready      : std_logic := '0';
  signal tlast       : std_logic;

  signal rupdate  : std_logic := '0';
  signal raddr    : std_logic_vector(15 downto 0) := (others => '0');
  signal rdata    : std_logic_vector(31 downto 0);
  signal rack     : std_logic;

  signal wupdate  : std_logic := '0';
  signal waddr    : std_logic_vector(15 downto 0) := (others => '0');
  signal wdata    : std_logic_vector(31 downto 0) := (others => '0');
  signal wack     : std_logic;

begin
  uut: axis_write_demo port map (
    M_AXIS_ACLK         => aclk,
    M_AXIS_ARESETN      => aresetn,
    M_AXIS_TDATA        => tdata,
    M_AXIS_TVALID       => tvalid,
    M_AXIS_TREADY       => tready,
    M_AXIS_TLAST        => tlast,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,    
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack,    
    REGA_I              => x"12345678",
    REGB_I              => x"FFAAAAFF"    
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

  write_process : process
  begin
    wait for 1 ns;
    wait for 20 ns;
    wupdate <= '1';
    waddr <= x"0008";
    --wdata <= x"00000001";
    wdata <= x"00030001";
    wait for 10 ns;
    wupdate <= '0';
    waddr <= x"0000";
    wdata <= x"00000000";
    wait for 90 ns;
    wupdate <= '1';
    waddr <= x"0008";
    wdata <= x"00000000";
    wait for 10 ns;
    wupdate <= '0';
    waddr <= x"0000";
    wdata <= x"00000000";    
    wait;
  end process;

  read_process : process
  begin
    wait for 1 ns;
    wait for 50 ns;
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
    rupdate <= '0';
    raddr <= x"0000";
    wait;
  end process;
    
  ready_process : process
  begin
    wait for 50 ns;
    wait until (rising_edge(aclk));
    tready <= '1';
    wait for 10 ns;
    wait until (rising_edge(aclk));
    tready <= '0';
    wait for 20 ns;
    wait until (rising_edge(aclk));
    tready <= '1';
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
    hwrite (l, tdata);
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

  summary_process : process
    variable l : line;
    --variable reads : integer := 0;
    --type result_t is array (0 to 5) of std_logic_vector(31 downto 0);
    --variable results : result_t;
  begin
    --if (reads < 6) then      
      --wait until ((rising_edge(aclk)) and (rvalid='1') and (rready='1'));
      --write (l, String'("*** READ DETECTED ***"));
      --writeline(output, l);
      --results(reads) := rdata;
      --reads := reads + 1;
    --else
      wait until (count > 30);
      write (l, String'("*** Simulation Summary ***"));
      writeline(output, l);
      --for i in 0 to 5 loop
        --write (l, i, right, 2);
        --write (l, String'(": "));
        --hwrite(l, results(i));
      --end loop;
      --writeline(output, l);

      --assert(results(0) = x"11111111") report("read 1 failed") severity failure;
      --assert(results(1) = x"00000000") report("read 2 failed") severity failure;
      --write (l, String'("*** Test results were all SUCCESSFUL!!! ***"));
      --writeline(output, l);      
      wait;
  --end if;      
  end process;
    
  
end behaviour;
        
