library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;
use work.register_map.all;

--  Defines a testbench (without any ports)
entity single_shot_tb is
end single_shot_tb;
     
architecture behaviour of single_shot_tb is
  component tx_unit is
    port (
      ACLK	        : in std_logic;
      ARESETN	        : in std_logic;
      UCLK_I	        : in std_logic;
      
      S_REGBUS_RB_RADDR	     : in  std_logic_vector(15 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(31 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;
      
      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(15 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(31 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;
      POSI_O                 : out std_logic_vector(39 downto 0);
      DEBUG_O                : out std_logic_vector(31 downto 0)
  );
  end component;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
  signal uclk     : std_logic;
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

  signal posi   : std_logic_vector(39 downto 0);
  signal debug  : std_logic_vector(31 downto 0);

  signal status : std_logic_vector(31 downto 0);
  signal look_c : std_logic_vector(31 downto 0);
  signal look_d : std_logic_vector(31 downto 0);
  signal acks   : std_logic_vector(31 downto 0); 
 

begin
  uut0: tx_unit port map (
      ACLK           => aclk,
      ARESETN        => aresetn,
      UCLK_I           => uclk,
      S_REGBUS_RB_RUPDATE => rupdate,
      S_REGBUS_RB_RADDR   => raddr,
      S_REGBUS_RB_RDATA   => rdata,
      S_REGBUS_RB_RACK    => rack,
      S_REGBUS_RB_WUPDATE => wupdate,
      S_REGBUS_RB_WADDR   => waddr,
      S_REGBUS_RB_WDATA   => wdata,
      S_REGBUS_RB_WACK    => wack,
      POSI_O                => posi,
      DEBUG_O               => debug
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

  uclk_process : process
  begin
    uclk <= '1';
    wait for 50 ns;
    uclk <= '0';
    wait for 50 ns;
  end process;

  monitor_process : process
    variable l : line;
  begin
    wait for 70 ns;
    raddr <= std_logic_vector(to_unsigned(C_ADDR_TX_STATUS, 16));
    rupdate <= '1';
    wait for 10 ns;
    status <= rdata;
    raddr <= std_logic_vector(to_unsigned(C_ADDR_TX_LOOK_C, 16));
    rupdate <= '1';
    wait for 10 ns;
    look_c <= rdata;
    raddr <= std_logic_vector(to_unsigned(C_ADDR_TX_LOOK_D, 16));
    rupdate <= '1';
    wait for 10 ns;
    look_d <= rdata;
    raddr <= std_logic_vector(to_unsigned(C_ADDR_TX_ACKS, 16));
    rupdate <= '1';
    wait for 10 ns;
    acks <= rdata;
    raddr <= (others => '0');
    rupdate <= '0';

    write (l, String'(" sta: 0x"));
    hwrite (l, status);
    write (l, String'(" lkc: 0x"));
    hwrite (l, look_c);
    write (l, String'(" lkd: 0x"));
    hwrite (l, look_d);
    write (l, String'(" acks: 0x"));
    hwrite (l, acks);
    write (l, String'(" valid: "));
    write (l, status(0));    
    writeline(output, l);
  end process;

  rapid_write_process : process
    variable cnt : integer range 0 to 16#FFFF# := 0;
  begin
    cnt := cnt+1;
    wait for 1 ns;
    wait for 20 ns;
    waddr <= std_logic_vector(to_unsigned(C_ADDR_TX_CONFIG, 16));
    wdata   <= x"00002001";
    wupdate <= '1';
    wait for 10 ns;
    waddr <= std_logic_vector(to_unsigned(C_ADDR_TX_SEND_C, 16));
    wdata   <= std_logic_vector(to_unsigned((cnt),32));
    wupdate <= '1';
    wait for 10 ns;
    waddr <= std_logic_vector(to_unsigned(C_ADDR_TX_SEND_D, 16));
    wdata   <=  x"DDDDDDDD";
    wupdate <= '1';
    wait for 10 ns;
    waddr <= std_logic_vector(to_unsigned(C_ADDR_TX_COMMAND, 16));
    wdata   <= x"00000003";
    wupdate <= '1';
    wait for 10 ns;    
    waddr   <= (others => '0');
    wdata   <= (others => '0');
    wupdate <= '0';    
    wait until status(0) = '0';
  end process;

  
end behaviour;
        
