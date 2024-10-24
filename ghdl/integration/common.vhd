library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is

  constant C_NUM_TILE          : integer  := 10;
  constant C_NUM_UART          : integer  := 40;

  constant C_TIMESTAMP_WIDTH   : integer  := 32;

  -- register bus data is 32 bits, address 16 bits.
  constant C_RB_DATA_WIDTH       : integer  := 32;
  constant C_RB_ADDR_WIDTH       : integer  := 16;

  -- DMA stream data widths:
  constant C_TX_AXIS_WIDTH     : integer    := 128;
  constant C_TX_AXIS_BEATS     : integer    := 21;
  constant C_RX_AXIS_WIDTH     : integer    := 128;

  constant C_UART_DATA_WIDTH   : integer  := 64;
  constant C_TX_DATA_WIDTH     : integer  := C_UART_DATA_WIDTH;
  constant C_TX_NUM_CHAN       : integer  := C_NUM_UART;
  constant C_RX_DATA_WIDTH     : integer  := 2*C_UART_DATA_WIDTH;
  constant C_RX_EXTRA_CHAN     : integer  := 4;
  constant C_RX_NUM_CHAN       : integer  := C_NUM_UART + C_RX_EXTRA_CHAN;
  constant C_RX_TURN_MAX       : integer  := 64;
  constant C_RX_BEAT_MAX       : integer  := 32;

  --arrays of std_logic_vectors with array length the number of uart channels:
  type uart_reg_array_t       is array (0 to C_NUM_UART-1) of std_logic_vector (C_RB_DATA_WIDTH-1 downto 0);
  type uart_tx_data_array_t   is array (0 to C_TX_NUM_CHAN-1) of std_logic_vector (C_TX_DATA_WIDTH-1 downto 0);
  type uart_rx_data_array_t   is array (0 to C_RX_NUM_CHAN-1) of std_logic_vector (C_RX_DATA_WIDTH-1 downto 0);

  -- uart counter arrays that roll over at C_COUNT_MAX:
  constant C_COUNT_MAX           : integer  := 16#10000#;
  type uart_counter_array_t is array (0 to C_NUM_UART-1) of integer range 0 to C_COUNT_MAX;

  -- default TX / RX config register (full 32 bits):
  constant C_DEFAULT_CONFIG_TX : integer := 16#00001602#;
  constant C_DEFAULT_CONFIG_RX : integer := 16#00001002#;

  constant C_DEFAULT_HEARTBEAT_CYCLES : integer := 16#3b9aca00#;
  constant C_DEFAULT_SYNC_CYCLES      : integer := 16#1#;

  constant C_TX_GFLAGS_WIDTH : integer  := 2;
  constant C_RX_GFLAGS_WIDTH : integer  := 2;

  constant C_BYTE            : integer  := 8;

end package common;
