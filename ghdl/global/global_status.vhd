library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.version.all;
use work.common.all;
use work.register_map.all;

entity global_status is
  port (
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;


    LED_CONFIG_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    GLOBAL_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    LED_O               : out std_logic_vector(C_NUM_LED-1 downto 0)
    );
end;

architecture behavioral of global_status is
  signal clk      : std_logic;
  signal rst      : std_logic;

begin
  -- Clock and reset inputs:
  clk <= ACLK;
  rst <= not ARESETN;

  -- simplest implementation:
  LED_O            <= LED_CONFIG_I(C_NUM_LED-1 downto 0);
  GLOBAL_STATUS_O  <= x"0000CAFE";
end;
