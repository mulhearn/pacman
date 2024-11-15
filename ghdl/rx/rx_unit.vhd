library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
use work.common.all;

entity rx_unit is
  port (
    M_AXIS_ACLK            : in std_logic;
    M_AXIS_ARESETN         : in std_logic;
    M_AXIS_TDATA           : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
    M_AXIS_TVALID          : out std_logic;
    M_AXIS_TREADY          : in std_logic;
    M_AXIS_TKEEP           : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
    M_AXIS_TLAST           : out std_logic;

    S_REGBUS_RB_RADDR      : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RUPDATE    : in  std_logic;
    S_REGBUS_RB_RACK       : out std_logic;

    S_REGBUS_RB_WUPDATE    : in  std_logic;
    S_REGBUS_RB_WADDR      : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK       : out std_logic;

    TIMESTAMP_I            : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    FIFO_RCNT_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    FIFO_WCNT_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DMA_ITR_I              : in  std_logic;

    PISO_I                 : in  std_logic_vector(C_NUM_UART-1 downto 0);
    LOOPBACK_I             : in  std_logic_vector(C_NUM_UART-1 downto 0)
  );
end rx_unit;

architecture behaviour of rx_unit is
  signal data    : uart_rx_data_array_t;
  signal valid   : std_logic_vector(C_RX_NUM_CHAN-1 downto 0) := (others => '0');
  signal ready   : std_logic_vector(C_RX_NUM_CHAN-1 downto 0) := (others => '0');
  signal status  : uart_reg_array_t;
  signal config  : uart_reg_array_t := (others => (others => '0'));
  signal gconfig : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal gstatus : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal heartbeat_cycles : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal sync_cycles       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  component rx_buffer is
    port (
      M_AXIS_ACLK        : in std_logic;
      M_AXIS_ARESETN     : in std_logic;
      M_AXIS_TDATA       : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      M_AXIS_TVALID      : out std_logic;
      M_AXIS_TREADY      : in std_logic;
      M_AXIS_TKEEP       : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
      M_AXIS_TLAST       : out std_logic;

      STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CONFIG_I           : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LOOK_O             : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);

      DATA_I             : in  uart_rx_data_array_t;
      VALID_I            : in  std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      READY_O            : out std_logic_vector(C_RX_NUM_CHAN-1 downto 0);

      DEBUG_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DEBUG_DATA_O       : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0)
    );
  end component;

  component rx_registers is
    port (
      ACLK	          : in std_logic;
      ARESETN	          : in std_logic;

      S_REGBUS_RB_RUPDATE : in  std_logic;
      S_REGBUS_RB_RADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RACK    : out std_logic;

      S_REGBUS_RB_WUPDATE : in  std_logic;
      S_REGBUS_RB_WADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	  : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK    : out std_logic;

      LOOK_I              : in  uart_rx_data_array_t;
      STATUS_I            : in  uart_reg_array_t;
      CONFIG_O            : out uart_reg_array_t;
      GCONFIG_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEARTBEAT_CYCLES_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SYNC_CYCLES_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      GSTATUS_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FIFO_RCNT_I         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FIFO_WCNT_I         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DMA_ITR_I           : in  std_logic
      );
  end component;

  component rx_chan is
    generic (
      constant CHANNEL : integer := 0
    );
    port (
      ACLK          : in  std_logic;
      ARESETN       : in  std_logic;
      CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      GFLAGS_I      : in  std_logic_vector(C_RX_GFLAGS_WIDTH-1 downto 0);
      DATA_O        : out  std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);
      VALID_O       : out  std_logic;
      READY_I       : in std_logic;
      RX_I          : in std_logic;
      LOOPBACK_I    : in std_logic;
      TIMESTAMP_I   : in  std_logic_vector(31 downto 0);
      DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  component heartbeat is
    port (
      ACLK          : in  std_logic;
      ARESETN       : in  std_logic;
      EN_I          : in  std_logic;
      CYCLES_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DATA_O        : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);
      VALID_O       : out std_logic;
      READY_I       : in  std_logic;
      TIMESTAMP_I   : in  std_logic_vector(31 downto 0);
      DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  component rollover is
    port (
      ACLK          : in  std_logic;
      ARESETN       : in  std_logic;
      EN_I          : in  std_logic;
      CYCLES_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DATA_O        : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);
      VALID_O       : out std_logic;
      READY_I       : in  std_logic;
      TIMESTAMP_I   : in  std_logic_vector(31 downto 0);
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
    CONFIG_I        => gconfig,
    DATA_I          => data,
    STATUS_O        => gstatus,
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
    LOOK_I  => data,
    STATUS_I  => status,
    GSTATUS_I  => gstatus,
    CONFIG_O  => config,
    GCONFIG_O => gconfig,
    HEARTBEAT_CYCLES_O => heartbeat_cycles,
    SYNC_CYCLES_O => sync_cycles,
    FIFO_RCNT_I => FIFO_RCNT_I,
    FIFO_WCNT_I => FIFO_WCNT_I,
    DMA_ITR_I   => DMA_ITR_I
  );

  grxchan0: for i in 0 to C_NUM_UART-1 generate
    rxchan0: rx_chan
      generic map(
        CHANNEL=>(i+1)
      )
      port map(
        ACLK          => M_AXIS_ACLK,
        ARESETN       => M_AXIS_ARESETN,
        CONFIG_I      => config(i),
        STATUS_O      => status(i),
        GFLAGS_I      => "00",
        DATA_O        => data(i),
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
    EN_I          => gconfig(16),
    CYCLES_I      => heartbeat_cycles,
    DATA_O        => data(40),
    VALID_O       => valid(40),
    READY_I       => ready(40),
    TIMESTAMP_I   => TIMESTAMP_I
  );

  ro0: rollover port map (
    ACLK          => M_AXIS_ACLK,
    ARESETN       => M_AXIS_ARESETN,
    EN_I          => gconfig(17),
    CYCLES_I      => sync_cycles,
    DATA_O        => data(41),
    VALID_O       => valid(41),
    READY_I       => ready(41),
    TIMESTAMP_I   => TIMESTAMP_I
  );


end behaviour;
