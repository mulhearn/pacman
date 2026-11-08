library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- tx_buffer: buffers data (from DMA) to be transmitted
--
-- Receives data to be transmitted via AXI stream interface (from PS
-- via DMA) Each DMA packet consists of a 64-bit header followed by 40
-- 64-bit words (one for each UART) containing the data to be
-- transmitted.  The header contains a channel mask specifying which
-- channels have data to transmit.
--
-- Once an entire DMA packet is received, the data for each UART is
-- placed in an output buffer and a valid bit is set for each UART
-- specified in the mask.  The stream reader is sent the ready
-- command, releasing its own buffer, so that it can begin reading the
-- next DMA packet in parallel with UART transmission.
--
-- Each valid bit is cleared upon receiving a ready from the
-- corresponding UART.  The output buffer is not updated with new data until no
-- valid bits remain high from the previous transmission.
--
-- This module contains the AXI stream reader module, which handles the
-- incoming AXI stream (with UART channels serial) and outputs the data in
-- parallel format.
--
-- The tx_buffer is an FSM with following states:
--
--   IDLE:  waiting for next TX packet
--     When stream reader reports an entire packet is valid, move to START_TX
--
--   START_TX: start UART transmission.  Copy stream data to output
--     buffer, assert ready to free stream readers buffer, and set valid high for each UART as specified in the mask.
--     Move to TX state on next clock cycle.
--
--   TX: UART transmission.  Clear valid as each UART channel reports ready.
--     When no channel has valid data, move to IDLE state.
--

entity tx_buffer is
  port (
    -- clock and active-high reset
    CLK_I              : in std_logic;
    RST_I              : in std_logic;

    -- AXI stream containing the data to be transmitted
    S_AXIS_TDATA       : in std_logic_vector(C_TX_AXIS_WIDTH-1 downto 0);
    S_AXIS_TVALID      : in std_logic;
    S_AXIS_TREADY      : out std_logic;
    S_AXIS_TKEEP       : in std_logic_vector(C_TX_AXIS_WIDTH/8-1 downto 0);
    S_AXIS_TLAST       : in std_logic;

    -- status register from this module (tx_buffer)
    STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- the data to be transmitted:
    DATA_O             : out uart_data_array_t;
    -- one valid bit per UART, set to 1 when new data is received
    VALID_O            : out std_logic_vector(C_NUM_UART-1 downto 0);
    -- one ready bit per UART, from TX channel
    -- valid is cleared when UART has both valid and ready
    READY_I            : in std_logic_vector(C_NUM_UART-1 downto 0);

    DEBUG_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
end;

architecture behavioral of tx_buffer is
  component axis_read is
    generic (
      constant C_AXIS_WIDTH  : integer  := C_TX_AXIS_WIDTH;
      constant C_AXIS_BEATS   : integer  := C_TX_AXIS_BEATS
      );
    port (
      CLK_I              : in std_logic;
      RST_I              : in std_logic;
      S_AXIS_TDATA       : in std_logic_vector(C_AXIS_WIDTH-1 downto 0);
      S_AXIS_TVALID      : in std_logic;
      S_AXIS_TREADY      : out std_logic;
      S_AXIS_TKEEP       : in std_logic_vector(C_AXIS_WIDTH/8-1 downto 0);
      S_AXIS_TLAST       : in std_logic;
      DATA_O             : out std_logic_vector(C_AXIS_WIDTH*C_AXIS_BEATS-1 downto 0);
      VALID_O            : out std_logic;
      READY_I            : in std_logic
    );
  end component;

  signal clk, rst : std_logic;

  -- AXI stream valid and ready:
  -- pass through to stream reader and added to the status register
  signal stream_valid    : std_logic;
  signal stream_ready    : std_logic;

  -- Fully assembled packet data and valid ready handshake with the stream reader
  signal packet_data     : std_logic_vector(C_TX_AXIS_WIDTH*C_TX_AXIS_BEATS-1 downto 0);
  signal packet_valid    : std_logic;
  signal packet_ready    : std_logic;

  -- status register
  signal status    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  -- per UART channel valid for the valid/ready handshake with each TX channel:
  signal uart_valid    : std_logic_vector(C_NUM_UART-1 downto 0);
  signal uart_data     : uart_data_array_t;

  -- state of the TX buffer:
  type state_type is (IDLE, START_TX, TX);
  signal state      : state_type := IDLE;
  signal next_state : state_type := IDLE;

begin
  ar0: axis_read port map (
    CLK_I           => clk,
    RST_I           => rst,
    S_AXIS_TDATA    => S_AXIS_TDATA,
    S_AXIS_TVALID   => stream_valid,
    S_AXIS_TREADY   => stream_ready,
    S_AXIS_TKEEP    => S_AXIS_TKEEP,
    S_AXIS_TLAST    => S_AXIS_TLAST,
    DATA_O          => packet_data,
    VALID_O         => packet_valid,
    READY_I         => packet_ready
  );

  clk <= CLK_I;
  rst <= RST_I;
  S_AXIS_TREADY <= stream_ready;
  stream_valid <= S_AXIS_TVALID;
  VALID_O <= uart_valid;
  DATA_O  <= uart_data;

  process(state, packet_valid, uart_valid)
  begin
    next_state <= state;
    case state is
      when IDLE =>
        if packet_valid='1' then
          next_state <= START_TX;
        end if;
      when START_TX =>
        next_state <= TX;
      when TX =>
        if bitwise_or(uart_valid)='0' then
          next_state <= IDLE;
        end if;
    end case;
  end process;

  -- FSM state register:
  process(clk, rst)
  begin
    if rst='1' then
      state        <= IDLE;
    elsif rising_edge(clk) then
      state        <= next_state;
    end if;
  end process;

  -- state dependent signals: packet_ready, uart_valid, uart_data
  process(clk,rst)
  begin
    if (rst='1') then
      packet_ready <= '0';
      uart_valid <= (others => '0');
      uart_data <= (others => (others => '0'));
    elsif (rising_edge(clk)) then
      packet_ready <= packet_ready;
      uart_valid <= uart_valid;
      uart_data <= uart_data;

      case state is
        when IDLE =>
          packet_ready <= '0';
          uart_valid <= (others => '0');
        when START_TX =>
          packet_ready <= '1';
          uart_valid <= packet_data(C_NUM_UART-1 downto 0);
          for i in 0 to C_NUM_UART-1 loop
            uart_data(i) <= packet_data(C_UART_DATA_WIDTH*(i+2)-1 downto C_UART_DATA_WIDTH*(i+1));
          end loop;
        when TX =>
          packet_ready <= '0';
          for i in 0 to C_NUM_UART-1 loop
            if (READY_I(i) = '1') then
              uart_valid(i) <= '0';
            end if;
          end loop;

      end case;
    end if;
  end process;

  status(0) <= stream_ready;
  status(1) <= stream_valid;
  status(4) <= packet_ready;
  status(5) <= packet_valid;

  status(9 downto 8) <= "00" when state = IDLE else
                        "01" when state = START_TX else
                        "10" when state = TX else
                        "11";
  --undelayed status for the test bench:
  DEBUG_O <= status;

  process(clk,rst)
  begin
    if (rst='1') then
      STATUS_O <= (others => '0');
    elsif (rising_edge(clk)) then
      STATUS_O <= status;
    end if;
  end process;
end;
