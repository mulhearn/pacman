library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is
  
  constant C_BYTE                : integer  := 8;

  -- register bus data is 32 bits, address 16 bits.
  constant C_RB_DATA_WIDTH       : integer  := 32;
  constant C_RB_ADDR_WIDTH       : integer  := 16;

  -- DMA stream data widths:
  constant C_TX_AXIS_WIDTH     : integer    := 128;
  constant C_TX_AXIS_BEATS     : integer    := 21;
  constant C_RX_AXIS_WIDTH     : integer    := 128;

  constant C_NUM_UART          : integer  := 40;
  constant C_UART_DATA_WIDTH   : integer  := 64;
  constant C_TX_DATA_WIDTH     : integer  := C_UART_DATA_WIDTH;
  constant C_RX_DATA_WIDTH     : integer  := 2*C_UART_DATA_WIDTH;

  --arrays of std_logic_vectors with array length the number of uart channels:
  type uart_reg_array_t       is array (0 to C_NUM_UART-1) of std_logic_vector (C_RB_DATA_WIDTH-1 downto 0);
  type uart_tx_data_array_t   is array (0 to C_NUM_UART-1) of std_logic_vector (C_TX_DATA_WIDTH-1 downto 0);
  type uart_rx_data_array_t   is array (0 to C_NUM_UART-1) of std_logic_vector (C_RX_DATA_WIDTH-1 downto 0);

  -- default TX / RX config register (full 32 bits):
  constant C_DEFAULT_CONFIG_TX : integer := 16#00001601#;
  constant C_DEFAULT_CONFIG_RX : integer := 16#00001001#;

  constant C_TX_GFLAGS_WIDTH : integer  := 2;


  
end package common;
