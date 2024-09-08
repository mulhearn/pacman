library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 

--  Defines a testbench (without any ports)
entity uart_rx_tb is
end uart_rx_tb;

architecture behaviour of uart_rx_tb is
  component uart_rx is
   port (
      CLK         : in   STD_LOGIC;
      RST         : in   STD_LOGIC;
      CLKIN_RATIO : in   STD_LOGIC_VECTOR (7 downto 0);
      CLKIN_PHASE : in   STD_LOGIC_VECTOR (3 downto 0);    
      RX          : in   STD_LOGIC;
      data        : out  STD_LOGIC_VECTOR (63 DOWNTO 0);
      data_update : out  STD_LOGIC;
      busy        : out  STD_LOGIC
    );  
  end component;

  signal aclk      : std_logic;
  signal uclk     : std_logic;
  signal aresetn  : std_logic;
  signal rst      : std_logic;
  
  signal data     : std_logic_vector(63 DOWNTO 0);
  signal update   : std_logic;
  signal busy   : std_logic;
  
  signal tx       : std_logic := '1'; 
begin
  urx: uart_rx port map (
    CLK => aclk,
    RST => rst,
    CLKIN_RATIO => X"01",
    CLKIN_PHASE => X"0",
    RX   => tx,
    data        => data,
    data_update => update,
    busy        => busy
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

  tx_process : process
    variable i      : integer := 0;
    variable txdata : std_logic_vector(79 downto 0) := x"FF5555FFFF000055557F";
  begin
    --wait on uclk;
    wait until rising_edge(uclk);
    
      
    if (i<80) then
      tx <= txdata(i);
      i := i+1;
    else
      tx <= '1';
    end if;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    wait for 10 ns;
    --wait for 100 ns;
    write  (l, String'("aclk: "));
    write  (l, aclk);
    write  (l, String'(" uclk: "));
    write  (l, uclk);
    write  (l, String'(" || rxdata: 0x"));
    hwrite (l, data);
    write  (l, String'(" rxupdate: "));
    write  (l, update);
    write  (l, String'(" rxbusy: "));
    write  (l, busy);
    write  (l,  String'(" tx: "));
    write  (l, tx);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
