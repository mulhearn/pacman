library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity tx_chan_tb is
end tx_chan_tb;

architecture behaviour of tx_chan_tb is
  component tx_chan is
    port (
      ACLK        : in std_logic;
      ARESETN     : in std_logic;
      UCLK_I      : in std_logic;
      CONFIG_I    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      COMMAND_I   : in  std_logic_vector(C_COMMAND_WIDTH-1 downto 0);
      STATUS_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    
      SEND_I      : in std_logic_vector(C_TX_CHAN_DATA_WIDTH-1 downto 0);
      LOOK_O      : out std_logic_vector(C_TX_CHAN_DATA_WIDTH-1 downto 0);      
      TX_O        : out std_logic;
      DEBUG_O     : out  std_logic_vector(15 downto 0)
    );  
  end component;

  signal aclk      : std_logic;
  signal uclk      : std_logic;
  signal aresetn   : std_logic;
  signal config    : std_logic_vector(31  downto 0)  := x"00000601";  
  signal command   : std_logic_vector(7 downto 0);
  signal status    : std_logic_vector(31  downto 0) := (others => '0');  
  signal send      : std_logic_vector(63 DOWNTO 0)  := (others => '0');
  signal look      : std_logic_vector(63 DOWNTO 0);
  signal valid     : std_logic := '0';
  signal ack       : std_logic;
  signal tx        : std_logic;
  signal debug     : std_logic_vector(15 downto 0);
  
begin
  uut: tx_chan port map (
    ACLK       => aclk,
    ARESETN    => aresetn,
    UCLK_I     => uclk,
    CONFIG_I   => config,
    COMMAND_I  => command,
    STATUS_O   => status,
    SEND_I     => send,
    LOOK_O     => look,
    TX_O       => tx,
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
    config <= x"00002601";  
    wait;
  end process;
  
  tx_process : process
    variable data : integer := 16#00#;
  begin
    data := data + 1;
    wait for 50 ns;
    send    <= std_logic_vector(to_unsigned(data, send'length));
    command <= x"01";
    wait for 10 ns;
    command <= x"01";
    wait for 8000 ns;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    --wait for 10 ns;
    --wait for 100 ns;
    wait for 1000 ns;
    write  (l, String'("aclk: "));
    write  (l, aclk);
    write  (l, String'(" uclk: "));
    write  (l, uclk);
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
    write  (l, String'(" || send: 0x"));
    hwrite (l, send(7 downto 0));
    write  (l, String'(" || look: 0x"));
    hwrite (l, look(7 downto 0));
    write  (l, String'(" tx: "));
    write  (l, tx);
    write  (l, String'(" bsy: "));
    write  (l, debug(0));
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
