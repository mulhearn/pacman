library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity rx_buffer is
  generic(
    constant C_TURN_MAX : integer := C_RX_TURN_MAX
  );
  port (
    M_AXIS_ACLK        : in std_logic;
    M_AXIS_ARESETN     : in std_logic;
    M_AXIS_TDATA       : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
    M_AXIS_TVALID      : out std_logic;
    M_AXIS_TREADY      : in std_logic;
    M_AXIS_TKEEP       : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
    M_AXIS_TLAST       : out std_logic;

    STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    LOOK_O             : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);

    DATA_I             : in  uart_rx_data_array_t;
    VALID_I            : in  std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
    READY_O            : out std_logic_vector(C_RX_NUM_CHAN-1 downto 0);

    DEBUG_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DEBUG_DATA_O       : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0)
  );
begin
  assert(C_TURN_MAX >= C_RX_NUM_CHAN) severity failure;
end;


architecture behavioral of rx_buffer is
  component axis_write is
    generic (
      constant C_AXIS_WIDTH    : integer  := C_RX_AXIS_WIDTH;
      constant C_DEBUG_WIDTH   : integer  := 8
    );
    port (
      M_AXIS_ACLK        : in std_logic;
      M_AXIS_ARESETN     : in std_logic;

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

  signal tvalid    : std_logic;
  signal tready    : std_logic;

  signal ready     : std_logic_vector(C_RX_NUM_CHAN-1 downto 0) := (others => '0');
  signal busy      : std_logic;
  signal wen       : std_logic := '0';
  signal last      : std_logic := '0';
  signal data      : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0) := (others => '0');

  signal status    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal turn      : integer range 0 to C_TURN_MAX-1 := 0;

  type state_t is (IDLE, STREAM, SEND_LAST);
  signal state : state_t := IDLE;


begin

  -- stream writer component:
  --
  -- the stream writer outputs a stream assembled from buffered input
  -- data sourced from the uarts.
  ar0: axis_write port map (
    M_AXIS_ACLK     => M_AXIS_ACLK,
    M_AXIS_ARESETN  => M_AXIS_ARESETN,
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

  clk <= M_AXIS_ACLK;
  rst <= not M_AXIS_ARESETN;

  -- Turn counter process:
  --
  -- The turn counter determines which uart is eligible for data
  -- transfer to the stream writer.  Turns 0-39 are used for the
  -- UARTs.  The remaining turns are used for state transitions and sending
  -- last according to the finite state machine.
  process(clk,rst)
  begin
    if (rst='1') then
      turn <= 0;
    elsif (rising_edge(clk)) then
      turn <= (turn + 1) mod C_TURN_MAX;
    end if;
  end process;



  -- STATE MACHINE
  process(clk,rst)
    variable valid_seen : std_logic := '0';
    variable sent : integer range 0 to C_COUNT_MAX := 0;
  begin
    if (rst='1') then
      state <= IDLE;
      valid_seen  := '0';
      sent        := 0;
      ready <= (others => '0');
      data  <= (others => '0');
      wen   <= '0';
      last  <= '0';
    elsif (rising_edge(clk)) then
      ready <= (others => '0');
      data <= (others => '0');
      wen  <= '0';
      last <= '0';
      if (state = IDLE) then
        if (turn < C_RX_NUM_CHAN) then
          if (VALID_I(turn) = '1') then
            valid_seen := '1';
          end if;
        end if;
        if ((turn=51) and (valid_seen='1')) then
          state <= STREAM;
        end if;
      end if;
      if (state = STREAM) then
        if ((turn < C_RX_NUM_CHAN) and (busy = '0')) then
          if (VALID_I(turn) = '1') then
            data <= DATA_I(turn);
            wen  <= '1';
            ready(turn) <= '1';
            sent := (sent + 1) mod C_COUNT_MAX; 
          end if;
        end if;
        if (turn=44) then
          state <= SEND_LAST;
        end if;
      end if;
      if (state = SEND_LAST) then
        if ((turn=50) and (busy = '0')) then
          data  <= (others=>'0');
          data(95 downto 64)  <= std_logic_vector(to_unsigned(sent, 32));
          wen   <= '1';
          last <= '1';
          valid_seen := '0';
          sent := 0;          
          state <= IDLE;
        end if;
      end if;
    end if;
  end process;

  status(1 downto 0) <= "00" when state = IDLE else
                        "01" when state = STREAM else
                        "10"; 

  status(2) <= tvalid;
  status(3) <= tready;

  status(4) <= busy;
  status(5) <= wen;
  status(6) <= last;
  status(7) <= '1';
  status(13 downto 8) <= std_logic_vector(to_unsigned(turn, 6));

  DEBUG_DATA_O   <= data;
  DEBUG_STATUS_O <= status;

  process(clk,rst)
  begin
    if (rst='1') then
      STATUS_O <= (others => '0');
      LOOK_O <= (others => '0');
    elsif (rising_edge(clk)) then
      STATUS_O <= status;
      if (wen='1') then
        LOOK_O <= data;
      end if;
    end if;
  end process;
end;
