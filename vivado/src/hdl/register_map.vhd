library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package register_map is

  -- Top Level SCOPE (4 - bits)
  constant C_SCOPE_GLOBAL  : integer := 2#1111#; -- GLOBAL = 0xF = 0b1111
  constant C_SCOPE_TIMING  : integer := 2#1110#; -- TIMING = 0xE = 0b1110
  constant C_SCOPE_ADC     : integer := 2#1110#; -- ADC    = 0xD = 0b1101
  constant C_SCOPE_UART_TX : integer := 2#00#;   -- TX     =     = 0b00XX
  constant C_SCOPE_UART_RX : integer := 2#01#;   -- RX     =     = 0b01XX

  --
  -- Registers with SCOPE=GLOBAL
  --
  constant C_ADDR_GLOBAL_STATUS    : integer := 16#000#; -- Read Only
  constant C_ADDR_GLOBAL_ENABLES   : integer := 16#010#;
  constant C_ADDR_GLOBAL_LEDS      : integer := 16#014#;
  constant C_ADDR_GLOBAL_SCRA      : integer := 16#020#;
  constant C_ADDR_GLOBAL_SCRB      : integer := 16#024#;
  constant C_ADDR_GLOBAL_FW_MAJOR  : integer := 16#F10#; -- Read Only
  constant C_ADDR_GLOBAL_FW_MINOR  : integer := 16#F14#; -- Read Only
  constant C_ADDR_GLOBAL_FW_BUILD  : integer := 16#F18#; -- Read Only
  constant C_ADDR_GLOBAL_HW_CODE   : integer := 16#F1C#; -- Read Only

  --
  -- Registers with SCOPE=UART_TX
  --
  constant C_ADDR_TX_STATUS     : integer := 16#00#;
  constant C_ADDR_TX_CONFIG     : integer := 16#04#;
  -- 64-bit RX register as two 32-bit words (LSB) A B C D (MSB)
  constant C_ADDR_TX_LOOK_C     : integer := 16#18#;
  constant C_ADDR_TX_LOOK_D     : integer := 16#1C#;
  -- Counters: (Zero by writing ZERO_CNTS register on global channel 0x7F)
  constant C_ADDR_TX_STARTS     : integer := 16#20#; -- count busy '0'->'1'
  -- consider?
  --constant C_ADDR_TX_BEATS      : integer := 16#24#; -- count valid='1' & ready='1'

  -- Channel number (loopback test of channel id)
  constant C_ADDR_TX_NCHAN    : integer := 16#50#;

  -- Global Status and Flags
  constant C_ADDR_TX_GSTATUS    : integer := 16#A0#;
  constant C_ADDR_TX_ZERO_CNTS  : integer := 16#A8#;

  --
  -- Registers with SCOPE=UART_RX
  --

  constant C_ADDR_RX_STATUS     : integer := 16#00#;
  constant C_ADDR_RX_CONFIG     : integer := 16#04#;
  -- 128-bit RX register as four 32-bit words (LSB) A B C D (MSB)
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
  constant C_ADDR_RX_FCNT       : integer := 16#B0#;
  constant C_ADDR_RX_FMAX       : integer := 16#B4#;

  -- Heartbeat and Sync Config registers
  constant C_ADDR_RX_HB_CYC     : integer := 16#C0#;
  constant C_ADDR_RX_SYNC_CYC   : integer := 16#C4#;



  -- Registers with SCOPE=TIMING ROLE(2 bits)=CFG, COUNTER, REGULAR
  constant C_TIMING_REGULAR               : integer := 16#0#;
  constant C_TIMING_COUNTER               : integer := 16#2#;
  constant C_TIMING_CFG                   : integer := 16#4#;

  constant C_ADDR_TIMING_STATUS            : integer := 16#00#;
  constant C_ADDR_TIMING_STAMP             : integer := 16#04#;
  constant C_ADDR_ATC_POKE_C               : integer := 16#10#;
  constant C_ADDR_ATC_POKE_D               : integer := 16#14#;
  CONSTANT C_ADDR_COUNT_START              : integer := 16#B0#;
  CONSTANT C_ADDR_COUNT_STOP               : integer := 16#B4#;
  CONSTANT C_ADDR_COUNT_RESET              : integer := 16#B8#;

  --F(fast clock domain)
  constant C_ADDR_LEMO_A_F                 : integer := 16#20#;
  constant C_ADDR_LEMO_B_F                 : integer := 16#24#;
  --S(slow)
  constant C_ADDR_LEMO_A_S                 : integer := 16#30#;
  constant C_ADDR_LEMO_B_S                 : integer := 16#34#;
  constant C_ADDR_POKE_C_S                 : integer := 16#38#;
  constant C_ADDR_POKE_D_S                 : integer := 16#3C#;


  constant C_ADDR_ATC_POLARITY             : integer := 16#40#;
  constant C_ADDR_ATC_TS                   : integer := 16#44#;
  constant C_ADDR_ATC_G_START              : integer := 16#50#;
  constant C_ADDR_ATC_G_END                : integer := 16#74#;

  constant C_ADDR_ATC_H_START              : integer := 16#80#;
  constant C_ADDR_ATC_H_END                : integer := 16#A4#;


end package register_map;
