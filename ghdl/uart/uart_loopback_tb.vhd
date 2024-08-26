library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 

--  Defines a testbench (without any ports)
entity uart_loopback_tb is
end uart_loopback_tb;

architecture behaviour of uart_loopback_tb is
  component uart_tx is
    port (
      CLK          : in  STD_LOGIC;
      RST          : in  STD_LOGIC;
      CLKOUT_RATIO : in  STD_LOGIC_VECTOR (7 downto 0);
      CLKOUT_PHASE : in  STD_LOGIC_VECTOR (3 downto 0);    
      MCLK        : in  STD_LOGIC;
      TX          : out STD_LOGIC;
      data        : in  STD_LOGIC_VECTOR (63 DOWNTO 0);
      data_update : in  STD_LOGIC;
      busy        : out STD_LOGIC
    );  
  end component;

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
  

  signal data     : std_logic_vector(63 DOWNTO 0) := X"C301010101010103";
  signal update   : std_logic := '0';
  
  signal TX       : std_logic;  
  signal TXBUSY   : std_logic;
  
  signal RXDATA   : std_logic_vector(63 DOWNTO 0) := (others => '0');
  signal RXUPDATE : std_logic := '0';
  signal RXBUSY   : std_logic := '0';
begin
  utx: uart_tx port map (
    CLK => aclk,
    RST => rst,
    CLKOUT_RATIO => X"01",
    CLKOUT_PHASE => X"2",
    MCLK => uclk,
    TX   => TX,
    data        => data,
    data_update => update,
    busy        => TXBUSY);

  urx: uart_rx port map (
    CLK => aclk,
    RST => rst,
    CLKIN_RATIO => X"01",
    CLKIN_PHASE => X"2",
    RX   => TX,
    data        => RXDATA,
    data_update => RXUPDATE,
    busy        => RXBUSY
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
  begin
    wait for 300 ns;
    update <= '1';
    wait for 300 ns;
    update <= '0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    wait for 100 ns;
    write  (l, String'("aclk: "));
    write  (l, aclk);
    write  (l, String'(" uclk: "));
    write  (l, uclk);
    write  (l, String'(" || txdata: 0x"));
    hwrite (l, data);
    write  (l, String'(" txupdate: "));
    write  (l, update);
    write  (l, String'(" txbusy: "));
    write  (l, TXBUSY);
    write  (l,  String'(" tx: "));
    write  (l, TX);
    write  (l, String'(" || rxdata: 0x"));
    hwrite (l, RXDATA);
    write  (l, String'(" rxupdate: "));
    write  (l, RXUPDATE);
    write  (l, String'(" rxbusy: "));
    write  (l, RXBUSY);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
