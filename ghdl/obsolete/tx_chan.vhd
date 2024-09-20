library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity tx_chan is
  generic (
    constant C_UART_CHANNEL    : integer  range 0 to C_NUM_UART-1 := 0
  );
  port (
    ACLK          : in std_logic;
    ARESETN       : in std_logic;
    UCLK_I        : in std_logic;

    CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    COMMAND_I     : in  std_logic_vector(C_COMMAND_WIDTH-1 downto 0);
    STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    
    CYCLES_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    BUSYS_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    ACKS_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    

    LOOK_O        : out std_logic_vector(C_TX_CHAN_DATA_WIDTH-1 downto 0);        
    SEND_I        : in std_logic_vector(C_TX_CHAN_DATA_WIDTH-1 downto 0);
    TX_O          : out std_logic;

    DEBUG_O       : out  std_logic_vector(15 downto 0)
  );
end;

architecture behavioral of tx_chan is
  component tx_buffer is
    port (
      ACLK        : in std_logic;
      ARESETN     : in std_logic;
      UCLK_I      : in std_logic;
      CONFIG_I    : in std_logic_vector(C_TX_BUFFER_CONFIG_WIDTH-1 downto 0);
      DATA_I      : in std_logic_vector(C_TX_CHAN_DATA_WIDTH-1 downto 0);      
      VALID_I     : in std_logic;
      ACK_O       : out std_logic;
      TX_O        : out std_logic;
      MON_BUSY_O  : out std_logic;
      DEBUG_O     : out  std_logic_vector(15 downto 0)
    );
  end component;

  signal clk         : std_logic;
  signal rst         : std_logic;
  signal rst_q       : std_logic := '0';
  
  signal tx          : std_logic;
  signal data        : std_logic_vector(C_TX_CHAN_DATA_WIDTH-1 downto 0) := (others => '0');
  signal look        : std_logic_vector(C_TX_CHAN_DATA_WIDTH-1 downto 0) := (others => '0');

  -- TX DATA CONTROL SIGNALS:
  signal valid        : std_logic := '0';
  signal busy         : std_logic;
  signal ack          : std_logic;
  
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
  signal tx_seen      : std_logic := '0';

  signal single_seen  : std_logic := '0';
  signal start_seen   : std_logic := '0';
  signal stop_seen    : std_logic := '0';
  
  signal count_ack_always : std_logic_vector(15 downto 0) := (others => '0'); 
  
begin
  txbuf0: tx_buffer
    port map(
      ACLK        => ACLK,
      ARESETN     => ARESETN,      
      UCLK_I      => UCLK_I,
      CONFIG_I    => CONFIG_I(C_TX_BUFFER_CONFIG_WIDTH-1 downto 0),
      DATA_I      => data,
      VALID_I     => valid,
      ACK_O       => ack,
      TX_O        => tx,
      MON_BUSY_O  => busy
    );
  clk <= ACLK;
  rst   <= not ARESETN;
  TX_O <= tx;
  LOOK_O <= look;

  -- Fill the LOOK buffer on every ack:  
  process(clk)
    variable mode : integer range 0 to 9 := 0;
  begin
    if (rst='1') then
      look  <= (others => '0');
    else
      if (rising_edge(clk)) then
        look <= data;
      end if;
    end if;   
  end process;
  
  -- Fill the TX buffer according to configuration settings:  
  process(clk)
    variable mode : integer range 0 to 9 := 0;
  begin
    mode := to_integer(unsigned(CONFIG_I(14 downto 12)));
      
    if (rst='1' or clear='1') then
      data  <= (others => '0');
      valid <= '0';
    else
      if (rising_edge(clk)) then
        if (mode = 3) then
          -- Mode 3:  Continuous Transmission
          data  <= SEND_I;
          valid <= '1';
        elsif (mode = 2) then
          -- Mode 2:  Single Shot Transmission        
          if (single='1' and valid='0') then
            data  <= SEND_I;
            valid <= '1';
          elsif (ack='1') then
            valid <= '0';
          end if;          
        else
          -- Mode 0: Diable TX
          data <= (others => '0');
          valid <= '0';          
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
  STATUS_O(3) <= tx;

  STATUS_O(4) <= valid_seen;
  STATUS_O(5) <= busy_seen; 
  STATUS_O(6) <= ack_seen;  
  STATUS_O(7) <= tx_seen;   

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
      tx_seen       <= '0';  
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
        if (tx='0') then
          tx_seen    <= '1';    
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
    variable cycles  : integer := 0;
    variable busys   : integer := 0;
    variable acks    : integer := 0;
  begin
    if (rst='1' or clear='1') then
      cycles := 0;
      busys  := 0;
      acks   := 0;
    else
      if (rising_edge(clk)) then
        CYCLES_O  <= std_logic_vector(to_unsigned(cycles, C_RB_DATA_WIDTH));
        BUSYS_O   <= std_logic_vector(to_unsigned(busys,   C_RB_DATA_WIDTH));
        ACKS_O    <= std_logic_vector(to_unsigned(acks,   C_RB_DATA_WIDTH));
        if (running='1') then
          cycles := cycles + 1;
          if (busy='1') then
            busys := busys + 1;
          end if;
          if (ack='1') then
            acks := acks + 1;
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

