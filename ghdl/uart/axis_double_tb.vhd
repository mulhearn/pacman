library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 

--  Defines a testbench (without any ports)
entity axis_double_tb is
end axis_double_tb;

architecture behaviour of axis_double_tb is

  component axis_double is      
  port (
    ACLK            : in  std_logic;
    ARESETN         : in  std_logic;
    S_AXIS_VALID    : in  std_logic;
    S_AXIS_DATA     : in  std_logic_vector(63 downto 0);
    S_AXIS_READY    : out std_logic;
    M_AXIS_VALID    : out std_logic;
    M_AXIS_DATA     : out std_logic_vector(127 downto 0);
    M_AXIS_READY    : in  std_logic;
    DEBUG           : out std_logic_vector(7 downto 0) := (others => '0')
    );
  end component;
  
  signal aclk     : std_logic;
  signal uclk     : std_logic;
  signal aresetn  : std_logic;
  signal rst      : std_logic;
  signal ivalid   : std_logic := '0';
  signal idata    : std_logic_vector(63 downto 0) := (others => '0');
  signal iready   : std_logic;
  signal ovalid   : std_logic;
  signal odata    : std_logic_vector(127 downto 0);
  signal oready   : std_logic := '0';  
  signal debug    : std_logic_vector(7 downto 0);
begin
  uut : axis_double port map (
    ACLK     => aclk,
    ARESETN  => aresetn,
    S_AXIS_VALID    => ivalid,
    S_AXIS_DATA     => idata,
    S_AXIS_READY    => iready,
    M_AXIS_VALID    => ovalid,
    M_AXIS_DATA     => odata,
    M_AXIS_READY    => oready,
    DEBUG    => debug
    );

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 30 ns;
    aresetn <= '1';
    wait;
  end process;
  rst <= not aresetn;
  
  aclk_process : process
  begin
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

  single_tx_process : process
  begin
    idata <= (others => '0');
    oready <= '0';
    ivalid <= '0';
    wait for 50 ns;
    ivalid <= '1';
    idata  <= x"AAAAAAAABBBBBBBB";
    wait for 10 ns;
    idata  <= x"CCCCCCCCDDDDDDDD";
    wait for 10 ns;
    idata  <= x"1111111111111111";
    oready <= '1';
    wait for 10 ns;
    oready <= '0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    wait for 10 ns;
    --wait for 100 ns;
    write  (l, String'("aclk: "));
    write  (l, aclk);
    --write  (l, String'(" uclk: "));
    --write  (l, uclk);
    write  (l, String'(" ivalid: "));
    write  (l, ivalid);
    write  (l, String'(" iready: "));
    write  (l, iready);
    --write  (l, String'(" oready(reg): "));
    --write  (l, debug(2));    
    write  (l, String'(" vup: "));
    write  (l, debug(0));
    write  (l, String'(" idata: 0x"));
    hwrite (l, idata);
    write  (l, String'(" odata: 0x"));
    hwrite (l, odata);
    write  (l, String'(" ovalid: "));
    write  (l, ovalid);
    write  (l, String'(" oready: "));
    write  (l, oready);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
