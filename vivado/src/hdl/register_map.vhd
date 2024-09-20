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
  constant C_ADDR_RX_COMMAND    : integer := 16#20#;
  -- Counters (via start/stop command)
  constant C_ADDR_RX_CYCLES     : integer := 16#30#;
  constant C_ADDR_RX_BUSYS      : integer := 16#34#;
  constant C_ADDR_RX_ACKS       : integer := 16#38#;
  constant C_ADDR_RX_LOSTS      : integer := 16#3C#;
  -- Channel number (loopback test of channel id)
  constant C_ADDR_RX_NCHAN      : integer := 16#40#;

  
  -- TX Unit Registers --
  constant C_ADDR_TX_STATUS   : integer := 16#00#;
  constant C_ADDR_TX_CONFIG   : integer := 16#04#; 
  -- 64 RX register (LSB) C D (MSB) -- 
  constant C_ADDR_TX_LOOK_C   : integer := 16#18#;
  constant C_ADDR_TX_LOOK_D   : integer := 16#1C#; 
  constant C_ADDR_TX_GFLAGS   : integer := 16#20#; 
  constant C_ADDR_TX_STARTS   : integer := 16#30#;

  -- Channel number (loopback test of channel id)
  constant C_ADDR_TX_NCHAN    : integer := 16#40#;



end package register_map;
