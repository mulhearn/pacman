library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity global_unit is
  port (
    ACLK                 : in std_logic;
    ARESETN              : in std_logic;

    S_REGBUS_RB_RADDR	 : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	 : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RUPDATE  : in  std_logic;
    S_REGBUS_RB_RACK     : out std_logic;

    S_REGBUS_RB_WUPDATE  : in  std_logic;
    S_REGBUS_RB_WADDR	 : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	 : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK     : out std_logic;

    ANALOG_PWR_EN_O      : out std_logic;
    TILE_EN_O            : out std_logic_vector(C_NUM_TILE-1 downto 0);
    ADC_EN_O             : out std_logic;
    LED_O                : out std_logic_vector(C_NUM_LED-1 downto 0)
  );
end global_unit;

architecture behaviour of global_unit is
  component global_registers is
    port (
      ACLK	        : in std_logic;
      ARESETN	        : in std_logic;

      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;

      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      ANALOG_PWR_EN_O        : out std_logic;
      TILE_EN_O              : out std_logic_vector(C_NUM_TILE-1 downto 0);
      ADC_EN_O               : out std_logic;

      LED_CONFIG_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      GLOBAL_STATUS_I        : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  component global_status is
    port (
      ACLK	          : in std_logic;
      ARESETN	          : in std_logic;

      LED_CONFIG_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      GLOBAL_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      LED_O               : out std_logic_vector(C_NUM_LED-1 downto 0)
    );
  end component;

  --signal analog_pwr_en  : std_logic;
  --signal adc_en         : std_logic;
  --signal tile_en        : std_logic_vector(C_NUM_TILE-1 downto 0);
  signal status         : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal led_config     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  --signal leds           : std_logic_vector(C_NUM_LED-1 downto 0) := (others => '0');

begin
  gr0: global_registers port map (
    ACLK           => aclk,
    ARESETN        => aresetn,
        S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
    S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
    S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
    S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
    S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
    S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
    S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
    S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,
    ANALOG_PWR_EN_O     => ANALOG_PWR_EN_O,
    TILE_EN_O           => TILE_EN_O,
    ADC_EN_O            => ADC_EN_O,
    GLOBAL_STATUS_I     => status,
    LED_CONFIG_O        => led_config
    );

  gs0: global_status port map (
    ACLK             => aclk,
    ARESETN          => aresetn,
    LED_CONFIG_I     => led_config,
    GLOBAL_STATUS_O  => status,
    LED_O            => LED_O
  );


end behaviour;
