library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- tx_buffer: buffers data (from DMA) to be transmitted
--
-- Receives data to be transmitted via AXI stream interface (from PS
-- via DMA) Each DMA packet consists of a 128-bit header and 20
-- 128-bit words.  The header contains a channel mask specifying which
-- channels have data to transmit.  The 20 128-bit words contains the
-- 40 uart payloads, each of 64 bits.  Payload from inactive UARTs is
-- ignored.
--
-- Once an entire DMA packet is received, the data for each UART is
-- placed in an output buffer and a valid bit is set for each UART
-- specified in the mask.  The stream reader is sent the ready
-- command, releasing its own buffer, so that it can beging reading
-- the next DMA packet.
--
-- Each valid bit is cleared upon receiving a ready from the
-- corresponding UART.  Once no valid bits remain high, the state
-- returns to IDLE.
--
-- This module contains the AXI stream reader module, which handles the
-- incoming AXI stream (with UART channels serial) and outputs the data in
-- parallel format.
--

entity tx_buffer is
  port (
    -- clock and reset
    S_AXIS_ACLK        : in std_logic;
    S_AXIS_ARESETN     : in std_logic;

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
    READY_I            : in std_logic_vector(C_NUM_UART-1 downto 0)
  );
end;

architecture behavioral of tx_buffer is
  component axis_read is
    generic (
      constant C_AXIS_WIDTH  : integer  := C_TX_AXIS_WIDTH;
      constant C_AXIS_BEATS   : integer  := C_TX_AXIS_BEATS
      );
    port (
      S_AXIS_ACLK        : in std_logic;
      S_AXIS_ARESETN     : in std_logic;
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

  -- UART channel mask extrated from parallel data:
  signal mask      : std_logic_vector(C_NUM_UART-1 downto 0);

  -- per UART channel valid for the valid/ready handshake with each TX channel:
  signal uart_valid    : std_logic_vector(C_NUM_UART-1 downto 0);

  -- state of the TX buffer is either:
  -- waiting on an AXI stream to finish, or
  -- waiting on a TX to finish.
  type state_type is (IDLE, START_TX, TX);
  signal state      : state_type := IDLE;
  signal next_state : state_type := IDLE;

begin
  ar0: axis_read port map (
    S_AXIS_ACLK     => S_AXIS_ACLK,
    S_AXIS_ARESETN  => S_AXIS_ARESETN,
    S_AXIS_TDATA    => S_AXIS_TDATA,
    S_AXIS_TVALID   => stream_valid,
    S_AXIS_TREADY   => stream_ready,
    S_AXIS_TKEEP    => S_AXIS_TKEEP,
    S_AXIS_TLAST    => S_AXIS_TLAST,
    DATA_O          => packet_data,
    VALID_O         => packet_valid,
    READY_I         => packet_ready
  );

  clk <= S_AXIS_ACLK;
  rst <= not S_AXIS_ARESETN;
  S_AXIS_TREADY <= stream_ready;
  stream_valid <= S_AXIS_TVALID;
  VALID_O <= uart_valid;

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

  -- simple flags
  process(clk,rst)
  begin
    if (rst='1') then
      packet_ready <= '0';
    elsif (rising_edge(clk)) then
      packet_ready <= '0';
      case state is
        when IDLE =>
          --do nothing
        when START_TX =>
          packet_ready <= '1';
        when TX =>
          --do nothing
      end case;
    end if;
  end process;

  -- register UART mask and data:
  process(clk,rst)
  begin
    if (rst='1') then
      DATA_O <= (others => (others => '0'));
    elsif (rising_edge(clk)) then
      case state is
        when IDLE =>
          DATA_O <= (others => (others => '0'));
        when START_TX =>
          for i in 0 to C_NUM_UART-1 loop
            DATA_O(i) <= packet_data(C_UART_DATA_WIDTH*(i+3)-1 downto C_UART_DATA_WIDTH*(i+2));
          end loop;
        when TX =>
          --DATA_O is sticky
      end case;
    end if;
  end process;

  --process for uart_valid
  process(clk,rst)
  begin
    if (rst='1') then
      packet_ready <= '1';
      uart_valid <= (others => '0');
    elsif (rising_edge(clk)) then
      case state is
        when IDLE =>
          uart_valid <= (others => '0');
        when START_TX =>
          uart_valid <= packet_data(C_NUM_UART-1 downto 0);
        when TX =>
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

  process(clk,rst)
  begin
    if (rst='1') then
      STATUS_O <= (others => '0');
    elsif (rising_edge(clk)) then
      STATUS_O <= status;
    end if;
  end process;
end;
