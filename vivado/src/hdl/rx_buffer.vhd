library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- rx_buffer: Send received (RX) data (from UARTs) out to DMA via an AXI
-- stream using round-robin scheduling.
--
-- Each UART channel has a single 64-bit buffer (see rx_chan.vhd)
-- which is marked valid upon a complete transfer from the UART
-- receiver.  In addition to the 40 UART channels, additional RX
-- channels are assigned for trigger and sync words.
--
-- Valid data is streamed using turn-based round-robin scheduling.
-- The stream width is 64 bits, but the word size is 192 bits, so each
-- turn lasts for three 64-bit fragments.
--
-- The rx_buffer is an FSM with states:
--
--   IDLE:  waiting for arrival of valid data
--     On arrival of valid data, move to STREAM state
--
--   WAIT_STATE: all valid data streamed, wait for new data or timeout
--     On arrival of valid data, move to STREAM state
--     If configurable timeout occurs, move to TRAILER state
--
--   STREAM: turn-based round-robin streaming of data to FIFO. Each RX
--     channel is assigned one turn which lasts long enough to stream
--     three 64-bit fragments when valid data is available and the
--     stream is not busy.
--     If the number of words sent exceeds a threshold, move to
--     TRAILER state.
--     If no more valid data is available, return to WAIT_STATE
--
--   TRAILER: stream trailer word
--     At end of packet, send three 64-bit fragments to write a
--     192-bit TRAILER reporting the number of 192-bit words streamed
--     (not including the TRAILER), and set LAST bit on the final
--     fragment of the trailer.  Return to IDLE state after TRAILER is
--     streamed
--
-- Data for the channel corresponding to the current turn is selected
-- via the MUX.  After valid data for a channel has been buffered for
-- streaming, the ready bit is set for that channel.  On receiving
-- ready, each UART channel clears its valid bit.  If new data arrives
-- on the RX channel before the valid bit is cleared (via ready) the
-- packet is lost, which is noted by the lost bit in the UART status
-- (see rx_chan.vhd).  Counters track the number of lost packets for
-- each UART (which should be zero during normal operation).
--
-- Although the data is streamed one word at a time, many words are
-- assembled into a single DMA packet (as marked via the LAST bit).
-- The size of the DMA packet is configurable based on a maximum number of
-- words and a timeout.
--
-- CONFIG_I:   0xMMMMTTTT
-- DEFAULT:    0x00000001
-- where: TTTT is timeout in clock cycles for completing packet
--        MMMM is max words streamed for completing a packet
--
-- In both cases, a zero is no condition (no timeout / no maximum).
-- The timeout is not checked while in stream state, so e.g. a timeout of one
-- (default setting) will send data from all channels with valid data once
-- valid data from at least one channel is available.
--

entity rx_buffer is
  port (
    -- clock and active-high reset:
    CLK_I              : in std_logic;
    RST_I              : in std_logic;

    -- AXI stream containing RX data (out to PS via FIFO and then DMA)
    M_AXIS_TDATA       : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
    M_AXIS_TVALID      : out std_logic;
    M_AXIS_TREADY      : in  std_logic;
    M_AXIS_TKEEP       : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
    M_AXIS_TLAST       : out std_logic;

    -- register accessible status of this module
    STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- configuration register for this module
    CONFIG_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- the received data from the UART receivers and extra channels
    CHAN_SELECT_O      : out std_logic_vector(C_SELECT_WIDTH-1 downto 0);
    HEADER_I           : in  std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
    FRAG_A_I           : in  std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
    FRAG_B_I           : in  std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);

    -- one valid bit for each UART receiver and extra channel
    VALID_I            : in  std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
    -- ready bit is set as each channel is streamed, which clears valid:
    READY_O            : out std_logic_vector(C_RX_NUM_CHAN-1 downto 0);

    -- header to mark the end of packet:
    EOP_HEADER_I       : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- debugging:
    DEBUG_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
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
  signal ready    : std_logic_vector(C_RX_NUM_CHAN-1 downto 0) := (others => '0');
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
  signal frag   : integer range 0 to C_RX_FRAGS_PER_TURN-1 := 0;
  signal turn   : integer range 0 to (C_RX_NUM_CHAN)       := 0;

  signal chan_select : std_logic_vector(C_SELECT_WIDTH-1 downto 0);
  signal header      : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
  signal frag_a      : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
  signal frag_b      : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);

  -- FSM control signals:
  signal valid_channel      : std_logic := '0';
  signal packet_timeout     : std_logic := '0';
  signal packet_full        : std_logic := '0';
  signal stream_active      : std_logic := '0';

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

  READY_O <= ready;
  CHAN_SELECT_O <= chan_select;

  clk <= CLK_I;
  rst <= RST_I;

  -- FSM combinatoric state logic: (see description above)
  process(state, busy, valid_channel, packet_timeout, packet_full, frag, turn)
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
        elsif packet_full = '1' and frag = (C_RX_FRAGS_PER_TURN-1) then
          next_state <= TRAILER;
        elsif turn = C_RX_NUM_CHAN and frag = (C_RX_FRAGS_PER_TURN-1) then
          next_state <= WAIT_STATE;
        else
          next_state <= STREAM;
        end if;

      when TRAILER =>
        if busy = '1' then
          next_state <= TRAILER;
        elsif frag = (C_RX_FRAGS_PER_TURN-1) then
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
            if frag < C_RX_FRAGS_PER_TURN-1 then
              frag <= frag + 1;
            else
              frag <= 0;
              -- turn = C_RX_NUM_CHAN is used to stream last channel...
              if turn < C_RX_NUM_CHAN then
                turn <= turn + 1;
              else
                turn <= 0;
              end if;
            end if;
          end if;

        when TRAILER =>
          turn <= 0;
          if busy = '0' then
            if frag < C_RX_FRAGS_PER_TURN-1 then
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


  -- buffer inputs process:
  process(clk, rst)
    variable buffer_active : boolean;
  begin
    if rst = '1' then
      ready       <= (others => '0');
      chan_select <= (others => '0');
      stream_active <= '0';
      header <= (others => '0');
      frag_a <= (others => '0');
      frag_b <= (others => '0');
    elsif rising_edge(clk) then
      ready         <= (others => '0');
      chan_select   <= chan_select;
      stream_active <= stream_active;
      header <= header;
      frag_a <= frag_a;
      frag_b <= frag_b;

      if (busy='0') and (state = STREAM) then
        case frag is
          when 0 =>
            if (turn < C_RX_NUM_CHAN) then
              chan_select <= std_logic_vector(to_unsigned(turn,chan_select'length));
              if (VALID_I(turn) = '1') then
                -- set the buffer active flag:
                buffer_active := true;
              else
                buffer_active := false;
              end if;
            else
              buffer_active:= false;
            end if;

          when 1 =>
            --waiting for mux...

          when 2 =>
            if (buffer_active) then
              -- buffer the MUX inputs:
              header <= HEADER_I;
              frag_a <= FRAG_A_I;
              frag_b <= FRAG_B_I;

              -- clear valid for this channel now that it is buffered
              ready(turn) <= '1';
              -- output to stream during the following turn:
              stream_active <= '1';
            else
              stream_active <= '0';
            end if;
        end case;
      end if;
    end if;
  end process;

  -- stream output process:
  process(clk, rst)
    variable sent_counter  : integer range 0 to 16#7FFFFFFF# := 0;
    variable sent_config   : integer := 0;
  begin
    if rst = '1' then
      packet_full <= '0';
      data        <= (others => '0');
      wen         <= '0';
      last        <= '0';
    elsif rising_edge(clk) then
      sent_config := to_integer(unsigned(CONFIG_I(31 downto 16)));
      packet_full <= packet_full;
      data        <= (others => '0');
      wen         <= '0';
      last        <= '0';
      if (state = IDLE) then
        sent_counter := 0;
        packet_full <= '0';
      elsif (state = STREAM) then
        if (busy = '0') then
          case frag is
            when 0 =>
              if (stream_active = '1') then
                -- send the header:
                wen <= '1';
                data <= header;
                -- we are fully committed, increment now so that we
                -- can act on packet_full by last fragment
                if (sent_counter < 16#7FFFFFFF#) then
                  sent_counter  := sent_counter + 1;
                end if;
              end if;

            when 1 =>
              if (stream_active = '1') then
                wen <= '1';
                data <= frag_a;
              end if;

            when 2 =>
              if (stream_active = '1') then
                wen <= '1';
                data <= frag_b;
              end if;
          end case;
        end if;
        if (sent_config > 0) and (sent_counter >= sent_config) then
          packet_full <= '1';
        end if;
      elsif (state = TRAILER) then
        if (busy = '0') then
          wen  <= '1';
          case frag is
            when 0 =>
              data(31 downto 0)  <= EOP_HEADER_I;

            when 1 =>
              data(31 downto 0)  <= std_logic_vector(to_unsigned(sent_counter, 32));

            when 2 =>
              last <= '1';
          end case;
        end if;
      end if;
    end if;
  end process;

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
