library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package register_map is

  -- Top Level SCOPE (4 - bits)
  constant C_SCOPE_GLOBAL   : integer := 2#1111#; -- GLOBAL = 0xF = 0b1111
  constant C_SCOPE_TIMING   : integer := 2#1110#; -- TIMING = 0xE = 0b1110
  constant C_SCOPE_ADC      : integer := 2#1110#; -- ADC    = 0xD = 0b1101
  constant C_SCOPE_UPPER_TX : integer := 2#00#;   -- TX     =     = 0b00XX
  constant C_SCOPE_UPPER_RX : integer := 2#01#;   -- RX     =     = 0b01XX

  --
  -- Registers with SCOPE=GLOBAL
  --
  constant C_ADDR_GLOBAL_STATUS          : integer := 16#000#; -- Read Only
  constant C_ADDR_GLOBAL_ENABLES         : integer := 16#010#;
  constant C_ADDR_GLOBAL_LEDS            : integer := 16#014#;
  constant C_ADDR_GLOBAL_SCRATCH_A       : integer := 16#020#;
  constant C_ADDR_GLOBAL_SCRATCH_B       : integer := 16#024#;
  constant C_ADDR_GLOBAL_FIRMWARE_MAJOR  : integer := 16#F10#; -- Read Only
  constant C_ADDR_GLOBAL_FIRMWARE_MINOR  : integer := 16#F14#; -- Read Only
  constant C_ADDR_GLOBAL_FIRMWARE_LETTER : integer := 16#F18#; -- Read Only
  constant C_ADDR_GLOBAL_HARDWARE_MAJOR  : integer := 16#F20#; -- Read Only
  constant C_ADDR_GLOBAL_HARDWARE_MINOR  : integer := 16#F24#; -- Read Only
  constant C_ADDR_GLOBAL_HARDWARE_LETTER : integer := 16#F28#; -- Read Only
  constant C_ADDR_GLOBAL_SYNTHESIS_DATE  : integer := 16#F30#; -- Read Only
  constant C_ADDR_GLOBAL_GIT_HASH_UPPER  : integer := 16#F40#; -- Read Only
  constant C_ADDR_GLOBAL_GIT_HASH_LOWER  : integer := 16#F44#; -- Read Only
  constant C_ADDR_GLOBAL_VIVADO_MAJOR    : integer := 16#F50#; -- Read Only
  constant C_ADDR_GLOBAL_VIVADO_MINOR    : integer := 16#F54#; -- Read Only
  --
  -- Registers with SCOPE=UART_TX
  --
  constant C_ADDR_TX_UART_STATUS    : integer := 16#00#; -- Read Only
  constant C_ADDR_TX_UART_CONFIG    : integer := 16#04#; -- Read Only
  -- 64-bit RX register as two 32-bit words (LSB) A B C D (MSB)
  constant C_ADDR_TX_UART_LOOK_A    : integer := 16#10#; -- Read Only
  constant C_ADDR_TX_UART_LOOK_B    : integer := 16#14#; -- Read Only
  -- Counters: (Zero by writing ZERO_CNTS register on global channel 0x7F)
  constant C_ADDR_TX_UART_STARTS    : integer := 16#20#;
  constant C_ADDR_TX_UART_BEATS     : integer := 16#24#; -- count valid='1' & ready='1'

  -- Global Status and Flags
  constant C_ADDR_TX_BUFFER_STATUS  : integer := 16#A0#;
  constant C_ADDR_TX_ZERO_CNTS      : integer := 16#B8#;

  --
  -- Registers with SCOPE=UART_RX
  -- Per UART registers, with chan = 0x00-0x28, and broadcast chan=0x3B (if writable):
  --
  constant C_ADDR_RX_UART_STATUS    : integer := 16#00#; -- Read Only
  constant C_ADDR_RX_UART_CONFIG    : integer := 16#04#;
  constant C_ADDR_RX_UART_CHAN      : integer := 16#08#;
  -- 128-bit RX register as four 32-bit words (LSB) A B C D (MSB)
  constant C_ADDR_RX_UART_LOOK_A    : integer := 16#10#; -- Read Only
  constant C_ADDR_RX_UART_LOOK_B    : integer := 16#14#; -- Read Only

  -- Counters: (Zero by writing ZERO_CNTS register on global channel 0x7F)
  constant C_ADDR_RX_UART_STARTS    : integer := 16#20#; -- count busy '0'->'1'
  constant C_ADDR_RX_UART_BEATS     : integer := 16#24#; -- count valid='1' & ready='1'
  constant C_ADDR_RX_UART_UPDATES   : integer := 16#28#; -- count update='1'
  constant C_ADDR_RX_UART_LOST      : integer := 16#2C#; -- count lost='1'

  --
  -- Registers with SCOPE=UART_RX
  -- Not UART specific, at chan=0x3F:
  --

  -- RX buffer status, config, and enables:
  constant C_ADDR_RX_BUFFER_STATUS  : integer := 16#A0#; -- Read Only
  constant C_ADDR_RX_BUFFER_CONFIG  : integer := 16#A4#;
  constant C_ADDR_RX_BUFFER_ENABLES : integer := 16#A8#;

  -- PACMAN ID:
  constant C_ADDR_RX_PACMAN        : integer := 16#AC#;

  -- FIFO counters from AXI Stream DATA FIFO
  constant C_ADDR_RX_FIFO_CNT  : integer := 16#B0#;
  constant C_ADDR_RX_FIFO_MAX  : integer := 16#B4#;
  constant C_ADDR_RX_ZERO_CNTS : integer := 16#B8#;


  -- Heartbeat and Sync Config regisiters
  constant C_ADDR_RX_HEARTBEAT_CONFIG : integer := 16#C0#;
  constant C_ADDR_RX_ROLLOVER_CONFIG  : integer := 16#C4#;
  -- LUT mapping 2-bit packet descriptor to one byte header field:
  constant C_ADDR_RX_WORD_TYPE_LUT    : integer := 16#C8#;

  constant C_ADDR_RX_HEARTBEAT_HEADER : integer := 16#D0#;
  constant C_ADDR_RX_ROLLOVER_HEADER  : integer := 16#D4#;
  constant C_ADDR_RX_TRIG_HEADER      : integer := 16#D8#; -- not yet implemented
  constant C_ADDR_RX_EOP_HEADER       : integer := 16#DC#;

  -- Registers with SCOPE=TIMING ROLE(2 bits)=CFG, COUNTER, REGULAR
  constant C_TIMING_REGULAR : integer := 16#0#;
  constant C_TIMING_COUNTER : integer := 16#2#;
  constant C_TIMING_CFG     : integer := 16#4#;

  constant C_ADDR_TIMING_STATUS : integer := 16#00#;
  constant C_ADDR_TIMING_STAMP  : integer := 16#04#;
  constant C_ADDR_ATC_POKE_C    : integer := 16#10#;
  constant C_ADDR_ATC_POKE_D    : integer := 16#14#;
  CONSTANT C_ADDR_COUNT_START   : integer := 16#B0#;
  CONSTANT C_ADDR_COUNT_STOP    : integer := 16#B4#;
  CONSTANT C_ADDR_COUNT_RESET   : integer := 16#B8#;

  --F(fast clock domain)
  constant C_ADDR_LEMO_A_F : integer := 16#20#;
  constant C_ADDR_LEMO_B_F : integer := 16#24#;
  --S(slow)
  constant C_ADDR_LEMO_A_S : integer := 16#30#;
  constant C_ADDR_LEMO_B_S : integer := 16#34#;
  constant C_ADDR_POKE_C_S : integer := 16#38#;
  constant C_ADDR_POKE_D_S : integer := 16#3C#;


  constant C_ADDR_ATC_POLARITY : integer := 16#40#;
  constant C_ADDR_ATC_TS       : integer := 16#44#;
  constant C_ADDR_ATC_G_START  : integer := 16#50#;
  constant C_ADDR_ATC_G_END    : integer := 16#74#;

  constant C_ADDR_ATC_H_START  : integer := 16#80#;
  constant C_ADDR_ATC_H_END    : integer := 16#A4#;

end package register_map;
