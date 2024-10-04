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
      ACLK          : in  std_logic;
      ARESETN       : in  std_logic;
      UCLK_I        : in  std_logic;    
      CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    
      GFLAGS_I       : in  std_logic_vector(C_TX_GFLAGS_WIDTH-1 downto 0);    
      DATA_I        : in  std_logic_vector(C_TX_DATA_WIDTH-1 downto 0);
      VALID_I       : in  std_logic;
      READY_O       : out std_logic;
      TX_O          : out std_logic;
      DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  signal count     : integer := 0;
  signal aclk      : std_logic;
  signal uclk      : std_logic;
  signal aresetn   : std_logic;
  signal config    : std_logic_vector(31  downto 0)  := x"00001601";  
  signal status    : std_logic_vector(31  downto 0);
  signal gflags     : std_logic_vector(C_TX_GFLAGS_WIDTH-1  downto 0);
  signal valid     : std_logic := '0';
  signal ready     : std_logic;
  signal tx        : std_logic;

  signal data      : std_logic_vector(C_TX_DATA_WIDTH-1 downto 0);
begin
  uut: tx_chan port map (
      ACLK     => aclk,
      ARESETN  => aresetn,
      UCLK_I   => uclk,
      CONFIG_I => config,
      DEBUG_O => status,  -- DEBUG_O is non-delayed status.
      GFLAGS_I => gflags,   
      DATA_I   => data,
      VALID_I  => valid,
      READY_O  => ready,
      TX_O     => tx
  );

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 10 ns;
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

  uclk_process : process
  begin
    uclk <= '1';
    wait for 50 ns;
    uclk <= '0';
    wait for 50 ns;
  end process;

  config_process : process
  begin
    gflags <= "00";
    config <= x"00001601";
    --config <= x"00000601";
    --config <= x"00002601";  
    wait;
  end process;

  tx_process : process
    variable l : line;
  begin
    data  <= (others => '0');
    valid <= '0';
    wait for 20 ns;
    data  <= x"5555555555555555";
    valid <= '1';
    wait until ((rising_edge(aclk)) and (ready='1'));
    wait for 10 ns;
    data  <= (others => '0');
    valid <= '0';
    wait for 40 ns;
    valid <= '1';
    data  <= x"3333333333333333";
    wait until ((rising_edge(aclk)) and (ready='1'));
    wait for 10 ns;
    data  <= (others => '0');
    valid <= '0';
    wait for 40 ns;
    --wait;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;

    if (count < 30) then
      wait for 10 ns;
    elsif (count < 680) then
      wait for 100 ns;
    elsif (count < 690) then
      wait for 10 ns;
    elsif (count < 1500) then
      wait for 100 ns;      
    else
      wait;
    end if;
    --wait for 100 ns;
    --wait for 1000 ns;

    write (l, String'("c: "));
    write (l, count, left, 4);    
    --write  (l, String'(" aclk: "));
    --write  (l, aclk);
    write  (l, String'(" uclk: "));
    write  (l, uclk);
    --write  (l, String'(" | cnf: 0x"));
    --hwrite (l, config(15 downto 0));
    --write  (l, String'(" mode: 0x"));
    --hwrite (l, (config(15 downto 12)));    
    --write  (l, String'(" sta: 0x"));
    --hwrite (l, status(15 downto 0));
    write  (l, String'(" vr: "));
    write  (l, valid);
    write  (l, ready);

    write  (l, String'(" b: "));
    write  (l, status(0));

    write  (l, String'(" vt: "));
    write  (l, status(1));

    write  (l, String'(" | tx: "));
    write  (l, tx);

    if (status(3) = '1') then
      write (l, String'(" --- "));
    end if;
    
    if ((valid = '1') and (ready = '1')) then
      write (l, String'(" *** "));
    end if;

    
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
