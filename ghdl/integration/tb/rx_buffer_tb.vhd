library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 

--  Defines a testbench (without any ports)
entity rx_buffer_tb is
end rx_buffer_tb;
library work;
use work.common.all;

architecture behaviour of rx_buffer_tb is
  component rx_buffer is
    port (
      ACLK          : in std_logic;
      ARESETN       : in std_logic;
      CONFIG_I      : in std_logic_vector(C_RX_BUFFER_CONFIG_WIDTH-1 downto 0);
    
      DATA_O        : out std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0);      
      VALID_O       : out std_logic;
      LOST_O        : out std_logic;
      ACK_I         : in  std_logic;
      RX_I          : in  std_logic;

      TIMESTAMP_I   : in  std_logic_vector(31 downto 0);
      CHANNEL_I     : in  std_logic_vector(7 downto 0);
      HEADER_I      : in  std_logic_vector(7 downto 0);      
      --
      MON_BUSY_O    : out std_logic;
      DEBUG_O       : out std_logic_vector(15 downto 0)
    );  
  end component;

  signal aclk      : std_logic;
  signal uclk     : std_logic;
  signal aresetn  : std_logic;
  signal rst      : std_logic;
  
  signal data     : std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 DOWNTO 0);
  signal valid    : std_logic;
  signal lost     : std_logic;
  signal ack      : std_logic := '0';
  signal busy     : std_logic;

  signal debug    : std_logic_vector(15 downto 0);

  signal tx     : std_logic := '1';
  
begin
  urx: rx_buffer port map (
    ACLK    => aclk,
    ARESETN => aresetn,
    CONFIG_I  => x"001",
    DATA_O    => data,
    VALID_O => valid,
    LOST_O => lost,
    ACK_I => ack,
    RX_I => tx,
    TIMESTAMP_I => x"00000EE0",
    CHANNEL_I   => x"11",
    HEADER_I    => x"44",    
    MON_BUSY_O => busy,
    DEBUG_O => debug
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

  ack_process : process
  begin
    --
    ack <= '0';
    wait for 15350 ns;
    ack <= '1';
    wait for 10 ns;
    ack <= '0';
    wait;
  end process;

  tx_process : process
    variable i      : integer := 0;
    variable txdata : std_logic_vector(159 downto 0) := x"FF33332222000011117FFF33331111000011117F";
  begin
    wait until rising_edge(uclk);
    if (i<160) then
      tx <= txdata(i);
      i := i+1;
    else
      tx <= '1';
      wait for 500 ns;
      i := 0;
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
    write  (l, String'(" || data: 0x"));
    hwrite (l, data);
    write  (l, String'(" valid: "));
    write  (l, valid);
    write  (l, String'(" ack: "));
    write  (l, ack);
    write  (l, String'(" lost: "));
    write  (l, lost);
    write  (l, String'(" busy: "));
    write  (l, busy);
    write  (l,  String'(" tx: "));
    write  (l, tx);
    write  (l,  String'(" update: "));
    write  (l, debug(0));
    write  (l,  String'(" busy: "));
    write  (l, debug(1));
    write  (l,  String'(" rx: "));
    write  (l, debug(2));
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
