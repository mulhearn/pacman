library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
use work.common.all;

-- tx_unit:  PACMAN transmitter (TX) features
--
-- register controlled configuration for TX unit
-- register accessible status and monitoring of TX unit
-- AXI stream input containing data to TX (from PS)
-- TX output for each UART channel (POSI)


entity tx_unit is
  port (
    --clock and reset
    S_AXIS_ACLK          : in std_logic;
    S_AXIS_ARESETN       : in std_logic;

    --ASIC clock (slower than ACLK)
    UCLK_I               : in  std_logic;

    -- AXI Stream containing data to transmit
    S_AXIS_TDATA         : in std_logic_vector(C_TX_AXIS_WIDTH-1 downto 0);
    S_AXIS_TVALID        : in std_logic;
    S_AXIS_TREADY        : out std_logic;
    S_AXIS_TKEEP         : in std_logic_vector(C_TX_AXIS_WIDTH/8-1 downto 0);
    S_AXIS_TLAST         : in std_logic;

    -- register bus (REGBUS) interface
    S_REGBUS_RB_RADDR	 : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	 : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RUPDATE  : in  std_logic;
    S_REGBUS_RB_RACK     : out std_logic;

    S_REGBUS_RB_WUPDATE  : in  std_logic;
    S_REGBUS_RB_WADDR	 : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	 : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK     : out std_logic;

    -- POSI output for all registers:
    POSI_O               : out std_logic_vector(C_NUM_UART-1 downto 0);

    -- Debugging:
    DEBUG_O	         : out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
end tx_unit;

-- This integration module contains submodules tx_registers,
-- tx_buffer, and tx_chan.  There is one instance of tx_chan for each
-- UART channel, implemented via the VHDL generate mechanism.

architecture behaviour of tx_unit is
  signal data        : uart_data_array_t := (others => (others => '0'));
  signal valid       : std_logic_vector(C_NUM_UART-1 downto 0) := (others => '0');
  signal ready       : std_logic_vector(C_NUM_UART-1 downto 0) := (others => '0');
  signal status      : uart_reg_array_t := (others => (others => '0'));
  signal gstatus     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal config      : uart_reg_array_t;

  component tx_buffer is
    port (
      S_AXIS_ACLK        : in std_logic;
      S_AXIS_ARESETN     : in std_logic;

      S_AXIS_TDATA       : in std_logic_vector(C_TX_AXIS_WIDTH-1 downto 0);
      S_AXIS_TVALID      : in std_logic;
      S_AXIS_TREADY      : out std_logic;
      S_AXIS_TKEEP       : in std_logic_vector(C_TX_AXIS_WIDTH/8-1 downto 0);
      S_AXIS_TLAST       : in std_logic;

      STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      DATA_O             : out uart_data_array_t;
      VALID_O            : out std_logic_vector(C_NUM_UART-1 downto 0);
      READY_I            : in std_logic_vector(C_NUM_UART-1 downto 0);

      DEBUG_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)

      );
  end component;

  component tx_registers is
    port (
      ACLK	        : in std_logic;
      ARESETN	        : in std_logic;

      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;

      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      UART_LOOK_I            : in uart_data_array_t;
      UART_STATUS_I          : in uart_reg_array_t;
      BUFFER_STATUS_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      UART_CONFIG_O          : out uart_reg_array_t
      );
  end component;

  component tx_chan is
    port (
      ACLK          : in  std_logic;
      ARESETN       : in  std_logic;
      UCLK_I        : in  std_logic;
      CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DATA_I        : in  std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
      VALID_I       : in  std_logic;
      READY_O       : out std_logic;
      TX_O          : out std_logic;
      DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;


begin
  uut: tx_buffer port map (
    S_AXIS_ACLK     => S_AXIS_ACLK,
    S_AXIS_ARESETN  => S_AXIS_ARESETN,
    S_AXIS_TDATA    => S_AXIS_TDATA,
    S_AXIS_TVALID   => S_AXIS_TVALID,
    S_AXIS_TREADY   => S_AXIS_TREADY,
    S_AXIS_TKEEP    => S_AXIS_TKEEP,
    S_AXIS_TLAST    => S_AXIS_TLAST,
    DATA_O          => data,
    STATUS_O        => gstatus,
    VALID_O         => valid,
    READY_I         => ready
  );

  uut0: tx_registers port map (
    ACLK                => S_AXIS_ACLK,
    ARESETN             => S_AXIS_ARESETN,
    S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
    S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
    S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
    S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
    S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
    S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
    S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
    S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,
    UART_LOOK_I  => data,
    --UART_LOOK_I  => (others => (others => '0')),
    UART_STATUS_I  => status,
    BUFFER_STATUS_I => gstatus,
    UART_CONFIG_O  => config
  );

  -- generate C_NUM_UART instances of tx_chan and connect to appropriate signals.
  gtxchan0: for i in 0 to C_NUM_UART-1 generate
    txchan0: tx_chan
      port map(
        ACLK       => S_AXIS_ACLK,
        ARESETN    => S_AXIS_ARESETN,
        UCLK_I     => UCLK_I,
        CONFIG_I   => config(i),
        STATUS_O   => status(i),
        DATA_I     => data(i),
        VALID_I    => valid(i),
        READY_O    => ready(i),
        TX_O       => POSI_O(i)
        );
  end generate gtxchan0;

end behaviour;

