library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity rx_unit is
  port (
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK    : out  std_logic;
    
    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out  std_logic;

    M_AXIS_TDATA       : out std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0);      
    M_AXIS_TVALID      : out std_logic;
    M_AXIS_TREADY      : in std_logic;
    M_AXIS_TKEEP       : out std_logic_vector(C_RX_CHAN_DATA_WIDTH/8-1 downto 0);      
    M_AXIS_TLAST       : out std_logic;
    
    LOOPBACK_I            : in std_logic_vector(C_NUM_UART-1 downto 0);
    PISO_I                : in std_logic_vector(C_NUM_UART-1 downto 0);
    --
    DEBUG_O               : out  std_logic_vector(31 downto 0)
    );
end;

architecture behavioral of rx_unit is
  component axis_write is
    generic (
      C_AXIS_WIDTH  : integer  := C_RX_CHAN_DATA_WIDTH
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
      DEBUG_O            : out std_logic_vector(7 downto 0)      
    );  
  end component;
  
  component rx_registers is
    port (
      ACLK	        : in std_logic;
      ARESETN	        : in std_logic;
      
      S_REGBUS_RB_RADDR	     : in  std_logic_vector(15 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(31 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;
      
      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(15 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(31 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;
      
      STATUS_I               : in  uart_reg_array_t;
      COUNT_I                : in  uart_rx_count_array_t;
      
      CONFIG_O               : out uart_reg_array_t;
      LOOK_I                 : in  uart_rx_data_array_t;
      COMMAND_O              : out uart_command_array_t      
    );  
  end component;

  component rx_chan is
    generic (
      constant C_UART_CHANNEL    : integer  range 0 to C_NUM_UART-1
      );    
    port (
      ACLK        : in std_logic;
      ARESETN     : in std_logic;
      CONFIG_I    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      COMMAND_I   : in  std_logic_vector(C_COMMAND_WIDTH-1 downto 0);
      STATUS_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      COUNT_O     : out std_logic_vector(C_RX_CHAN_COUNT_WIDTH-1 downto 0);

      BUSY_I      : in  std_logic;
      TURN_I      : in  std_logic_vector(C_UART_CHAN_ADDR_WIDTH-1 downto 0);
      WEN_O       : out std_logic;
      
      DATA_O      : out std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0);        
      RX_I        : in  std_logic;
      DEBUG_O     : out  std_logic_vector(15 downto 0)
    );  
  end component;
  
  signal clk      : std_logic;
  signal rst      : std_logic;

  -- registers
  signal status    : uart_reg_array_t := (others => x"FFFFFFFF");
  signal count     : uart_rx_count_array_t;
  signal config    : uart_reg_array_t;
  signal command   : uart_command_array_t;

  -- rx data
  signal data      : uart_rx_data_array_t := (others => x"DDDDDDDDCCCCCCCCBBBBBBBBAAAAAAAA");

  signal wen       : std_logic_vector(C_NUM_UART-1 downto 0);
  signal busy      : std_logic;
  signal turn      : std_logic_vector(C_UART_CHAN_ADDR_WIDTH-1 downto 0);


  -- data and wen selected for the current turn:
  signal data_turn : std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0);        
  signal wen_turn  : std_logic;
  
begin
  reg0: rx_registers port map (
    ACLK           => ACLK,
    ARESETN        => ARESETN,
    S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
    S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
    S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
    S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
    S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
    S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
    S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
    S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,
    STATUS_I            => status,
    CONFIG_O            => config,
    COUNT_I             => count,

    LOOK_I              => data,
    COMMAND_O           => command
  );

  axis0: axis_write port map (
      M_AXIS_ACLK     => ACLK,
      M_AXIS_ARESETN  => ARESETN,
      M_AXIS_TDATA    => M_AXIS_TDATA,
      M_AXIS_TVALID   => M_AXIS_TVALID,
      M_AXIS_TREADY   => M_AXIS_TREADY,
      M_AXIS_TKEEP    => M_AXIS_TKEEP,
      M_AXIS_TLAST    => M_AXIS_TLAST,
      BUSY_O          => busy, 
      WEN_I           => '0',
      LAST_I          => '0',
      DATA_I          => (others => '0')
  );
  
  clk <= ACLK;
  rst <= not ARESETN;  

  grxchan0: for i in 0 to 39 generate
    rxchan0: rx_chan
    generic map (
      C_UART_CHANNEL => i
    )
    port map (
      ACLK       => aclk,
      ARESETN    => aresetn,
      CONFIG_I   => config(i),
      COMMAND_I  => command(i),
      STATUS_O   => status(i),
      COUNT_O    => count(i),
      BUSY_I     => busy,
      TURN_I     => turn,
      WEN_O      => wen(i),
      DATA_O     => data(i),
      RX_I       => PISO_I(i)
    );
  end generate grxchan0;


  process(clk)
    variable turn_count : integer range 0 to 63 := 0;
  begin
    if (rst='1') then
      turn_count := 0;
    elsif (rising_edge(clk)) then
      turn <= std_logic_vector(to_unsigned(turn_count, turn'length));
      turn_count := (turn_count + 1) mod 64;
      if (turn_count < 40) then
        wen_turn  <= wen(0);
        data_turn <= data(0);
      else
        wen_turn  <= '0';
        data_turn <= (others => '0');        
      end if;      
    end if;
  end process;

  DEBUG_O( 5 downto 0)  <= turn;
  DEBUG_O( 7 downto 6)  <= (others => '0');
  DEBUG_O(15 downto 8)  <= data(0)(127 downto 120);
  DEBUG_O(23 downto 16) <= data_turn(127 downto 120);  
  DEBUG_O(24)           <= wen(0);
  DEBUG_O(25)           <= wen_turn;
  

  
end;  
