library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 

--  Defines a testbench (without any ports)
entity tx_buffer_tb is
end tx_buffer_tb;

architecture behaviour of tx_buffer_tb is
  component tx_buffer is
    port (
      ACLK        : in std_logic;
      ARESETN       : in std_logic;
      UCLK_I        : in std_logic;
      CONFIG_I      : in std_logic_vector(11 downto 0);
      DATA_I        : in std_logic_vector(63 downto 0);
      VALID_I       : in std_logic;
      ACK_O         : out std_logic;
      TX_O          : out std_logic;
      --
      MON_BUSY_O    : out std_logic;
      DEBUG_O       : out std_logic_vector(15 downto 0)      
    );  
  end component;

  signal aclk      : std_logic;
  signal uclk     : std_logic;
  signal aresetn  : std_logic;
  signal config   : std_logic_vector(11 downto 0) := x"601";  
  signal data     : std_logic_vector(63 DOWNTO 0) := (others => '0');
  signal valid    : std_logic := '0';
  signal ack      : std_logic;
  signal debug    : std_logic_vector(15 DOWNTO 0);
  signal tx       : std_logic;
  signal busy     : std_logic;
begin
  uut: tx_buffer port map (
    ACLK => aclk,
    ARESETN => aresetn,
    UCLK_I => uclk,
    CONFIG_I => config,
    DATA_I => data,
    VALID_I => valid,
    ACK_O => ack,
    TX_O => tx,   
    MON_BUSY_O => busy,    
    DEBUG_O => debug    
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

  tx_process : process
  begin
    wait for 41 ns;
    valid <= '1';
    data  <= X"5555555555555555";
    wait until ack='1';
    wait for 11 ns;
    valid <= '0';
    data  <= X"0000000000000000";
    wait for 30 ns;
    valid <= '1';
    data  <= X"3333333333333333";    
    wait until ack='1';
    wait for 11 ns;
    valid <= '0';
    data  <= X"0000000000000000";
    wait;
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
    write  (l, String'(" || txdata: 0x"));
    hwrite (l, data(7 downto 0));
    write  (l, String'(" valid: "));
    write  (l, valid);
    write  (l, String'(" ack: "));
    write  (l, ack);
    write  (l, String'(" || txstart: "));
    write  (l, debug(0));
    write  (l, String'(" || tx: "));
    write  (l, tx);
    write  (l, String'(" || busy: "));
    write  (l, debug(1));

    
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
