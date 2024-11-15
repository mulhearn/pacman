library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package register_map is

  -- Top Level SCOPE (4 - bits)
  constant C_SCOPE_GLOBAL  : integer := 2#1111#;
  constant C_SCOPE_UART_TX : integer := 2#00#;   -- UART_TX = 00XX
  constant C_SCOPE_UART_RX : integer := 2#01#;   -- UART_RX = 01XX 

  -- ROLES (next 4-bits) within the GLOBAL SCOPE:
  constant C_ROLE_GLOBAL   : integer := 2#1111#;
  constant C_ROLE_TIMING   : integer := 2#1110#; 
  constant C_ROLE_ADC      : integer := 2#1101#;

  -- Registers with SCOPE=GLOBAL ROLE=GLOBAL
  constant C_ADDR_GLOBAL_SCRA      : integer := 16#00#;
  constant C_ADDR_GLOBAL_SCRB      : integer := 16#04#;

  constant C_ADDR_GLOBAL_FW_MAJOR  : integer := 16#10#; -- Read Only
  constant C_ADDR_GLOBAL_FW_MINOR  : integer := 16#14#; -- Read Only
  constant C_ADDR_GLOBAL_FW_BUILD  : integer := 16#18#; -- Read Only
  constant C_ADDR_GLOBAL_HW_CODE   : integer := 16#1C#; -- Read Only

  constant C_ADDR_GLOBAL_ENABLES   : integer := 16#20#;

  -- Registers with SCOPE=GLOBAL ROLE=TIMING
  constant C_ADDR_TIMING_STATUS    : integer := 16#00#;
  constant C_ADDR_TIMING_STAMP     : integer := 16#04#;
  constant C_ADDR_TIMING_TRIG      : integer := 16#20#;
  constant C_ADDR_TIMING_SYNC      : integer := 16#24#;

  -- Registers with SCOPE=UART_RX

  -- RX Unit Registers --
  constant C_ADDR_RX_STATUS     : integer := 16#00#;
  constant C_ADDR_RX_CONFIG     : integer := 16#04#;
  
  -- 128 RX register (LSB) A B C D (MSB) 
  constant C_ADDR_RX_LOOK_A     : integer := 16#10#;
  constant C_ADDR_RX_LOOK_B     : integer := 16#14#;
  constant C_ADDR_RX_LOOK_C     : integer := 16#18#;
  constant C_ADDR_RX_LOOK_D     : integer := 16#1C#;
  
  -- Counters: (Zero by writing ZERO_CNTS register on global channel 0x7F)
  constant C_ADDR_RX_STARTS     : integer := 16#20#; -- count busy '0'->'1'
  constant C_ADDR_RX_BEATS      : integer := 16#24#; -- count valid='1' & ready='1'
  constant C_ADDR_RX_UPDATES    : integer := 16#28#; -- count update='1'
  constant C_ADDR_RX_LOST       : integer := 16#2C#; -- count lost='1'
  
  -- Channel number (loopback test of channel id)
  constant C_ADDR_RX_NCHAN      : integer := 16#50#;

  -- Global Status and Flags
  constant C_ADDR_RX_GSTATUS    : integer := 16#A0#;
  constant C_ADDR_RX_GCONFIG    : integer := 16#A4#;
  constant C_ADDR_RX_ZERO_CNTS  : integer := 16#A8#;
  
  -- FIFO counters (only via global channel 0x7F) from AXI Stream DATA FIFO
  constant C_ADDR_RX_FRCNT      : integer := 16#B0#;
  constant C_ADDR_RX_FWCNT      : integer := 16#B4#; 
  -- DMA Interrupt bit (S2MM)
  constant C_ADDR_RX_DMAITR     : integer := 16#B8#;

  -- Heartbeat and Sync Config registers
  constant C_ADDR_RX_HEARTBEAT_CYCLES  : integer := 16#C0#;
  constant C_ADDR_RX_SYNC_CYCLES       : integer := 16#C4#; 
  
  -- Registers with SCOPE=UART_TX
  -- TODO:  needs sync with RX registers, e.g. GSTATUS.

  constant C_ADDR_TX_STATUS   : integer := 16#00#;
  constant C_ADDR_TX_CONFIG   : integer := 16#04#; 
  -- 64 RX register (LSB) C D (MSB) -- 
  constant C_ADDR_TX_LOOK_C   : integer := 16#18#;
  constant C_ADDR_TX_LOOK_D   : integer := 16#1C#; 
  constant C_ADDR_TX_GFLAGS   : integer := 16#20#; 
  constant C_ADDR_TX_STARTS   : integer := 16#30#;

  -- Channel number (loopback test of channel id)
  constant C_ADDR_TX_NCHAN    : integer := 16#50#;

end package register_map;
