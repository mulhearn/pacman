library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is

  constant C_NUM_TILE          : integer  := 10;
  constant C_NUM_UART          : integer  := 40;
  constant C_NUM_LED           : integer  := 2;

  constant BRAM_ADDR_WIDTH       : integer  := 13;
  constant ADC_DATA_WIDTH        : integer  := 12;
  constant BRAM_DATA_WIDTH       : integer  := 32;

  -- register bus data is 32 bits, address 16 bits.
  constant C_RB_DATA_WIDTH       : integer  := 32;
  constant C_RB_ADDR_WIDTH       : integer  := 16;

  -- DMA stream data widths:
  constant C_TX_AXIS_WIDTH     : integer    := 128;
  constant C_TX_AXIS_BEATS     : integer    := 21;
  constant C_RX_AXIS_WIDTH     : integer    := 128;

  constant C_UART_DATA_WIDTH   : integer    := 64;
  constant C_TIMESTAMP_WIDTH   : integer    := 64;
  constant C_RX_HEADER_WIDTH   : integer    := 16;

  constant C_RX_TURN_MAX       : integer  := 64;
  constant C_RX_EXTRA_CHAN     : integer  := 4;
  constant C_RX_NUM_CHAN       : integer  := C_NUM_UART + C_RX_EXTRA_CHAN;
  constant C_RX_BEAT_MAX       : integer  := 32;

  --arrays of std_logic_vectors with array length the number of tiles:
  type ATC_array              is array (0 to C_NUM_TILE-1) of std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  --arrays of std_logic_vectors with array length the number of uart channels:
  type uart_reg_array_t       is array (0 to C_NUM_UART-1) of std_logic_vector (C_RB_DATA_WIDTH-1 downto 0);
  type uart_data_array_t      is array (0 to C_NUM_UART-1) of std_logic_vector (C_UART_DATA_WIDTH-1 downto 0);

  type rx_header_array_t      is array (0 to C_RX_NUM_CHAN-1) of std_logic_vector (C_RX_HEADER_WIDTH-1 downto 0);
  type rx_data_array_t        is array (0 to C_RX_NUM_CHAN-1) of std_logic_vector (C_UART_DATA_WIDTH-1 downto 0);
  type rx_timestamp_array_t   is array (0 to C_RX_NUM_CHAN-1) of std_logic_vector (C_TIMESTAMP_WIDTH-1 downto 0);


  -- uart counter arrays that roll over at C_COUNT_MAX:
  constant C_COUNT_MAX           : integer  := 16#10000#;
  type uart_counter_array_t is array (0 to C_NUM_UART-1) of integer range 0 to C_COUNT_MAX;

  -- default TX / RX config register (can be set per UART channel)
  constant C_DEFAULT_TX_UART_CONFIG : integer := 16#00001602#;
  constant C_DEFAULT_RX_UART_CONFIG : integer := 16#00001002#;

  -- default TX / RX global config register (one global setting)
  constant C_DEFAULT_TX_BUFFER_CONFIG : integer := 16#00000000#;
  constant C_DEFAULT_RX_BUFFER_CONFIG : integer := 16#00000000#;

  constant C_DEFAULT_HEARTBEAT_CONFIG : integer := 16#3b9aca00#;
  constant C_DEFAULT_ROLLOVER_CONFIG  : integer := 16#1#;

  constant C_BYTE            : integer  := 8;

  constant C_TYPE_DATA       : integer  := 16#44#; -- ASCII D
  constant C_TYPE_EOP        : integer  := 16#45#; -- end of packet, ASCII E


end package common;
