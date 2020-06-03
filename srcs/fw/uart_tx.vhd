-- general purpose UART

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY uart_tx IS
   GENERIC (
      DATA_WIDTH   : INTEGER
      );
   PORT (
      MCLK         : IN  STD_LOGIC;
      RST          : IN  STD_LOGIC;
      CLKOUT_RATIO : IN UNSIGNED (7 downto 0);
      -- UART TX
      TX          : OUT STD_LOGIC;
      -- received data
      data        : IN  STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
      data_update : IN  STD_LOGIC; -- must be held high until busy goes high
      busy        : OUT STD_LOGIC;
      -- test signals
      TC          : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
      );
END ENTITY uart_tx;

ARCHITECTURE uart_tx_arch OF uart_tx IS
   signal busy_out : std_logic;
   signal tx_out : std_logic;

   signal baud_cnt : unsigned(7 downto 0) := (others => '0');
   signal bit_cnt : unsigned(DATA_WIDTH+2 downto 0) := (others => '0');

   TYPE state_type IS (IDLE, SHIFT);
   SIGNAL state : state_type := IDLE;

   SIGNAL srg : STD_LOGIC_VECTOR (DATA_WIDTH+1 DOWNTO 0);

BEGIN  -- ARCHITECTURE uart_tx_arch
  -- IO
  TX <= tx_out;
  busy <= busy_out;
  TC <= (others => '0');
  
  uart_tx_fsm : process (MCLK, RST) is
  begin
    if (RST = '1') then -- asynchronous reset (active high)
      state <= IDLE;
      tx_out <= '1';
      busy_out <= '1';

    elsif (falling_edge(MCLK)) then
    --elsif (rising_edge(MCLK)) then
      case state is
        when IDLE =>
          busy_out <= '0';
          srg <= '1' & data & '0';
          if (data_update = '1') then
            state <= SHIFT;
            busy_out <= '1';
            bit_cnt <= to_unsigned(DATA_WIDTH + 2, bit_cnt'length);
            baud_cnt <= to_unsigned(0, baud_cnt'length);
          end if;

        when SHIFT =>
          busy_out <= '1';
          -- shift bits
          if (baud_cnt = 0) then
            tx_out <= srg(0);
            srg <= '1' & srg(DATA_WIDTH+1 DOWNTO 1);
            
            -- full word sent
            if (bit_cnt = 0) then
              state <= IDLE;
              
            -- reset baud counter, increment bit counter
            else
              baud_cnt <= CLKOUT_RATIO - 1;
              bit_cnt <= bit_cnt - 1;
            end if;
            
          -- increment baud counter
          else
            baud_cnt <= baud_cnt - 1;
          end if;

        when others =>
          state <= IDLE;
      end case;
    end if;
    end process uart_tx_fsm;

END ARCHITECTURE uart_tx_arch;
