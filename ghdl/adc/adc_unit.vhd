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

    -- Data Ports
    DATA_I              : in  std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
    DOF_I               : in  std_logic;
    DATA_O              : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    BRAM_ADDR_O         : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    WEN_O               : out std_logic;

    -- ADC Ports
    ADC_EN_O            : out std_logic;
    ADC_CLK_O           : out std_logic   
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

      TRIG_MODE              : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CLK_DIV                : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ADC_EN                 : out std_logic;
      LAST_W                 : in  std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
      );
  end component;

  component ADC_DAQ is
    port(
      ACLK      : in std_logic;
      ARESETN   : in std_logic;

      DATA_IN   : in std_logic_vector(11 downto 0);
      DOF_IN    : in std_logic;

      TRIG_MODE : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      DATA_OUT  : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

      ADDR      : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
      WEN       : out std_logic;
    
      LAST_W    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
      );
  end component;

  component ADC_CLK_DIV is
    port(
      ACLK    : in std_logic;
      CLK_DIV : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ARESETN : in std_logic;

      ADC_CLK : out std_logic
    );
  end component;

  signal last_w    : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal trig_mode : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal clk_div   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  begin
  registers: ADC_reg port map (
      TRIG_MODE      => trig_mode,
      CLK_DIV        => clk_div,
      LAST_W         => last_w,
      ADC_EN         => ADC_EN_O,
      ACLK           => ACLK,
      ARESETN        => ARESETN,
      S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
      S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
      S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
      S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
      S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
      S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
      S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
      S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK
      );

  data: ADC_DAQ port map (
      TRIG_MODE      => trig_mode,
      ACLK           => ACLK,
      ARESETN        => ARESETN,
      LAST_W         => last_w,

      DATA_IN        => DATA_I,
      DOF_IN         => DOF_I,
      DATA_OUT       => DATA_O,
      ADDR           => BRAM_ADDR_O,
      WEN            => WEN_O
      );

  clock: ADC_CLK_DIV port map (
    ACLK => ACLK,
    ARESETN => ARESETN,
    CLK_DIV => clk_div,
    ADC_CLK => ADC_CLK_O
  );
end behavioral;
