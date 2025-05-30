library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity adc_daq_tb is
end adc_daq_tb;
     
architecture behaviour of adc_daq_tb is
  component adc_daq is
    port (
      ACLK           : in  std_logic;
      ARESETN        : in  std_logic;

      -- ADC
      ADC_DATA_I     : in  std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
      ADC_DOF_I      : in  std_logic;
      ADC_EN_O       : out std_logic;

      -- REGISTER
      CONFIG_I       : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      COMMAND_I      : in  std_logic_vector(7 downto 0);
      STATUS_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LAST_O         : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATE_O        : out std_logic_vector(3 downto 0);

      -- BRAM
      BRAM_EN_O      : out std_logic; 
      BRAM_DATA_O    : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
      BRAM_WEN_O     : out std_logic_vector(3 downto 0);
      BRAM_ADDR_O    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
      BRAM_CLK_O     : out std_logic;
      BRAM_RST_O     : out std_logic
      );
  end component;
  signal count     : integer := 0;
  signal aclk      : std_logic;
  signal aresetn   : std_logic;
  signal config    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal stat      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal last      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal wen       : std_logic_vector(3 downto 0);
  signal addr      : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal do        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal di        : std_logic_vector(ADC_DATA_WIDTH-1 downto 0) := (others => '0');
  signal diof      : std_logic := '0';
  signal adc_e     : std_logic := '0';
  signal command   : std_logic_vector(7 downto 0) := (others => '0');
  signal state     : std_logic_vector(3 downto 0) := (others => '0');

  signal clock     : std_logic;
  signal reset     : std_logic;
  signal adc_data  : std_logic_vector(11 downto 0);
  signal adc_of    : std_logic;
  signal data_o    : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal address   : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal trigger   : std_logic := '0';
  signal old_state : std_logic_vector(3 downto 0) := (others => '0');
begin
  uut: adc_daq port map (
      ACLK         => aclk,
      ARESETN      => aresetn,      
      ADC_DATA_I   => di,
      ADC_DOF_I    => diof,
      ADC_EN_O     => adc_e,
      CONFIG_I     => config,
      COMMAND_I    => command,
      STATUS_O     => stat,
      LAST_O       => last,
      STATE_O      => state,
      BRAM_DATA_O  => do,
      BRAM_WEN_O   => wen,
      BRAM_ADDR_O  => addr
      );

  clock <= aclk;
  reset <= aresetn;
  adc_data <= di;
  adc_of   <= diof;
  data_o   <= do;
  address  <= addr;
  trigger  <= state(1) and not old_state(1);
  
  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 12 ns;
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
    old_state <= state;
  end process;

  config_in : process
  begin
    wait for 18 ns;
    config <= x"00300033";
    --wait for 20 ns;
    --config <= x"000F0013";
    --wait for 70 ns;
    --config <= x"00400033";
    wait for 70 ns;
    wait;
  end process;

  --command_in : process
  --begin
  --  wait for 28 ns;
  --  command <= x"02";
  --  wait for 10 ns;
  --  command <= x"00";
  --  wait for 10 ns;
  --  command <= x"04";
  --  wait for 10 ns;
  --  command <= x"00";
  --  wait for 10 ns;
  --  command <= x"02";
  --  wait for 10 ns;
  --  command <= x"00";
  --  wait for 200 ns;
  --  command <= x"01";
  --  wait for 10 ns;
  --  command <= x"00";
  --  wait for 20 ns;
  --  command <= x"02";
  --  wait for 10 ns;
  --  command <= x"00";
  --  wait;
  --end process;

  data_in : process
  begin
    di     <= x"000";
    diof   <= '0';
    wait for 18 ns;
    di     <= x"111";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"222";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"333";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"444";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"555";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"666";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"777";
    diof   <= '0';   
    wait for 10 ns;
    di     <= x"888";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"999";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"AAA";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"BBB";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"CCC";
    diof   <= '1';  
    wait for 10 ns;
    di     <= x"DDD";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"EEE";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"FFF";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"001";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"112";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"223";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"334";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"445";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"556";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"667";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"778";
    diof   <= '0';   
    wait for 10 ns;
    di     <= x"889";
    diof   <= '1';
    wait for 10 ns;
    di     <= x"99A";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"AAB";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"BBC";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"CCD";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"DDE";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"EEF";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"FF0";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"ACE";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"222";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"333";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"444";
    diof   <= '1';
    wait for 10 ns;
    di     <= x"555";
    diof   <= '0';  
    wait for 10 ns;
    di     <= x"666";
    diof   <= '0';
    wait;
  end process;

  
end behaviour;
