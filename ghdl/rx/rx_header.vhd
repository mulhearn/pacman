library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- rx_header: create an RX header based on configurable parameters and snooping
--   inside the LArPix payload for the packet descriptor.

entity rx_header is
  port (
    -- clock and active-high reset:
    CLK_I        : in std_logic;
    RST_I        : in std_logic;

    -- configurable PACMAN id:
    PACMAN_I           : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- configuration register for this module:
    LUT_I              : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- UART channel array (configurable):
    CHAN_I             : in uart_reg_array_t;
    DATA_I             : in uart_data_array_t;

    -- outgoing (modified) headers:
    HEADER_O           : out uart_reg_array_t;

-- debugging:
    DEBUG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
end;

architecture behavioral of rx_header is
  signal clk       : std_logic;
  signal rst       : std_logic;
  type lut_t is array(0 to 3) of std_logic_vector(7 downto 0);
  signal lut       : lut_t;
  signal data      : uart_data_array_t := (others => (others => '0'));
begin
  lut(0) <= LUT_I(7  downto 0);
  lut(1) <= LUT_I(15 downto 8);
  lut(2) <= LUT_I(23 downto 16);
  lut(3) <= LUT_I(31 downto 24);

  data <= DATA_I when RST_I = '0' else (others => (others => '0'));

  -- HEADER FORMAT:  0xWWUUUUPP  -- W=word, U=chan, P=PACMAN
  gheader0: for i in 0 to C_NUM_UART-1 generate
    HEADER_O(i)(7 downto 0) <= lut(to_integer(unsigned(data(i)(1 downto 0))));
    HEADER_O(i)(23 downto 8)  <= CHAN_I(i)(15 downto 0);
    HEADER_O(i)(31 downto 24) <= PACMAN_I(7 downto 0);
  end generate gheader0;

end;
