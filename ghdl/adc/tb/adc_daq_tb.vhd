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
      ACLK      : in std_logic;
      ARESETN   : in std_logic;

      DATA_IN   : in std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
      DOF_IN    : in std_logic;

      TRIG_MODE : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      DATA_OUT  : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

      ADDR      : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
      WEN       : out std_logic_vector(3 downto 0);
    
      LAST_W    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
      );
  end component;
  signal count     : integer := 0;
  signal last_w    : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal wen       : std_logic_vector(3 downto 0);
  signal addr      : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal do        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal di        : std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
  signal diof      : std_logic;
  signal aclk      : std_logic;
  signal aresetn   : std_logic;
  signal trig_mode : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
begin
  uut: adc_daq port map (
      TRIG_MODE      => trig_mode,
      ACLK           => aclk,
      ARESETN        => aresetn,      
      DATA_IN        => di,
      DOF_IN         => diof,
      DATA_OUT       => do,
      ADDR           => addr,
      WEN            => wen,
      LAST_W         => last_w
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
    di     <= x"ACE";
    diof   <= '0';
    wait for 8 ns;
    trig_mode <= x"00000001";
    wait for 10 ns;
    wait for 10 ns;
    wait for 10 ns;
    di     <= x"444";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"DEA";
    diof   <= '0';
    wait for 10 ns;
    di     <= x"DED";
    diof   <= '0';
    wait for 20 ns;
    trig_mode <= x"00000000";
    wait for 10 ns;
    di     <= x"FAB";
    diof   <= '0';  
    wait for 10 ns;
    trig_mode <= x"000000FF";
    wait for 10 ns;
    di     <= x"ACE";
    diof   <= '0';    
    wait for 10 ns;  
    wait;
  end process;
end behaviour;
        
