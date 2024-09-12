library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;
use work.register_map.all;

--  Defines a testbench (without any ports)
entity rx_unit_tb is
end rx_unit_tb;
     
architecture behaviour of rx_unit_tb is
  component rx_unit is
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

      LOOPBACK_I             : in std_logic_vector(C_NUM_UART-1 downto 0);
      PISO_I                 : in std_logic_vector(C_NUM_UART-1 downto 0);
      --
      DEBUG_O                : out  std_logic_vector(31 downto 0)
  );
  end component;
  
  signal aclk     : std_logic;
  signal uclk     : std_logic;
  signal aresetn  : std_logic;
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

  signal debug  : std_logic_vector(31 downto 0);

  signal rx     : std_logic := '1';

  signal piso   : std_logic_vector(39 downto 0) := (others=>'1');
  
begin
  uut0: rx_unit port map (
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
    PISO_I              => piso,
    LOOPBACK_I          => piso,
    DEBUG_O             => debug
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
  
  rx_process : process
    variable i      : integer := 0;
    variable rxdata : std_logic_vector(159 downto 0) := x"FF33332222000011117FFF33331111000011117F";
  begin
    wait until rising_edge(uclk);
    if (i<160) then
      piso(0) <= rxdata(i);
      i := i+1;
    else
      piso(0) <= '1';
      wait for 500 ns;
      i := 0;
    end if;
  end process;

  
  read_process : process
  begin
    raddr <= (others => '0');
    rupdate <= '0';        
    wait for 1 ns;
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(16#00200# + C_ADDR_RX_STATUS, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(16#00200# + C_ADDR_RX_CONFIG, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(16#00200# + C_ADDR_RX_LOOK_A, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(16#00200# + C_ADDR_RX_LOOK_B, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(16#00200# + C_ADDR_RX_LOOK_C, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= std_logic_vector(to_unsigned(16#00200# + C_ADDR_RX_LOOK_D, 16));
    rupdate <= '1';
    wait for 100 ns;
    raddr <= (others => '0');
    rupdate <= '0';    
  end process;


  write_process : process
    variable cnt : integer range 0 to 16#FFFF# := 0;
  begin
    cnt := cnt+1;
    wait for 1 ns;
    wait for 20 ns;
    wait for 10 ns;
    waddr <= std_logic_vector(to_unsigned(16#00200# + C_ADDR_RX_CONFIG, 16));
    wdata   <= x"00002001";
    wupdate <= '1';
    wait for 8000 ns;
    waddr <= std_logic_vector(to_unsigned(16#00200# + C_ADDR_RX_COMMAND, 16));
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
    wait for 1 ns;
    --wait for 10 ns;
    wait for 100 ns;
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
    --write (l, String'(" posi: "));
    --hwrite (l, posi);
    --write (l, String'(" 0: "));
    --write (l, posi(0));
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;

end behaviour;
        
