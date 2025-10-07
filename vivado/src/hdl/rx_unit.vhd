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
    --clock and active-high reset
    ACLK                   : in std_logic;
    RST_I                  : in std_logic;

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
  signal clk                : std_logic;
  signal rst                : std_logic;

  signal uart_data          : uart_data_array_t  := (others => (others => '0'));
  signal timestamp          : rx_timestamp_array_t;

  signal valid              : std_logic_vector(C_RX_NUM_CHAN-1 downto 0) := (others => '0');
  signal ready              : std_logic_vector(C_RX_NUM_CHAN-1 downto 0) := (others => '0');
  signal uart_statuses      : uart_reg_array_t;
  signal uart_configs       : uart_reg_array_t := (others => (others => '0'));
  signal uart_chans         : uart_small_array_t := (others => (others => '0'));

  signal buffer_config      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal buffer_enables     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal buffer_status      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal buffer_chan_select : std_logic_vector(C_SELECT_WIDTH-1 downto 0);
  signal buffer_header      : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0) := (others => '0');
  signal buffer_frag_a      : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0) := (others => '0');
  signal buffer_frag_b      : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0) := (others => '0');

  signal heartbeat_config   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rollover_config    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal pacman             : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal word_type_lut      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal heartbeat_header   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rollover_header    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal eop_header         : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal look_chan_select   : std_logic_vector(C_SELECT_WIDTH-1 downto 0);
  signal look_uart_data     : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
  signal word_type          : std_logic_vector(C_BYTE-1 downto 0);

  component rx_buffer is
    port (
      CLK_I              : in std_logic;
      RST_I              : in std_logic;
      M_AXIS_TDATA       : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      M_AXIS_TVALID      : out std_logic;
      M_AXIS_TREADY      : in  std_logic;
      M_AXIS_TKEEP       : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
      M_AXIS_TLAST       : out std_logic;
      STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CONFIG_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CHAN_SELECT_O      : out std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      HEADER_I           : in  std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      FRAG_A_I           : in  std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      FRAG_B_I           : in  std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      VALID_I            : in  std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      READY_O            : out std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      EOP_HEADER_I       : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DEBUG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  component rx_registers is
    port (
      CLK_I	          : in std_logic;
      RST_I	          : in std_logic;

      S_REGBUS_RB_RADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE : in  std_logic;
      S_REGBUS_RB_RACK    : out std_logic;

      S_REGBUS_RB_WUPDATE : in  std_logic;
      S_REGBUS_RB_WADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	  : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK    : out std_logic;

      UART_STATUS_I       : in  uart_reg_array_t;
      UART_CONFIG_O       : out uart_reg_array_t;
      UART_CHAN_O         : out uart_small_array_t;

      BUFFER_STATUS_I     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      FIFO_COUNT_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BUFFER_CONFIG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BUFFER_ENABLES_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      PACMAN_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEARTBEAT_CONFIG_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ROLLOVER_CONFIG_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      WORD_TYPE_LUT_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEARTBEAT_HEADER_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ROLLOVER_HEADER_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      EOP_HEADER_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LOOK_SELECT_O       : out std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      LOOK_UART_DATA_I    : in std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
      );
  end component;

  component rx_chan is
    port (
      CLK_I       : in  std_logic;
      RST_I       : in  std_logic;
      CONFIG_I    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DATA_O      : out  std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
      TIMESTAMP_O : out  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      VALID_O     : out std_logic;
      READY_I     : in  std_logic;
      RX_I        : in  std_logic;
      LOOPBACK_I  : in  std_logic;
      TIMESTAMP_I : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      DEBUG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  component rx_header is
    port (
      CLK_I      : in std_logic;
      RST_I      : in std_logic;
      SEL_I      : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      WTYPE_I    : in  std_logic_vector(C_BYTE-1 downto 0);
      HEADER_A_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEADER_B_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEADER_C_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      HEADER_D_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      PACMAN_I   : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CHAN_I     : in uart_small_array_t;
      HEADER_O   : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
    );
  end component;

  component rx_timestamp_mux is
    port (
      CLK_I       : in std_logic;
      RST_I       : in std_logic;
      SEL_I       : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      TIMESTAMP_I : in  rx_timestamp_array_t;
      TIMESTAMP_O : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
    );
  end component;

  component rx_data_mux is
    port (
      CLK_I      : in std_logic;
      RST_I      : in std_logic;
      SEL_A_I    : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      SEL_B_I    : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      DATA_I     : in  uart_data_array_t;
      DATA_A_O   : out std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
      DATA_B_O   : out std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
      LUT_I      : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      WTYPE_A_O  : out std_logic_vector(C_BYTE-1 downto 0)
    );
  end component;


  component heartbeat is
    port (
      CLK_I       : in  std_logic;
      RST_I       : in  std_logic;
      EN_I        : in  std_logic;
      CONFIG_I    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      TIMESTAMP_O : out  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      VALID_O     : out std_logic;
      READY_I     : in  std_logic;
      TIMESTAMP_I : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      DEBUG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

  component rollover is
    port (
      CLK_I       : in  std_logic;
      RST_I       : in  std_logic;
      EN_I        : in  std_logic;
      CONFIG_I    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      TIMESTAMP_O : out  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      VALID_O     : out std_logic;
      READY_I     : in  std_logic;
      TIMESTAMP_I : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      DEBUG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;

begin
  clk <= ACLK;
  rst <= RST_I;

  uut: rx_buffer port map (
    CLK_I           => clk,
    RST_I           => rst,
    M_AXIS_TDATA    => M_AXIS_TDATA,
    M_AXIS_TVALID   => M_AXIS_TVALID,
    M_AXIS_TREADY   => M_AXIS_TREADY,
    M_AXIS_TKEEP    => M_AXIS_TKEEP,
    M_AXIS_TLAST    => M_AXIS_TLAST,
    STATUS_O        => buffer_status,
    CONFIG_I        => buffer_config,
    CHAN_SELECT_O   => buffer_chan_select,
    HEADER_I        => buffer_header,
    FRAG_A_I        => buffer_frag_a,
    FRAG_B_I        => buffer_frag_b,
    VALID_I         => valid,
    READY_O         => ready,
    EOP_HEADER_I    => eop_header
    );

  reg0: rx_registers port map (
    CLK_I               => clk,
    RST_I               => rst,
    S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
    S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
    S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
    S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
    S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
    S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
    S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
    S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,
    UART_STATUS_I       => uart_statuses,
    UART_CONFIG_O       => uart_configs,
    UART_CHAN_O         => uart_chans,
    BUFFER_STATUS_I     => buffer_status,
    FIFO_COUNT_I        => FIFO_COUNT_I,
    BUFFER_CONFIG_O     => buffer_config,
    BUFFER_ENABLES_O    => buffer_enables,
    PACMAN_O            => pacman,
    HEARTBEAT_CONFIG_O  => heartbeat_config,
    ROLLOVER_CONFIG_O   => rollover_config,
    WORD_TYPE_LUT_O     => word_type_lut,
    HEARTBEAT_HEADER_O  => heartbeat_header,
    ROLLOVER_HEADER_O   => rollover_header,
    EOP_HEADER_O        => eop_header,
    LOOK_SELECT_O       => look_chan_select,
    LOOK_UART_DATA_I    => look_uart_data
    );

  grxchan0: for i in 0 to C_NUM_UART-1 generate
    rxchan0: rx_chan
      port map(
        CLK_I         => clk,
        RST_I         => rst,
        CONFIG_I      => uart_configs(i),
        STATUS_O      => uart_statuses(i),
        DATA_O        => uart_data(i),
        TIMESTAMP_O   => timestamp(i),
        VALID_O       => valid(i),
        READY_I       => ready(i),
        RX_I          => PISO_I(i),
        LOOPBACK_I    => LOOPBACK_I(i),
        TIMESTAMP_I   => TIMESTAMP_I
        );
  end generate grxchan0;

  h0: rx_header port map (
    CLK_I      => clk,
    RST_I      => rst,
    SEL_I      => buffer_chan_select,
    WTYPE_I    => word_type,
    HEADER_A_I => heartbeat_header,
    HEADER_B_I => rollover_header,
    HEADER_C_I => (others => '0'),
    HEADER_D_I => (others => '0'),
    PACMAN_I   => pacman,
    CHAN_I     => uart_chans,
    HEADER_O   => buffer_header
  );

  ts0: rx_timestamp_mux port map (
    CLK_I           => clk,
    RST_I           => rst,
    SEL_I           => buffer_chan_select,
    TIMESTAMP_I     => timestamp,
    TIMESTAMP_O     => buffer_frag_a
  );

  dm0: rx_data_mux port map (
    CLK_I           => clk,
    RST_I           => rst,
    SEL_A_I         => buffer_chan_select,
    SEL_B_I         => look_chan_select,
    DATA_I          => uart_data,
    DATA_A_O        => buffer_frag_b,
    DATA_B_O        => look_uart_data,
    LUT_I           => word_type_lut,
    WTYPE_A_O       => word_type
  );

  hb0: heartbeat port map (
    CLK_I         => clk,
    RST_I         => rst,
    EN_I          => buffer_enables(0),
    CONFIG_I      => heartbeat_config,
    TIMESTAMP_O   => timestamp(40),
    VALID_O       => valid(40),
    READY_I       => ready(40),
    TIMESTAMP_I   => TIMESTAMP_I
    );

  ro0: rollover port map (
    CLK_I         => clk,
    RST_I         => rst,
    EN_I          => buffer_enables(1),
    CONFIG_I      => rollover_config,
    TIMESTAMP_O   => timestamp(41),
    VALID_O       => valid(41),
    READY_I       => ready(41),
    TIMESTAMP_I   => TIMESTAMP_I
    );


end behaviour;
