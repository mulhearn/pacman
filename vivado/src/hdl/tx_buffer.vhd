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
-- The UART packet data is buffered, and once the entire DMA packet is
-- received, a valid bit is set for each UART specified in the
-- mask. The valid bit is cleared upon receiving a ready from the
-- corresponding UART. The stream is not ready for more input until
-- all UART channels have their valid bit cleared (via ready).
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
    DATA_O             : out uart_tx_data_array_t;
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

  -- clock and reset
  signal clk       : std_logic;
  signal rst       : std_logic;

  -- AXI stream valid-ready handshake:
  -- pass through to stream reader and added to the status register
  signal tvalid    : std_logic;
  signal tready    : std_logic;

  -- Parallel data and valid ready handshake with the stream reader
  signal pdata     : std_logic_vector(C_TX_AXIS_WIDTH*C_TX_AXIS_BEATS-1 downto 0);
  signal pvalid    : std_logic;
  signal pready    : std_logic;

  -- status register
  signal status    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  -- UART channel mask extrated from parallel data:
  signal mask      : std_logic_vector(C_NUM_UART-1 downto 0);

  -- per UART channel valid for the valid/ready handshake with each TX channel:
  signal ovalid    : std_logic_vector(C_NUM_UART-1 downto 0);

  -- state of the TX buffer is either:
  -- waiting on an AXI stream to finish, or
  -- waiting on a TX to finish.
  type state_type is (WAIT_STREAM, WAIT_TX);
  signal state : state_type := WAIT_STREAM;

begin
  ar0: axis_read port map (
    S_AXIS_ACLK     => S_AXIS_ACLK,
    S_AXIS_ARESETN  => S_AXIS_ARESETN,
    S_AXIS_TDATA    => S_AXIS_TDATA,
    S_AXIS_TVALID   => tvalid,
    S_AXIS_TREADY   => tready,
    S_AXIS_TKEEP    => S_AXIS_TKEEP,
    S_AXIS_TLAST    => S_AXIS_TLAST,
    DATA_O          => pdata,
    VALID_O         => pvalid,
    READY_I         => pready
  );

  tvalid <= S_AXIS_TVALID;
  S_AXIS_TREADY <= tready;

  -- register pdata
  process(clk,rst)
  begin
    if (rst='1') then
      mask   <= (others => '0');
      DATA_O <= (others => (others => '0'));
    elsif (rising_edge(clk)) then
      mask <= pdata(C_NUM_UART-1 downto 0);
      for i in 0 to C_NUM_UART-1 loop
        DATA_O(i) <= pdata(C_TX_DATA_WIDTH*(i+3)-1 downto C_TX_DATA_WIDTH*(i+2));
      end loop;
    end if;
  end process;

  VALID_O <= ovalid;
  process(clk,rst)
    function reductive_or (a_vector : std_logic_vector) return std_logic is
      variable r : std_logic := '0';
    begin
      for i in a_vector'range loop
        r := r or a_vector(i);
      end loop;
      return r;
    end function;
  begin
    if (rst='1') then
      state  <= WAIT_STREAM;
      pready <= '0';
      ovalid <= (others => '0');
    elsif (rising_edge(clk)) then
      if (state = WAIT_STREAM) then
        pready <= '0';
        ovalid <= (others => '0');
        if (pvalid='1' and pready='0') then
          ovalid <= mask;
          state <= WAIT_TX;
        end if;
      else
        pready <= '0';
        for i in 0 to C_NUM_UART-1 loop
          if (READY_I(i) = '1') then
            ovalid(i) <= '0';
          end if;
        end loop;
        if (reductive_or(ovalid)='0') then
          pready <= '1';
          state <= WAIT_STREAM;
        end if;
      end if;
    end if;
  end process;

  clk <= S_AXIS_ACLK;
  rst <= not S_AXIS_ARESETN;

  status(0) <= tready;
  status(1) <= tvalid;
  status(4) <= pready;
  status(5) <= pvalid;

  process(clk,rst)
  begin
    if (rst='1') then
      STATUS_O <= (others => '0');
    elsif (rising_edge(clk)) then
      STATUS_O <= status;
    end if;
  end process;
end;
