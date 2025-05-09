library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

entity ADC_unit_tb is
end ADC_unit_tb;

architecture behaviour of ADC_unit_tb is
  component ADC_unit is
    port (
      ACLK	        : in std_logic;
      ARESETN	        : in std_logic;

      -- REGBUS Ports
      S_REGBUS_RB_RUPDATE : in  std_logic;
      S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      S_REGBUS_RB_RACK    : out std_logic;
    
      S_REGBUS_RB_WUPDATE : in  std_logic;
      S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK    : out std_logic;

      -- Data Ports
      DATA_IN             : in  std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
      DOF_IN              : in  std_logic;
      DATA_OUT            : out std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
      DOF_OUT             : out std_logic;
      BRAM_ADDR           : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
      WEN                 : out std_logic;

      -- ADC Ports
      ADC_EN              : out std_logic;
      ADC_CLK             : out std_logic   
    );
  end component;
  
  signal count     : integer := 0;
  signal aclk      : std_logic;
  signal aresetn   : std_logic;

  -- regbus 
  -- read signals:
  signal raddr   : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rupdate : std_logic := '0';
  signal rdata   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rack    : std_logic := '0';
  -- write signals:
  signal waddr   : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wupdate : std_logic := '0';
  signal wdata   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal wack    : std_logic := '0';

  -- daq
  signal wen       : std_logic;
  signal addr      : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal doof      : std_logic;
  signal do        : std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
  signal di        : std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
  signal diof      : std_logic;

  -- adc
  signal adc_en    : std_logic;
  signal adc_clk   : std_logic;

begin
  uut: ADC_unit port map (
    ADC_EN         => adc_en,
    ADC_CLK        => adc_clk,
    ACLK           => aclk,
    ARESETN        => aresetn,
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack, 
    DATA_IN        => di,
    DOF_IN         => diof,
    DATA_OUT       => do,
    DOF_OUT        => doof,
    BRAM_ADDR      => addr,
    WEN            => wen
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
    di     <= x"000";
    diof   <= '0';
    wait for 8 ns;
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
    diof   <= '0';  
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
    diof   <= '0';
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
    wait;
  end process;

write_process : process
  begin
    wait for 1 ns;
    wait for 20 ns;
    waddr   <= x"D100";
    wdata   <= x"00000001";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D104";
    wdata   <= x"00000004";
    wupdate <= '1';
    wait for 10 ns;
    --expert write:
    waddr   <= x"D1E0";
    wdata   <= x"FFFFFFFF";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D108";
    wdata   <= x"A0000000";
    wupdate <= '1';
    wait for 100 ns;
    waddr   <= x"D100"; 
    wdata   <= x"000000FF";
    wupdate <= '1';
    wait for 50 ns;
    waddr   <= x"D100";
    wdata   <= x"EEEEEEEE";
    wupdate <= '1';
    wait for 50 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';
    wait;
  end process;

  
  rapid_read_process : process
  begin
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 40 ns;
    raddr   <= x"D10C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D100";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D104";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D110";
    rupdate <= '1';
    wait for 100 ns;
    raddr   <= x"D100";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D10C";
    rupdate <= '1';
    wait for 30 ns;
    raddr   <= x"D1FF";
    rupdate <= '1';    
    wait for 10 ns;    
    raddr   <= x"D108";
    rupdate <= '1';    
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait;
  end process;
end behaviour;
