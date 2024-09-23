library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package register_map is

  -- Lower (8-BIT) Offset Registers (R = 0bRRRRRRRR)

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
  constant C_ADDR_RX_GFLAGS     : integer := 16#A4#;
  constant C_ADDR_RX_ZERO_CNTS  : integer := 16#A8#;
  
  -- FIFO counters (only via global channel 0x7F) from AXI Stream DATA FIFO
  constant C_ADDR_RX_FRCNT      : integer := 16#B0#;
  constant C_ADDR_RX_FWCNT      : integer := 16#B4#; 
  -- DMA Interrupt bit (S2MM)
  constant C_ADDR_RX_DMAITR     : integer := 16#B8#;

  -- TX Unit Registers --
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
