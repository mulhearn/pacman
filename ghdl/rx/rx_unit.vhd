library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
use work.common.all;

-- rx_unit:  PACMAN receiver (RX) features
--
-- register controlled configuration for RX unit
-- register accessible status and monitoring of RX unit
-- RX input for each UART channel (PISO)
-- AXI stream output containing data from RX (out to PS)
-- inputs time stamp from timing unit which is used to mark data
-- inputs the RX FIFO word count for monitoring

entity rx_unit is
  port (
    --clock and reset
    M_AXIS_ACLK            : in std_logic;
    M_AXIS_ARESETN         : in std_logic;

    -- AXI Stream containing data received
    M_AXIS_TDATA           : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
    M_AXIS_TVALID          : out std_logic;
    M_AXIS_TREADY          : in std_logic;
    M_AXIS_TKEEP           : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
    M_AXIS_TLAST           : out std_logic;

    --register bus (REGBUS) interface:
    S_REGBUS_RB_RADDR      : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RUPDATE    : in  std_logic;
    S_REGBUS_RB_RACK       : out std_logic;

    S_REGBUS_RB_WUPDATE    : in  std_logic;
    S_REGBUS_RB_WADDR      : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK       : out std_logic;

    -- timestamp from timing unit
    TIMESTAMP_I            : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    -- RX FIFO word count
    FIFO_COUNT_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- RX input (PISO) for each UART channel:
    PISO_I                 : in  std_logic_vector(C_NUM_UART-1 downto 0);

    -- TX output (POSI) from TX unit for loopback option:
    LOOPBACK_I             : in  std_logic_vector(C_NUM_UART-1 downto 0)
    );
end rx_unit;

-- This integration module contains submodules rx_registers,
-- rx_buffer, rx_chan, heartbeat, and rollover.  There is one instance
-- of rx_chan for each UART channel, implemented via the VHDL generate
-- mechanism.

architecture behaviour of rx_unit is
  signal header           : rx_header_array_t;
  signal data             : rx_data_array_t;
  signal timestamp        : rx_timestamp_array_t;
  signal valid            : std_logic_vector(C_RX_NUM_CHAN-1 downto 0) := (others => '0');
  signal ready            : std_logic_vector(C_RX_NUM_CHAN-1 downto 0) := (others => '0');
  signal ustatus          : uart_reg_array_t;
  signal uconfig          : uart_reg_array_t := (others => (others => '0'));
  signal bconfig          : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal bstatus          : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal heartbeat_config : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rollover_config  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  component rx_buffer is
    port (
      M_AXIS_ACLK        : in std_logic;
      M_AXIS_ARESETN     : in std_logic;
      M_AXIS_TDATA       : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      M_AXIS_TVALID      : out std_logic;
      M_AXIS_TREADY      : in  std_logic;
      M_AXIS_TKEEP       : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
      M_AXIS_TLAST       : out std_logic;
      STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CONFIG_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LOOK_O             : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      -- the received data from the UART receivers and extra channels
      HEADER_I           : in  rx_header_array_t;
      DATA_I             : in  rx_data_array_t;
      TIMESTAMP_I        : in  rx_timestamp_array_t;
      VALID_I            : in  std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      READY_O            : out std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      DEBUG_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DEBUG_DATA_O       : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
      );
  end component;

  component rx_registers is
    port (
      ACLK	           : in std_logic;
      ARESETN	           : in std_logic;

      S_REGBUS_RB_RADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE  : in  std_logic;
      S_REGBUS_RB_RACK     : out std_logic;

      S_REGBUS_RB_WUPDATE  : in  std_logic;
      S_REGBUS_RB_WADDR	   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK     : out std_logic;

      UART_LOOK_I          : in rx_data_array_t;
      UART_STATUS_I        : in uart_reg_array_t;
      UART_CONFIG_O        : out uart_reg_array_t;
      BUFFER_CONFIG_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEARTBEAT_CONFIG_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ROLLOVER_CONFIG_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BUFFER_STATUS_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FIFO_COUNT_I         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  component rx_chan is
    generic (
      constant CHANNEL : integer := 1;
      constant HEADER  : integer := C_TYPE_DATA
      );
    port (
      ACLK          : in  std_logic;
      ARESETN       : in  std_logic;
      CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEADER_O      : out  std_logic_vector(C_RX_HEADER_WIDTH-1 downto 0);
      DATA_O        : out  std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
      TIMESTAMP_O   : out  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      VALID_O       : out std_logic;
      READY_I       : in  std_logic;
      RX_I          : in  std_logic;
      LOOPBACK_I    : in  std_logic;
      TIMESTAMP_I   : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  component heartbeat is
    port (
      ACLK          : in  std_logic;
      ARESETN       : in  std_logic;
      EN_I          : in  std_logic;
      CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEADER_O      : out  std_logic_vector(C_RX_HEADER_WIDTH-1 downto 0);
      TIMESTAMP_O   : out  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      VALID_O       : out std_logic;
      READY_I       : in  std_logic;
      TIMESTAMP_I   : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  component rollover is
    port (
      ACLK          : in  std_logic;
      ARESETN       : in  std_logic;
      EN_I          : in  std_logic;
      CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEADER_O      : out  std_logic_vector(C_RX_HEADER_WIDTH-1 downto 0);
      TIMESTAMP_O   : out  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      VALID_O       : out std_logic;
      READY_I       : in  std_logic;
      TIMESTAMP_I   : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

begin
  uut: rx_buffer port map (
    M_AXIS_ACLK     => M_AXIS_ACLK,
    M_AXIS_ARESETN  => M_AXIS_ARESETN,
    M_AXIS_TDATA    => M_AXIS_TDATA,
    M_AXIS_TVALID   => M_AXIS_TVALID,
    M_AXIS_TREADY   => M_AXIS_TREADY,
    M_AXIS_TKEEP    => M_AXIS_TKEEP,
    M_AXIS_TLAST    => M_AXIS_TLAST,
    CONFIG_I        => bconfig,
    HEADER_I        => header,
    DATA_I          => data,
    TIMESTAMP_I     => timestamp,
    STATUS_O        => bstatus,
    VALID_I         => valid,
    READY_O         => ready
    );

  reg0: rx_registers port map (
    ACLK                => M_AXIS_ACLK,
    ARESETN             => M_AXIS_ARESETN,
    S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
    S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
    S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
    S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
    S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
    S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
    S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
    S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,
    UART_LOOK_I         => data,
    UART_STATUS_I       => ustatus,
    BUFFER_STATUS_I     => bstatus,
    UART_CONFIG_O       => uconfig,
    BUFFER_CONFIG_O     => bconfig,
    HEARTBEAT_CONFIG_O  => heartbeat_config,
    ROLLOVER_CONFIG_O   => rollover_config,
    FIFO_COUNT_I        => FIFO_COUNT_I
    );

  grxchan0: for i in 0 to C_NUM_UART-1 generate
    rxchan0: rx_chan
      generic map(
        CHANNEL=>(i+1)
        )
      port map(
        ACLK          => M_AXIS_ACLK,
        ARESETN       => M_AXIS_ARESETN,
        CONFIG_I      => uconfig(i),
        STATUS_O      => ustatus(i),
        HEADER_O      => header(i),
        DATA_O        => data(i),
        TIMESTAMP_O   => timestamp(i),
        VALID_O       => valid(i),
        READY_I       => ready(i),
        RX_I          => PISO_I(i),
        LOOPBACK_I    => LOOPBACK_I(i),
        TIMESTAMP_I   => TIMESTAMP_I
        );
  end generate grxchan0;

  hb0: heartbeat port map (
    ACLK          => M_AXIS_ACLK,
    ARESETN       => M_AXIS_ARESETN,
    EN_I          => bconfig(16),
    CONFIG_I      => heartbeat_config,
    HEADER_O      => header(40),
    TIMESTAMP_O   => timestamp(40),
    VALID_O       => valid(40),
    READY_I       => ready(40),
    TIMESTAMP_I   => TIMESTAMP_I
    );

  ro0: rollover port map (
    ACLK          => M_AXIS_ACLK,
    ARESETN       => M_AXIS_ARESETN,
    EN_I          => bconfig(17),
    CONFIG_I      => rollover_config,
    HEADER_O      => header(41),
    TIMESTAMP_O   => timestamp(41),
    VALID_O       => valid(41),
    READY_I       => ready(41),
    TIMESTAMP_I   => TIMESTAMP_I
    );


end behaviour;
