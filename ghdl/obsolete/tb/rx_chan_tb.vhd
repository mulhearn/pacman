library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity rx_chan_tb is
end rx_chan_tb;

architecture behaviour of rx_chan_tb is
  component rx_chan is
    port (
      ACLK        : in std_logic;
      ARESETN     : in std_logic;
      CONFIG_I    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      COMMAND_I   : in  std_logic_vector(C_COMMAND_WIDTH-1 downto 0);
      STATUS_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      COUNT_O     : out std_logic_vector(C_RX_CHAN_COUNT_WIDTH-1 downto 0);

      BUSY_I      : in  std_logic;
      TURN_I      : in  std_logic_vector(C_UART_CHAN_ADDR_WIDTH-1 downto 0);
      WEN_O       : out std_logic;
      
      DATA_O      : out std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0);        
      RX_I        : in  std_logic;
      DEBUG_O     : out  std_logic_vector(15 downto 0)
    );  
  end component;

  signal aclk      : std_logic;
  signal uclk      : std_logic;
  signal aresetn   : std_logic;
  signal wen       : std_logic;
  signal config    : std_logic_vector(31  downto 0)  := x"00000601";  
  signal command   : std_logic_vector(7 downto 0);
  signal status    : std_logic_vector(31  downto 0) := (others => '0');    
  signal data      : std_logic_vector(127 DOWNTO 0);
  signal rx        : std_logic := '1';
  signal debug     : std_logic_vector(15 downto 0);
  
begin
  uut: rx_chan port map (
    ACLK       => aclk,
    ARESETN    => aresetn,
    CONFIG_I   => config,
    COMMAND_I  => command,
    STATUS_O   => status,
    BUSY_I     => '0',
    TURN_I     => (others => '0'),
    WEN_O      => wen,
    DATA_O     => data,
    RX_I       => rx,
    DEBUG_O    => debug
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
  
  config_process : process
  begin
    config <= x"00001001";  
    wait;
  end process;

  rx_process : process
    variable i      : integer := 0;
    variable rxdata : std_logic_vector(159 downto 0) := x"FF33332222000011117FFF33331111000011117F";
  begin
    wait until rising_edge(uclk);
    if (i<160) then
      rx <= rxdata(i);
      i := i+1;
    else
      rx <= '1';
      wait for 500 ns;
      i := 0;
    end if;
  end process;

  data_process : process
  begin
    command <= x"00";
    wait for 7500 ns;
    command <= x"01";
    wait for 10 ns;
    command <= x"00";
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    wait for 10 ns;
    --wait for 100 ns;
    --wait for 1000 ns;
    write  (l, String'("aclk: "));
    write  (l, aclk);
    write  (l, String'(" || cnf: 0x"));
    hwrite (l, config(15 downto 0));
    write  (l, String'(" || mode: 0x"));
    hwrite (l, ('0'&config(14 downto 12)));    
    write  (l, String'(" cmd: 0x"));
    hwrite (l, command);
    write  (l, String'(" aks: 0x"));
    hwrite (l, status(31 downto 16));
    write  (l, String'(" sta: 0x"));
    hwrite (l, status(15 downto 0));
    write  (l, String'(" v: "));
    write (l, status(0));
    write  (l, String'(" b: "));
    write (l, status(1));
    write  (l, String'(" a: "));
    write (l, status(2));
write  (l, String'(" || data: 0x"));
    hwrite (l, data);
    write  (l, String'(" wen: "));
    write  (l, wen);    
    write  (l, String'(" rx: "));
    write  (l, rx);
    write  (l, String'(" s: "));
    write  (l, debug(0));
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
