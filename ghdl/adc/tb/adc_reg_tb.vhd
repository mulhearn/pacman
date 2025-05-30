library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity adc_reg_tb is
end adc_reg_tb;
     
architecture behaviour of adc_reg_tb is
  component adc_reg is
    port (
      ACLK	           : in std_logic;
      ARESETN	           : in std_logic;

      S_REGBUS_RB_RADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE  : in  std_logic;
      S_REGBUS_RB_RACK     : out std_logic;
      
      S_REGBUS_RB_WUPDATE  : in  std_logic;
      S_REGBUS_RB_WADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK     : out std_logic;

      CONFIG_O             : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CLKPAR_O             : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      COMMAND_O            : out std_logic_vector(7 downto 0);
      STATE_I              : in  std_logic_vector(3 downto 0);
      STATUS_I             : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LAST_I               : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LOOK_I               : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;
  signal count     : integer := 0;
  signal aclk      : std_logic;
  signal aresetn   : std_logic;
  -- registers
  signal config  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal clkpar  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal command : std_logic_vector(7 downto 0);

  -- read signals:
  signal raddr   : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rupdate : std_logic := '0';
  signal rdata   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rack    : std_logic := '0';
  -- write signals:
  signal waddr   : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wupdate : std_logic := '0';
  signal wdata   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal wack    : std_logic := '0';
begin
  uut: adc_reg port map (
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

      CONFIG_O            => config,
      CLKPAR_O            => clkpar,
      COMMAND_O           => command,
      STATUS_I            => x"11112222",
      STATE_I             => x"4",
      LAST_I              => x"00000AAA",
      LOOK_I              => x"11111BBB"      
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
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 1 ns;
    wait for 40 ns;
    raddr   <= x"D100";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D104";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D108";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D110";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D114";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D200";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D204";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait;
  end process;

  write_process : process
  begin
    wait for 18 ns;
    waddr   <= x"D110";
    wdata   <= x"FEEDDADA";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D114";
    wdata   <= x"DEADBEEF";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D118";
    wdata   <= x"000000EF";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D200";
    wdata   <= x"AAAAAAAA";
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
    if (count < 15) then
      wait for 10 ns;
    else
      wait;
    end if;
    write (l, String'("c: "));
    write (l, count, left, 4);
    --write (l, String'("aclk: "));
    --write (l, aclk);
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
    write (l, String'(" wk:"));
    write (l, wack);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
