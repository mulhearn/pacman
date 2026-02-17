library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;

-- global_status:  this module produces the global status and the LED output
--   in the current implementation, (1) each LED is set on or off via LED config,
--   and (2) the status is set to fixed value "0x0000CAFE"
--
-- in a future implementation, this module could receive unit level status bits, report them,
-- and set LED or LEDs appropriately.
--

entity global_status is
  port (
    CLK_I	        : in std_logic;
    RST_I	        : in std_logic;

    LED_CONFIG_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    GLOBAL_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    LED_O               : out std_logic_vector(C_NUM_LED-1 downto 0)
    );
end;

architecture behavioral of global_status is
  signal clk      : std_logic;
  signal rst      : std_logic;

begin
  -- clock and active-high reset:
  clk <= CLK_I;
  rst <= RST_I;

  -- simplest implementation:
  LED_O            <= LED_CONFIG_I(C_NUM_LED-1 downto 0);
  GLOBAL_STATUS_O  <= x"0000CAFE";
end;
