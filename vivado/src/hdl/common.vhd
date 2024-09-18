library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is
  
  constant C_BYTE                : integer  := 8;
  constant C_COMMAND_WIDTH       : integer  := 8;

  -- register bus data is 32 bits, address 16 bits.
  constant C_RB_DATA_WIDTH       : integer  := 32;
  constant C_RB_ADDR_WIDTH       : integer  := 16;

  -- DMA stream data widths:
  constant C_TX_AXIS_WIDTH     : integer    := 512;
  constant C_TX_AXIS_BEATS     : integer    := 5;
  constant C_RX_AXIS_WIDTH     : integer    := 128;
  
  constant C_NUM_UART              : integer  := 40;
  constant C_UART_DATA_WIDTH       : integer  := 64;
  constant C_TX_CHAN_DATA_WIDTH    : integer  := C_UART_DATA_WIDTH;
  constant C_RX_CHAN_DATA_WIDTH    : integer  := 128;
  constant C_UART_CHAN_ADDR_WIDTH  : integer  := 6;
  constant C_UART_BROADCAST        : integer  := 16#3F#;
  constant C_TX_CHAN_COUNT_WIDTH   : integer  := 3*C_RB_DATA_WIDTH;
  constant C_RX_CHAN_COUNT_WIDTH   : integer  := 4*C_RB_DATA_WIDTH;
    
  --arrays of std_logic_vectors with array length the number of uart channels:
  type uart_reg_array_t       is array (0 to C_NUM_UART-1) of std_logic_vector (C_RB_DATA_WIDTH-1 downto 0);
  type uart_tx_data_array_t   is array (0 to C_NUM_UART-1) of std_logic_vector (C_TX_CHAN_DATA_WIDTH-1 downto 0);
  type uart_rx_data_array_t   is array (0 to C_NUM_UART-1) of std_logic_vector (C_RX_CHAN_DATA_WIDTH-1 downto 0);
  type uart_tx_count_array_t  is array (0 to C_NUM_UART-1) of std_logic_vector (C_TX_CHAN_COUNT_WIDTH-1 downto 0);
  type uart_rx_count_array_t  is array (0 to C_NUM_UART-1) of std_logic_vector (C_RX_CHAN_COUNT_WIDTH-1 downto 0);
  type uart_command_array_t   is array (0 to C_NUM_UART-1) of std_logic_vector (C_COMMAND_WIDTH-1 downto 0);

  -- subset of TX/RX config register consumed by UART:
  constant C_TX_BUFFER_CONFIG_WIDTH : integer  := 12;  -- (11-PHASE-8) (7-RATIO-0)
  constant C_RX_BUFFER_CONFIG_WIDTH : integer  := 12;  -- (11-PHASE-8) (7-RATIO-0)
  -- default TX / RX config register (full 32 bits):
  constant C_DEFAULT_CONFIG_TX : integer := 16#00000601#;
  constant C_DEFAULT_CONFIG_RX : integer := 16#00000001#;
  
end package common;
