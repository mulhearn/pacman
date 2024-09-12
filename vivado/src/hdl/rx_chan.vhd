library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity rx_chan is
  generic (
    constant C_UART_CHANNEL    : integer  range 0 to C_NUM_UART-1 := 0
  );
  port (
    ACLK        : in std_logic;
    ARESETN     : in std_logic;

    CONFIG_I    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    COMMAND_I   : in  std_logic_vector(C_COMMAND_WIDTH-1 downto 0);
    STATUS_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    
    CYCLES_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    BUSYS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    ACKS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    LOSTS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    

    
    --FIFO ACCESS NOT YET IMPLEMENTED
    -- TURN : in  std_logic_vector();
    LOOK_O      : out std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0);        
    RX_I        : in  std_logic;

    DEBUG_O     : out  std_logic_vector(15 downto 0)
  );
end;

architecture behavioral of rx_chan is
  component rx_buffer is
    port (
      ACLK        : in   std_logic;
      ARESETN     : in   std_logic;
      CONFIG_I    : in   std_logic_vector(C_RX_BUFFER_CONFIG_WIDTH-1 downto 0);
      DATA_O      : out  std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0);      
      VALID_O     : out  std_logic;
      ACK_I       : in   std_logic;
      LOST_O      : out std_logic;
      RX_I        : in   std_logic;
      TIMESTAMP_I : in  std_logic_vector(31 downto 0);
      CHANNEL_I   : in  std_logic_vector(7 downto 0);
      HEADER_I    : in  std_logic_vector(7 downto 0);
      MON_BUSY_O  : out  std_logic;
      DEBUG_O     : out  std_logic_vector(15 downto 0)
    );
  end component;

  signal clk         : std_logic;
  signal rst         : std_logic;
  signal rst_q       : std_logic := '0';
  
  signal rx          : std_logic;
  signal data        : std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0) := (others => '0');
  signal look        : std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0) := (others => '0');

  -- RX DATA CONTROL SIGNALS:
  signal valid        : std_logic;
  signal lost         : std_logic;
  signal ack          : std_logic := '0';
  signal busy         : std_logic;

  -- COMMANDS:
  signal clear        : std_logic := '0';
  signal start        : std_logic := '0';
  signal stop         : std_logic := '0';
  signal single       : std_logic := '0';
  -- running is after start until stop:
  signal running      : std_logic := '0';
  
  -- STATUS bits:
  signal valid_seen   : std_logic := '0';
  signal busy_seen    : std_logic := '0';
  signal ack_seen     : std_logic := '0';
  signal rx_seen      : std_logic := '0';

  signal single_seen  : std_logic := '0';
  signal start_seen   : std_logic := '0';
  signal stop_seen    : std_logic := '0';
  
  signal count_ack_always : std_logic_vector(15 downto 0) := (others => '0'); 
  
begin

  urx: rx_buffer port map (
    ACLK    => ACLK,
    ARESETN => ARESETN,
    CONFIG_I  => CONFIG_I(C_RX_BUFFER_CONFIG_WIDTH-1 downto 0),
    DATA_O    => data,
    VALID_O => valid,
    LOST_O => lost,
    ACK_I => ack,
    RX_I => rx,
    TIMESTAMP_I => x"00000EE0",
    CHANNEL_I   => x"11",
    HEADER_I    => x"44",    
    MON_BUSY_O => busy
  );
   
  clk <= ACLK;
  rst   <= not ARESETN;
  rx <= RX_I;
  LOOK_O <= look;

  -- Fill the LOOK buffer as long as the data is valid:  
  process(clk)
    variable mode : integer range 0 to 9 := 0;
  begin
    if (rst='1') then

    else
      if (rising_edge(clk) and valid='1') then

      end if;
    end if;   
  end process;

  -- Send ack according to the mode:  
  process(clk)
    variable mode : integer range 0 to 9 := 0;
  begin
    mode := to_integer(unsigned(CONFIG_I(14 downto 12)));      
    if (rst='1') then
      ack <= '0';
      look  <= (others => '0');
    else
      if (rising_edge(clk)) then
        if (mode = 3) then
          -- Mode 3:  Continuous Acceptance
          if (ack = '1') then
            ack <= '0';
          elsif (valid='1') then
            look <= data;
            ack <= '1';
          end if;
        elsif (mode = 2) then
          -- Mode 2:  Single Shot Transmission
          if (ack='1') then
            ack <= '0';
          elsif (single='1' and valid='1') then
            look <= data;
            ack <= '1';
          end if;
        else
          -- Mode 0: Disable RX
          look <= (others => '0');
          ack <= '0';          
        end if;
      end if;
    end if;   
  end process;

  -- Commands:
  single <= COMMAND_I(0);
  start  <= COMMAND_I(1);
  stop   <= COMMAND_I(2);
  clear  <= COMMAND_I(3);

  -- Status register bits:

    
  STATUS_O(0) <= valid;
  STATUS_O(1) <= busy;
  STATUS_O(2) <= ack;
  STATUS_O(3) <= rx;

  STATUS_O(4) <= valid_seen;
  STATUS_O(5) <= busy_seen; 
  STATUS_O(6) <= ack_seen;  
  STATUS_O(7) <= rx_seen;   

  STATUS_O(8)  <= single_seen;
  STATUS_O(9)  <= start_seen; 
  STATUS_O(10)  <= stop_seen;  
  STATUS_O(11)  <= running;  

  STATUS_O(15 downto 12) <= x"F";
  STATUS_O(31 downto 16) <= count_ack_always;  
    
  process(clk)
    variable cnt_ack : integer range 0 to 16#FFFF# := 0;
  begin
    if (rising_edge(clk)) then
      rst_q <= rst;
    end if;
    
    if (rst='1' or rst_q='1' or clear='1') then
      running       <= '0';    
      valid_seen    <= '0';    
      busy_seen     <= '0';    
      ack_seen      <= '0';    
      rx_seen       <= '0';  
      single_seen   <= '0';  
      start_seen    <= '0';  
      stop_seen     <= '0';
      cnt_ack := 0;
    else
      if (rising_edge(clk)) then
        count_ack_always <= std_logic_vector(to_unsigned(cnt_ack,count_ack_always'length));
        if (valid='1') then
          valid_seen    <= '1';    
        end if;
        if (busy='1') then
          busy_seen    <= '1';    
        end if;
        if (ack='1') then
          cnt_ack := cnt_ack + 1;
          ack_seen    <= '1';    
        end if;
        if (rx='0') then
          rx_seen    <= '1';    
        end if;
        if (single='1') then
          single_seen    <= '1';    
        end if;
        if (start='1') then
          running <= '1';
          start_seen    <= '1';    
        end if;
        if (stop='1') then
          running <= '0';
          stop_seen    <= '1';    
        end if;
      end if;    
    end if;
  end process;


  -- counters --
  process(clk)
    variable cycles   : integer := 0;
    variable busys    : integer := 0;
    variable acks     : integer := 0;
    variable losts    : integer := 0;
  begin
    if (rst='1' or clear='1') then
      cycles := 0;
      busys  := 0;
      acks   := 0;
      losts  := 0;
    else
      if (rising_edge(clk)) then
        CYCLES_O  <= std_logic_vector(to_unsigned(cycles, C_RB_DATA_WIDTH));
        BUSYS_O   <= std_logic_vector(to_unsigned(busys,   C_RB_DATA_WIDTH));
        ACKS_O    <= std_logic_vector(to_unsigned(acks,   C_RB_DATA_WIDTH));
        LOSTS_O   <= std_logic_vector(to_unsigned(losts,   C_RB_DATA_WIDTH));
        if (running='1') then
          cycles := cycles + 1;
          if (busy='1') then
            busys := busys + 1;
          end if;
          if (ack='1') then
            acks := acks + 1;
          end if;
          if (lost='1') then
            losts := losts + 1;
          end if;
        end if;
      end if;    
    end if;
  end process;

  
  DEBUG_O(0) <= single;
  DEBUG_O(1) <= start;
  DEBUG_O(2) <= stop;
  DEBUG_O(3) <= clear;  
  DEBUG_O(15 downto 4) <= (others => '0');

  
  
end;  

