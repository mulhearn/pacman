library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- rx_buffer: Send received (RX) data (from UARTs) out to DMA via an AXI
-- stream using round-robin scheduling.
--
-- Each UART channel has a single buffer, which is marked valid upon a
-- complete transfer from the UART receiver.
--
-- A turn counter runs from 0 to 63.  When the stream is running (i.e.
-- if the receiving FIFO is not full) valid data from a UART is added
-- to the stream only on its turn (e.g. UART 5 streams on turn 5).
-- When streamed, the ready bit is set, so that the UART channel
-- clears the valid bit, and its (single buffer) is ready to recieve
-- updated data.  If new data arrives on the RX channel before the
-- valid bit is cleared (via ready) the packet is lost, which is noted
-- by the lost bit in the UART status.  Counters track the number of
-- lost packets for each UART (which should be zero during normal
-- operation).
--
-- The UART RX channels consume turns 0-39.  The remaining turns are used for
-- adding additional words (e.g. heartbeat and rollover words) to the stream,
-- and for state machine transitions.
--
-- Upon first seeing data after a pause, the streaming does not
-- commence until the start of the next cycle (at turn 0).  This
-- orders the data in the DMA packet nicely, starting with channel 0,
-- when the data is synchronous (such as during loopback testing).
--
-- Although the data is streamed one word at a time, many words are
-- assembled into a single DMA packet using the LAST word.  All data
-- that arrives within a configurable number of cycles (each cycle is
-- 64 turns) is included in the same DMA packet.  (In future, we could
-- specify a maximum time and a maximum packet size).  In this
-- version, the maximum time translates to a maximum possible size.
--
-- CONFIG_I:   0xMMMMTTTT
-- DEFAULT:    0x00000001
-- where: TTTT is a timeout in cycles for writing a complete packet
--        MMMM is max words for writing a complete packet at the end of a cycle
--        In both cases, a zero is no timeout / no maximum

entity rx_buffer is
  generic(
    constant TURN_MAX       : integer := C_RX_TURN_MAX;
    constant FRAGS_PER_TURN : integer := C_RX_FRAGS_PER_TURN
  );
  port (
    -- clock and active-high reset:
    CLK_I              : in std_logic;
    RST_I              : in std_logic;

    -- AXI stream containing RX data (out to PS via FIFO and then DMA)
    M_AXIS_TDATA       : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
    M_AXIS_TVALID      : out std_logic;
    M_AXIS_TREADY      : in std_logic;
    M_AXIS_TKEEP       : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
    M_AXIS_TLAST       : out std_logic;

    -- register accessible status of this module
    STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- configuration register for this module
    CONFIG_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- the most recent data word sent to the stream
    LOOK_O             : out std_logic_vector(C_RX_FRAGS_PER_TURN*C_RX_AXIS_WIDTH-1 downto 0);

    -- the received data from the UART receivers and extra channels
    HEADER_I           : in  rx_header_array_t;
    DATA_I             : in  rx_data_array_t;
    TIMESTAMP_I        : in  rx_timestamp_array_t;
    -- one valid bit for each UART receiver and extra channel
    VALID_I            : in  std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
    -- ready bit is set as each channel is streamed, which clears valid:
    READY_O            : out std_logic_vector(C_RX_NUM_CHAN-1 downto 0);

    -- header to mark the end of packet:
    EOP_HEADER_I       : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- debugging:
    DEBUG_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
begin
  assert(TURN_MAX >= C_RX_NUM_CHAN) severity failure;
end;



architecture behavioral of rx_buffer is
  component axis_write is
    generic (
      constant C_AXIS_WIDTH    : integer  := C_RX_AXIS_WIDTH;
      constant C_DEBUG_WIDTH   : integer  := 8
    );
    port (
      CLK_I              : in std_logic;
      RST_I              : in std_logic;

      M_AXIS_TDATA       : out std_logic_vector(C_AXIS_WIDTH-1 downto 0);
      M_AXIS_TVALID      : out std_logic;
      M_AXIS_TREADY      : in std_logic;

      M_AXIS_TKEEP       : out std_logic_vector(C_AXIS_WIDTH/8-1 downto 0);
      M_AXIS_TLAST       : out std_logic;

      BUSY_O             : out std_logic;
      WEN_I              : in  std_logic;
      LAST_I             : in  std_logic;
      DATA_I             : in  std_logic_vector(C_AXIS_WIDTH-1 downto 0);
      --
      DEBUG_O            : out std_logic_vector(C_DEBUG_WIDTH-1 downto 0)
    );
  end component;

  signal clk       : std_logic;
  signal rst       : std_logic;

  signal uready    : std_logic_vector(C_RX_NUM_CHAN-1 downto 0) := (others => '0');

  signal tvalid    : std_logic;
  signal tready    : std_logic;
  signal data      : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0) := (others => '0');
  signal last      : std_logic := '0';
  signal busy      : std_logic;
  signal wen       : std_logic := '0';

  signal status    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  -- FSM states:
  type state_t is (IDLE, WAIT_STATE, STREAM, TRAILER);
  signal state, next_state : state_t := IDLE;

  -- turn and frag counters:
  signal frag : integer range 0 to 2 := 0;
  signal turn : integer range 0 to 43 := 0;

  -- FSM control signals:
  signal valid_channel      : std_logic := '0';
  signal stream_active      : std_logic := '0';
  signal packet_timeout     : std_logic := '0';
  signal packet_full        : std_logic := '0';

begin

  -- stream writer component:
  --
  -- the stream writer outputs a stream assembled from buffered input
  -- data sourced from the uarts.
  ar0: axis_write port map (
    CLK_I           => clk,
    RST_I           => rst,
    M_AXIS_TDATA    => M_AXIS_TDATA,
    M_AXIS_TVALID   => tvalid,
    M_AXIS_TREADY   => tready,
    M_AXIS_TKEEP    => M_AXIS_TKEEP,
    M_AXIS_TLAST    => M_AXIS_TLAST,
    BUSY_O          => busy,
    WEN_I           => wen,
    LAST_I          => last,
    DATA_I          => data
  );
  M_AXIS_TVALID <= tvalid;
  tready <= M_AXIS_TREADY;

  READY_O <= uready;

  clk <= CLK_I;
  rst <= RST_I;

  -- FSM combinatoric state logic: (see description above)
  process(state, valid_channel, stream_active, packet_timeout, busy, packet_full, frag, turn)
  begin
    case state is
      when IDLE =>
        if valid_channel = '1' then
          next_state <= STREAM;
        else
          next_state <= IDLE;
        end if;

      when WAIT_STATE =>
        if packet_timeout = '1' then
          next_state <= TRAILER;
        elsif valid_channel = '1' then
          next_state <= STREAM;
        else
          next_state <= WAIT_STATE;
        end if;

      when STREAM =>
        if busy = '1' then
          next_state <= STREAM;
        elsif packet_full = '1' and frag = 2 then
          next_state <= TRAILER;
        elsif turn = 43 and frag = 2 then
          next_state <= WAIT_STATE;
        else
          next_state <= STREAM;
        end if;

      when TRAILER =>
        if busy = '1' then
          next_state <= TRAILER;
        elsif frag = 2 then
          next_state <= IDLE;
        else
          next_state <= TRAILER;
        end if;

      when others =>
        next_state <= IDLE;
    end case;

  end process;

  -- state register: on reset enter IDLE,
  -- otherwise update state to next_state for next clock cycle:
  process(clk, rst)
  begin
    if rst = '1' then
      state <= IDLE;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;

  -- turn and frag counters:
  -- only STREAM state uses turn counter
  -- only STREAM and TRAILER states use frag counter
  process(clk, rst)
  begin
    if rst = '1' then
      turn <= 0;
      frag <= 0;
    elsif rising_edge(clk) then
      case state is
        when STREAM =>
          if busy = '0' then
            if frag < 2 then
              frag <= frag + 1;
            else
              frag <= 0;
              if turn < 43 then
                turn <= turn + 1;
              else
                turn <= 0;
              end if;
            end if;
          end if;

        when TRAILER =>
          turn <= 0;
          if busy = '0' then
            if frag < 2 then
              frag <= frag + 1;
            else
              frag <= 0;  -- ready for next IDLE or WAIT_STATE
            end if;
          end if;

        when others =>
          frag <= 0;
          turn <= 0;
      end case;
    end if;
  end process;

  -- detect valid data on any channel:
  process(clk, rst)
  begin
    if rst = '1' then
      valid_channel <= '0';
    elsif rising_edge(clk) then
      valid_channel <= bitwise_or(VALID_I);
    end if;
  end process;

  -- packet timeout: reset in IDLE, otherwise count until configurable timeout
  -- is reached, then flag is high until next reset or IDLE.
  process(clk, rst)
    variable timeout_config : integer;
    variable timeout_counter : integer range 0 to 16#FFFFF# := 0;
  begin
    if rst = '1' then
      timeout_counter := 0;
      packet_timeout <= '0';
    elsif rising_edge(clk) then
      timeout_config := to_integer(unsigned(CONFIG_I(15 downto 0)));

      if (state = IDLE) then
        timeout_counter := 0;
        packet_timeout <= '0';
      else
        if (timeout_counter < 16#FFFFF#) then
          timeout_counter := timeout_counter + 1;
        end if;
        if ((timeout_config > 0) and (timeout_counter >= timeout_config)) then
          packet_timeout <= '1';
        end if;
      end if;
    end if;
  end process;

  -- stream output process:
  process(clk, rst)
    variable sent_config  : integer;
    variable sent_counter : integer range 0 to 16#7FFFFFFF# := 0;
  begin
    if rst = '1' then
      -- reset packet_full and its counter:
      sent_counter := 0;
      packet_full <= '0';
      -- reset stream_active (see STREAM state)
      stream_active <= '0';
      -- stream output siginals (La raison d'etre for this module)
      uready <= (others => '0');
      data   <= (others => '0');
      wen    <= '0';
      last   <= '0';
    elsif rising_edge(clk) then
      sent_config := to_integer(unsigned(CONFIG_I(31 downto 16)));

      uready <= (others => '0');
      data   <= (others => '0');
      wen    <= '0';
      last   <= '0';

      if (state = IDLE) then
        sent_counter := 0;
        packet_full <= '0';
      elsif (state = STREAM) then
        if (busy = '0') then
          case frag is
            when 0 =>
              if (VALID_I(turn) = '1') then
                stream_active <= '1';
                wen <= '1';
                --increment before last fragment so that state transition can occur at fragment=2 when necessary
                if (sent_counter < 16#7FFFFFFF#) then
                  sent_counter  := sent_counter + 1;
                end if;
                data(31 downto 0) <= HEADER_I(turn);
              else
                stream_active <= '0';
              end if;

            when 1 =>
              if (stream_active = '1') then
                wen <= '1';
                data <= TIMESTAMP_I(turn);
              end if;

            when 2 =>
              if (stream_active = '1') then
                wen <= '1';
                data <= DATA_I(turn);
                uready(turn) <= '1';
                stream_active <= '0';
              end if;
          end case;
        end if;
        if (sent_config > 0) and (sent_counter >= sent_config) then
          packet_full <= '1';
        end if;
      elsif (state = TRAILER) then
        if (busy = '0') then
          wen  <= '1';
          if (frag = 0) then
            data(31 downto 0)  <= EOP_HEADER_I;
          elsif (frag = 1) then
            data(31 downto 0)  <= std_logic_vector(to_unsigned(sent_counter, 32));
          else
            data  <= (others=>'0');
            last <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  LOOK_O <= (others => '0');
  --LOOK_O(31 downto 0)   <=  HEADER_I(oturn);
  --LOOK_O(63 downto 32)  <=  (others => '0');
  --LOOK_O(127 downto 64) <=  TIMESTAMP_I(oturn);
  --LOOK_O(191 downto 128) <=  DATA_I(oturn);

  status(2 downto 0) <= "000" when state = IDLE else
                        "001" when state = WAIT_STATE else
                        "010" when state = STREAM else
                        "011" when state = TRAILER else
                        "111";
  status(3) <= tvalid;
  status(4) <= tready;
  status(5) <= busy;
  status(6) <= wen;
  status(7) <= last;
  status(13 downto 8) <= std_logic_vector(to_unsigned(turn, 6));
  status(15 downto 14) <= std_logic_vector(to_unsigned(frag, 2));

  DEBUG_STATUS_O <= status;

  process(clk,rst)
  begin
    if (rst='1') then
      STATUS_O <= (others => '0');
    elsif (rising_edge(clk)) then
      STATUS_O <= status;
    end if;
  end process;



end;
