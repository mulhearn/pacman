library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is

  -- register bus data is 32 bits, address 16 bits.
  constant C_RB_ADDR_WIDTH       : integer  := 16;
  constant C_RB_DATA_WIDTH       : integer  := 32;

  -- DEPRECATE:
  constant C_BYTE                : integer  := 8;   --deprecate for C_BYTE_WIDTH
  constant C_SMALL               : integer  := 16;  --deprecate for C_REG16
  constant C_SELECT_WIDTH        : integer  := 6;   --deprecate for C_UART_SELECT_WIDTH
  constant C_UART_DATA_WIDTH     : integer  := 64;  --deprecate for C_UART64
  --deprecate for uart_reg16_array_t:
  type uart_small_array_t     is array (0 to 39) of std_logic_vector (15 downto 0);

  -- maximum AXI-lite register size is 32-bits, but we provide smaller opitions:
  constant C_REG32_WIDTH         : integer  := 32;
  constant C_ADDR16_WIDTH        : integer  := 16;
  constant C_REG16_WIDTH         : integer  := 16;
  constant C_BYTE_WIDTH          : integer  := 8;

  -- the UART data packet size from ASIC design is 64-bits:
  constant C_UART64              : integer  := 64;

  -- maximum number of tile cards supported by firmware:
  constant C_NUM_TILE            : integer  := 10;
  -- maximum number of UART channels supported:
  constant C_NUM_UART            : integer  := 40;
  -- maximum number of LEDSs supported:
  constant C_NUM_LED             : integer  := 2;
  -- number bits needed for UART channel selection:
  constant C_UART_SELECT_WIDTH   : integer  := 6;


  --arrays of std_logic_vectors with array length the number of uart channels:
  type uart_reg_array_t       is array (0 to C_NUM_UART-1) of std_logic_vector (C_RB_DATA_WIDTH-1 downto 0);
  type uart_reg16_array_t     is array (0 to C_NUM_UART-1) of std_logic_vector (C_REG16_WIDTH-1 downto 0);
  type uart_data_array_t      is array (0 to C_NUM_UART-1) of std_logic_vector (C_UART_DATA_WIDTH-1 downto 0);

  constant C_ATC_COUNT_SELECT_WIDTH : integer := 5;

  -- TX unit:
  -- DMA stream width and number of beats
  constant C_TX_AXIS_WIDTH     : integer  := 64;
  constant C_TX_AXIS_BEATS     : integer  := 41;

  -- RX unit:
  -- DMA stream width
  constant C_RX_AXIS_WIDTH     : integer  := 64;
  constant C_TIMESTAMP_WIDTH   : integer  := 64;

  -- number of fragments per turn (first is a pause):
  constant C_RX_FRAGS_PER_TURN : integer  := 3;
  constant C_RX_EXTRA_CHAN     : integer  := 4;
  constant C_RX_NUM_CHAN       : integer  := C_NUM_UART + C_RX_EXTRA_CHAN;


  --type rx_header_array_t      is array (0 to C_RX_NUM_CHAN-1) of std_logic_vector (C_RX_HEADER_WIDTH-1 downto 0);
  type rx_data_array_t        is array (0 to C_RX_NUM_CHAN-1) of std_logic_vector (C_UART_DATA_WIDTH-1 downto 0);
  type rx_timestamp_array_t   is array (0 to C_RX_NUM_CHAN-1) of std_logic_vector (C_TIMESTAMP_WIDTH-1 downto 0);


  --arrays of std_logic_vectors with array length the number of tiles:
  type ATC_array              is array (0 to C_NUM_TILE-1) of std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  -- uart counter arrays (16 bit) that saturate at 0xFFFF:
  constant C_COUNT_BITS : integer := 16;
  constant C_COUNT_MAX  : unsigned := x"FFFF";
  type uart_counter_array_t is array (0 to C_NUM_UART-1) of unsigned(C_COUNT_BITS-1 downto 0);

  -- default TX / RX config register (can be set per UART channel)
  constant C_DEFAULT_TX_UART_CONFIG : integer := 16#00001602#;
  constant C_DEFAULT_RX_UART_CONFIG : integer := 16#00001002#;

  -- default TX / RX global config register (one global setting)
  constant C_DEFAULT_TX_BUFFER_CONFIG     : integer := 16#00000000#;
  constant C_DEFAULT_RX_BUFFER_CONFIG     : integer := 16#00000001#;
  constant C_DEFAULT_RX_WORD_TYPE_LUT     : integer := 16#44444444#;
  constant C_DEFAULT_RX_HEARTBEAT_CONFIG  : integer := 16#3b9aca00#;
  constant C_DEFAULT_RX_HEARTBEAT_HEADER  : integer := 16#00480053#;
  constant C_DEFAULT_RX_ROLLOVER_CONFIG   : integer := 16#1#;
  constant C_DEFAULT_RX_ROLLOVER_HEADER   : integer := 16#00530053#;
  constant C_DEFAULT_RX_EOP_HEADER        : integer := 16#0000004C#;


  constant BRAM_ADDR_WIDTH     : integer  := 13;
  constant ADC_DATA_WIDTH      : integer  := 12;
  constant BRAM_DATA_WIDTH     : integer  := 32;




  function bitwise_or(vec : std_logic_vector) return std_logic;

end package common;

package body common is
  function bitwise_or(vec : std_logic_vector) return std_logic is
  begin
    for i in vec'range loop
      if vec(i) = '1' then
        return '1';
      end if;
    end loop;
    return '0';
  end function;
end package body common;
