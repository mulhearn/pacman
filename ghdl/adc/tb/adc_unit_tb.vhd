library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

entity adc_unit_tb is
end adc_unit_tb;

architecture behaviour of adc_unit_tb is
  component adc_unit is
    port (
      ACLK	          : in std_logic;
      ARESETN	          : in std_logic;

      -- REGBUS Ports
      S_REGBUS_RB_RUPDATE : in  std_logic;
      S_REGBUS_RB_RADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      S_REGBUS_RB_RACK    : out std_logic;
    
      S_REGBUS_RB_WUPDATE : in  std_logic;
      S_REGBUS_RB_WADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK    : out std_logic;

      -- BRAM
      BRAM_EN_O           : out std_logic; 
      BRAM_DATA_O         : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
      BRAM_WEN_O          : out std_logic_vector(3 downto 0);
      BRAM_ADDR_O         : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
      BRAM_CLK_O          : out std_logic;
      BRAM_RST_O          : out std_logic;
    
      -- ADC
      ADC_EN_O            : out std_logic;
      ADC_CLK_O           : out std_logic;
      ADC_DATA_I          : in  std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
      ADC_DOF_I           : in  std_logic
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
  signal wen       : std_logic_vector(3 downto 0);
  signal addr      : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal do        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal di        : std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
  signal diof      : std_logic;

  -- adc
  signal adc_en    : std_logic;
  signal adc_clk   : std_logic;

begin
  uut: adc_unit port map (
    ADC_EN_O       => adc_en,
    ADC_CLK_O      => adc_clk,
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
    ADC_DATA_I          => di,
    ADC_DOF_I           => diof,
    BRAM_DATA_O         => do,
    BRAM_ADDR_O         => addr,
    BRAM_WEN_O          => wen
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


write_process : process
  begin
    wait for 1 ns;
    wait for 20 ns;
    waddr   <= x"D110";
    wdata   <= x"000000A1";
    wupdate <= '1';
    wait for 50 ns;
    waddr   <= x"D110";
    wdata   <= x"0ACE0FB0";
    wupdate <= '1';
    wait for 50 ns;
    waddr   <= x"D110"; 
    wdata   <= x"0DEAD1C1";
    wupdate <= '1';
    wait;
  end process;
  
  rapid_read_process : process
  begin
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 42 ns;
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
