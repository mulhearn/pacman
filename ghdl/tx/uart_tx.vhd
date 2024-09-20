-- general purpose UART

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY uart_tx IS
  GENERIC (
    CLK_HZ : INTEGER := 100000000;
    CLKOUT_HZ : INTEGER := 10000000;
    DATA_WIDTH   : INTEGER := 64
    );
  PORT (
    CLK          : IN  STD_LOGIC;
    RST          : IN  STD_LOGIC;
    CLKOUT_RATIO : IN  STD_LOGIC_VECTOR (7 downto 0);
    CLKOUT_PHASE : IN  STD_LOGIC_VECTOR (3 downto 0);    
    -- UART TX
    MCLK        : IN  STD_LOGIC;
    TX          : OUT STD_LOGIC;
    -- received data
    data        : IN  STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
    data_update : IN  STD_LOGIC; -- must be held high until busy goes high
    busy        : OUT STD_LOGIC
    -- test signals
    --TC          : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
END ENTITY uart_tx;

ARCHITECTURE uart_tx_arch OF uart_tx IS
  constant BIT_LEN : integer := CLK_HZ / CLKOUT_HZ;
  
  signal busy_out : std_logic;
  signal tx_out : std_logic;
  
  signal mclk_meta : std_logic;
  signal mclk_sync : std_logic;
  signal mclk_prev : std_logic;

  signal phase_cnt : unsigned(3 downto 0) := (others => '0');
  signal baud_cnt : unsigned(7 downto 0) := (others => '0');
  signal bit_cnt : unsigned(DATA_WIDTH+2 downto 0) := (others => '0');

  TYPE state_type IS (IDLE, WT, DELAY, SHIFT);
  SIGNAL state : state_type := IDLE;

  SIGNAL srg : STD_LOGIC_VECTOR (DATA_WIDTH+1 DOWNTO 0);
  
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of mclk_meta: signal is "TRUE";
  attribute ASYNC_REG of mclk_sync: signal is "TRUE";

BEGIN  -- ARCHITECTURE uart_tx_arch
  -- IO
  TX <= tx_out;
  busy <= busy_out;
  --TC <= (others => '0');

  mclk_sync_proc : process (CLK) is
  begin
    if (rising_edge(CLK)) then
      mclk_meta <= MCLK;
      mclk_sync <= mclk_meta;
      mclk_prev <= mclk_sync;
    end if;
  end process;
  
  uart_tx_fsm : process (CLK, RST) is
  begin
    if (RST = '1') then -- asynchronous reset (active high)
      state <= IDLE;
      tx_out <= '1';
      busy_out <= '0'; -- mm change
      
    elsif (rising_edge(CLK)) then
      case state is
        when IDLE =>
          busy_out <= '0';
          srg <= '1' & data & '0';
          if (data_update = '1') then
            state <= WT;
            --mm change: keep busy low during IDLE
            bit_cnt <= to_unsigned(DATA_WIDTH + 2, bit_cnt'length);
            baud_cnt <= to_unsigned(0, baud_cnt'length);
            phase_cnt <= unsigned(CLKOUT_PHASE);
          end if;

        when WT =>
          -- sync with mclk rising edge
          busy_out <= '1';
          if (mclk_sync = '1' and mclk_prev = '0') then
             state <= DELAY;
          end if;

        when DELAY =>
          -- delay relative to mclk rising edge
          busy_out <= '1';
          if (phase_cnt > 0) then 
            phase_cnt <= phase_cnt - 1;
          else
            state <= SHIFT;
          end if;
          
        when SHIFT =>
          -- shift bits
          busy_out <= '1';
          if (baud_cnt = 0) then
            tx_out <= srg(0);
            srg <= '1' & srg(DATA_WIDTH+1 DOWNTO 1);
            
            -- full word sent
            if (bit_cnt = 0) then
              state <= IDLE;              
            -- reset baud counter, increment bit counter
            else
              baud_cnt <= to_unsigned(to_integer(unsigned(CLKOUT_RATIO)) * BIT_LEN, baud_cnt'length) - 1;
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
