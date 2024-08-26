-- generic RS232 UART

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY uart_rx IS
   GENERIC (
      CLK_HZ     : INTEGER := 100000000;
      CLKIN_HZ   : INTEGER := 10000000;
      DATA_WIDTH : INTEGER := 64
      );
   PORT (
      CLK         : IN  STD_LOGIC;
      RST         : IN  STD_LOGIC;
      CLKIN_RATIO : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
      CLKIN_PHASE : in  STD_LOGIC_VECTOR (3 downto 0);
      -- UART RX
      RX          : IN  STD_LOGIC;
      -- received data
      busy        : OUT STD_LOGIC;
      data        : OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
      data_update : OUT STD_LOGIC;
      -- test signals
      TC          : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
      );
END ENTITY uart_rx;

ARCHITECTURE uart_rx_arch OF uart_rx IS

  CONSTANT CLK_LENGTH   : INTEGER := CLK_HZ / CLKIN_HZ;
  SIGNAL bit_length     : INTEGER RANGE CLK_LENGTH TO CLK_LENGTH * 255;
  SIGNAL cnt_bit_length : INTEGER RANGE -1 TO CLK_LENGTH * 255;
  SIGNAL cnt_bits       : INTEGER RANGE 0 TO DATA_WIDTH+2;
  SIGNAL delay_cnt      : INTEGER RANGE 0 TO 255;
  
  TYPE state_type IS (IDLE, DELAY, WT, SHIFT, UPDATE);
  SIGNAL state : state_type := IDLE;
  
  SIGNAL RXfiltered  : STD_LOGIC;
  SIGNAL RXfilterSRG : STD_LOGIC_VECTOR (2 DOWNTO 0);
  
  SIGNAL srg : STD_LOGIC_VECTOR (DATA_WIDTH+1 DOWNTO 0);

BEGIN  -- ARCHITECTURE uart_rx_arch

   -- filter glitched from input data
   RX_FILTER : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS RX_FILTER
      IF RST = '1' THEN  -- asynchronous reset (active high)
        RXfiltered <= '1';
      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
        RXfilterSRG <= RXfilterSRG (1 DOWNTO 0) & RX;
        RXfiltered <= ((RXfilterSRG(0) and RXfilterSRG(1)) or (RXfilterSRG(0) and RXfilterSRG(2)) or (RXfilterSRG(1) and RXfilterSRG(2)));
      END IF;
   END PROCESS RX_FILTER;

   UART_RX_FSM : PROCESS (CLK, RST) IS
   BEGIN  -- PROCESS UART_RX_FSM
      IF RST = '1' THEN  -- asynchronous reset (active high)
        state <= IDLE;
        busy <= '0';
        data_update <= '0';
        
      ELSIF CLK'EVENT AND CLK = '1' THEN  -- rising clock edge
         data_update <= '0';
         bit_length  <= CLK_LENGTH * to_integer(unsigned(CLKIN_RATIO));
         
         CASE state IS
            WHEN IDLE =>
               busy <= '0';
               cnt_bit_length <= (bit_length / 2) - 2;
               cnt_bits       <= 0;
               IF RXfiltered = '0' THEN
                 if to_integer(unsigned(CLKIN_PHASE)) = 0 THEN
                   state <= WT;
                 else
                   state <= DELAY;
                   delay_cnt <= to_integer(unsigned(CLKIN_PHASE)) - 1;
                 end if;
               END IF;

           when DELAY =>
              busy <= '1';
              if delay_cnt = 0 then
                state <= WT;
              else
                delay_cnt <= delay_cnt - 1;
              end if;
               
            WHEN WT =>
               busy <= '1';
               cnt_bit_length <= cnt_bit_length - 1;
               IF cnt_bit_length = 0 THEN
                  state <= SHIFT;
               ELSE
                  state <= WT;
               END IF;
               
            WHEN SHIFT =>
               cnt_bits       <= cnt_bits + 1;
               srg            <= RXfiltered & srg (DATA_WIDTH+1 DOWNTO 1);
               cnt_bit_length <= bit_length - 2;
               IF cnt_bits >= DATA_WIDTH+1 THEN
                  state <= UPDATE;
               ELSE
                  state <= WT;
               END IF;
               
            WHEN UPDATE =>
               -- check stop bit
               IF srg(DATA_WIDTH+1) = '1' THEN
                  data_update <= '1';
                  data        <= srg(DATA_WIDTH DOWNTO 1);
               END IF;
               state <= IDLE;
               
            WHEN OTHERS =>
               state <= IDLE;
         END CASE;
      END IF;
   END PROCESS UART_RX_FSM;

   TC <= (OTHERS => '0');

END ARCHITECTURE uart_rx_arch;
