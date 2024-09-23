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
    GCONFIG_I          : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    GFLAGS_I           : in  std_logic_vector(C_RX_GFLAGS_WIDTH-1 downto 0);
    LOOK_O             : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);
    
    DATA_I             : in  uart_rx_data_array_t;
    VALID_I            : in  std_logic_vector(C_NUM_UART-1 downto 0);
    READY_O            : out std_logic_vector(C_NUM_UART-1 downto 0);

    DEBUG_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DEBUG_DATA_O       : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0)
  );
begin
  assert(C_TURN_MAX >= C_NUM_UART) severity failure;
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

  signal ready     : std_logic_vector(C_NUM_UART-1 downto 0) := (others => '0');
  signal busy      : std_logic;
  signal wen       : std_logic := '0';
  signal last      : std_logic := '0';
  signal data      : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0) := (others => '0');

  signal status    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal turn      : integer range 0 to C_TURN_MAX-1 := 0;

  type state_t is (EMPTY, IDLE, STREAM, SEND_LAST);
  signal state : state_t := EMPTY;


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

  -- Send ready process:
  --
  -- Each ready is held at zero except for one cycle immediately
  -- following the beat on which the data was transfered into the
  -- stream writer.
  process(clk,rst)
    variable turn_z : integer range 0 to C_TURN_MAX-1;
  begin
    if (rst='1') then
      ready <= (others => '0');
    elsif (rising_edge(clk)) then
      ready <= (others => '0');
      if ((wen='1') and (tready='1')) then
        turn_z := (turn + C_TURN_MAX-1) mod C_TURN_MAX;
        if (turn_z < C_NUM_UART) then
          ready(turn_z) <= '1';
        end if;
      end if;
    end if;
  end process;

  -- STATE MACHINE
  process(clk,rst)
    variable last_en  : std_logic := '1';
    variable valid_seen : std_logic := '0';
    variable beats : integer range 0 to C_COUNT_MAX := 0;
  begin
    if (rst='1') then
      state <= EMPTY;
      data  <= (others => '0');
      wen   <= '0';
      last  <= '0';      
    elsif (rising_edge(clk)) then
      if (tvalid='1' and tready='1') then
        beats := (beats + 1) mod C_COUNT_MAX;
      end if;      
      data <= (others => '0');
      wen  <= '0';
      last <= '0';
      if (state = EMPTY) then
        valid_seen := '0';
        beats := 0; 
        if (turn < C_NUM_UART) then
          if (VALID_I(turn) = '1') then
            valid_seen := '1';
            state <= IDLE;
          end if;
        end if;
      end if;
      if (state = IDLE) then
        if (turn < C_NUM_UART) then
          if (VALID_I(turn) = '1') then
            valid_seen := '1';
          end if;
        end if;
        if ((turn=51) and (valid_seen='1')) then
          state <= STREAM;
        end if;
      end if;
      if (state = STREAM) then  
        valid_seen := '1';
        if (turn < 40) then
          data <= DATA_I(turn);
          wen  <= VALID_I(turn);
        end if;        
        if (turn=40) then
          state <= SEND_LAST;          
        end if;
      end if;
      if (state = SEND_LAST) then  
        if (turn=50) then
          data  <= (others=>'0');
          data(95 downto 64)  <= std_logic_vector(to_unsigned(beats, 32));
          wen   <= '1';
          last <= '1';
          state <= EMPTY;          
        end if;
      end if;



    end if;
  end process;



  
  status(1 downto 0) <= "00" when state = EMPTY else
                        "01" when state = IDLE else
                        "10" when state = STREAM else
                        "11";
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
