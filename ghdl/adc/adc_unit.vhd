library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_unit is
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
end adc_unit;

architecture behavioral of adc_unit is
  component adc_reg is
    port(
      ACLK	             : in std_logic;
      ARESETN	             : in std_logic;

      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;
      
      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      CONFIG_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CLKPAR_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_I            : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LAST_I              : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LOOK_I              : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  signal config    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal clkpar    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');  
  signal status    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal last      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal look      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

begin
  ADC_CLK_O <= ACLK;
  ADC_EN_O  <= '1';
  
  BRAM_EN_O   <= '0';
  BRAM_DATA_O <= x"ABCD1234";
  BRAM_WEN_O  <= (others => '1');
  BRAM_ADDR_O <= (others => '0');
  BRAM_CLK_O  <= ACLK;
  BRAM_RST_O  <= '0';

  look(ADC_DATA_WIDTH-1 downto 0) <= ADC_DATA_I;
  look(ADC_DATA_WIDTH) <= ADC_DOF_I;
  
  registers: ADC_reg port map (
      ACLK           => ACLK,
      ARESETN        => ARESETN,
      S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
      S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
      S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
      S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
      S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
      S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
      S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
      S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,

      CONFIG_O => config,
      CLKPAR_O => clkpar,
      STATUS_I => status,
      LAST_I   => last,
      LOOK_I   => look
      );


end behavioral;
