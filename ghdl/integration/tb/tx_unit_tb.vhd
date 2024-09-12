library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;
use work.register_map.all;

--  Defines a testbench (without any ports)
entity tx_unit_tb is
end tx_unit_tb;
     
architecture behaviour of tx_unit_tb is
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

  signal output_registers : std_logic :='1';
  signal output_tx        : std_logic :='0';

  signal posi   : std_logic_vector(39 downto 0);
  signal debug  : std_logic_vector(31 downto 0);


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


  read_process : process
  begin
    wait for 1 ns;
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(C_ADDR_TX_STATUS, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(C_ADDR_TX_CONFIG, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(C_ADDR_TX_SEND_C, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(C_ADDR_TX_SEND_D, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(C_ADDR_TX_LOOK_C, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(C_ADDR_TX_LOOK_D, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= (others => '0');
    rupdate <= '0';

    
  end process;

  rapid_write_process : process
    variable cnt : integer range 0 to 16#FFFF# := 0;
  begin
    cnt := cnt+1;
    wait for 1 ns;
    wait for 20 ns;
    wait for 10 ns;
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
    wdata   <= x"00000001";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= (others => '0');
    wdata   <= (others => '0');
    wupdate <= '0';    
    wait for 1000 ns;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    --wait for 10 ns;
    wait for 100 ns;
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
    if (output_registers='1') then 
      write (l, String'(" uclk: "));
      write (l, uclk);
      write (l, String'(" posi: "));
      hwrite (l, posi);
      write (l, String'(" 0: "));
      write (l, posi(0));
      write (l, String'(" bsy: "));
      write (l, debug(0));
      write (l, String'(" v: "));
      write (l, debug(1));
      write (l, String'(" sa: "));
      write (l, debug(2));
      write (l, String'(" so: "));
      write (l, debug(3));
    end if;
  
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
