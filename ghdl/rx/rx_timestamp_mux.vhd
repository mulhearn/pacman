library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- rx_timestamp_mux:

entity rx_timestamp_mux is
  port (
    -- clock and active-high reset:
    CLK_I       : in std_logic;
    RST_I       : in std_logic;

    -- channel selection for A and B outputs:
    SEL_I       : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);

    -- incoming data:
    TIMESTAMP_I : in  rx_timestamp_array_t;

    -- selected output:
    TIMESTAMP_O : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
  );
end;

architecture behavioral of rx_timestamp_mux is
  signal clk       : std_logic;
  signal rst       : std_logic;

  signal timestamp : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
begin
  clk <= CLK_I;
  rst <= RST_I;


  timestamp <= (others => '0') when to_integer(unsigned(SEL_I)) >= C_RX_NUM_CHAN
            else TIMESTAMP_I(to_integer(unsigned(SEL_I)));

  process(clk, rst)
  begin
    if rst = '1' then
      TIMESTAMP_O  <= (others => '0');
    elsif rising_edge(clk) then
      TIMESTAMP_O  <= timestamp;
    end if;
  end process;

end;
