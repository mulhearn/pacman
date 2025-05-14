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
      STATUS_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LAST_O         : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

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
begin
  uut: adc_daq port map (
      ACLK         => aclk,
      ARESETN      => aresetn,      
      ADC_DATA_I   => di,
      ADC_DOF_I    => diof,
      ADC_EN_O     => adc_e,
      CONFIG_I     => config,
      STATUS_O     => stat,
      LAST_O       => last,
      BRAM_DATA_O  => do,
      BRAM_WEN_O   => wen,
      BRAM_ADDR_O  => addr       
      );
  
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
  end process;

  data_in : process
  begin
    --di     <= x"ACE";
    --diof   <= '0';
    wait for 8 ns;
    config <= x"000000A0";
    wait for 20 ns;
    config <= x"000000A1";
    wait for 20 ns;
    config <= x"00000FB1";
    wait for 20 ns;
    config <= x"0ACE0AB0";
    wait for 20 ns;
    config <= x"0DEAAAC1";
    wait for 20 ns;
    config <= x"00000000";
    wait;
  end process;

  
end behaviour;
