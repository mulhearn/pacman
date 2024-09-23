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

    TIMESTAMP_I            : in  std_logic_vector(31 downto 0);
    FIFO_RCNT_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    FIFO_WCNT_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DMA_ITR_I              : in  std_logic;

    PISO_I                 : in  std_logic_vector(C_NUM_UART-1 downto 0)
  );
end rx_unit;

architecture behaviour of rx_unit is
  signal data    : uart_rx_data_array_t;
  signal valid   : std_logic_vector(C_NUM_UART-1 downto 0);
  signal ready   : std_logic_vector(C_NUM_UART-1 downto 0);
  signal status  : uart_reg_array_t;
  signal config  : uart_reg_array_t := (others => (others => '0'));
  signal gflags  : std_logic_vector(C_RX_GFLAGS_WIDTH-1 downto 0);
  signal gstatus : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
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
      GCONFIG_I          : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      GFLAGS_I           : in  std_logic_vector(C_RX_GFLAGS_WIDTH-1 downto 0);
      LOOK_O             : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);
      
      DATA_I             : in  uart_rx_data_array_t;
      VALID_I            : in  std_logic_vector(C_NUM_UART-1 downto 0);
      READY_O            : out std_logic_vector(C_NUM_UART-1 downto 0);

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
      GFLAGS_O            : out std_logic_vector(C_RX_GFLAGS_WIDTH-1 downto 0);
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
    DATA_I          => data,
    STATUS_O        => gstatus,
    GFLAGS_I        => gflags,
    GCONFIG_I       => (others => '0'),
    VALID_I         => valid,
    READY_O         => ready
  );

  uut0: rx_registers port map (
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
    GFLAGS_O => gflags,
    FIFO_RCNT_I => FIFO_RCNT_I,
    FIFO_WCNT_I => FIFO_WCNT_I,
    DMA_ITR_I   => DMA_ITR_I
  );

  grxchan0: for i in 0 to C_NUM_UART-1 generate
    rxchan0: rx_chan
      generic map(
        CHANNEL=>i
      )
      port map(
        ACLK          => M_AXIS_ACLK,
        ARESETN       => M_AXIS_ARESETN,
        CONFIG_I      => config(i),
        STATUS_O      => status(i),
        GFLAGS_I      => gflags,
        DATA_O        => data(i),
        VALID_O       => valid(i),
        READY_I       => ready(i),
        RX_I          => PISO_I(i),
        TIMESTAMP_I   => TIMESTAMP_I
      );
  end generate grxchan0;

end behaviour;
