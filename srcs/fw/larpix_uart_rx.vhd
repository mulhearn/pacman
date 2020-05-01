library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_uart_rx is
  generic (
    C_CLK_HZ : integer := 100000000;
    C_CLKIN_HZ : integer := 10000000;
    C_CHANNEL : std_logic_vector (7 downto 0) := x"FF";
    C_DATA_TYPE : std_logic_vector (7 downto 0) := x"44";
    C_LARPIX_DATA_WIDTH : integer := 64;
    C_M_AXIS_TDATA_WIDTH : integer := 128
    );
  port (
    --C_CHANNEL : in std_logic_vector (7 downto 0) := x"FF";
    
    ACLK : in std_logic;
    ARESETN : in std_logic;

    -- uart
    MCLK : in std_logic;
    CLKIN_RATIO : in unsigned (7 downto 0);
    PACMAN_TS : in unsigned (31 downto 0);
    UART_RX_IN : in std_logic;

    -- axi-stream master
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TKEEP : out std_logic_vector(C_M_AXIS_TDATA_WIDTH/8-1 downto 0);
    M_AXIS_TSTRB : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M_AXIS_TLAST : out std_logic;
    M_AXIS_TREADY : in std_logic    
    );
end entity larpix_uart_rx;

architecture arch_imp of larpix_uart_rx is

  attribute ASYNC_REG : string;

  component larpix_to_axi_stream is
    generic (
      C_M_AXIS_TDATA_WIDTH : integer;
      C_LARPIX_DATA_WIDTH : integer;
      C_M_AXIS_TDATA_TYPE : std_logic_vector(7 downto 0) := C_DATA_TYPE;
      C_M_AXIS_TDATA_CHANNEL  : std_logic_vector(7 downto 0) := C_CHANNEL
      );
    port (
      --C_M_AXIS_TDATA_CHANNEL  : in std_logic_vector(7 downto 0) := C_CHANNEL;
      
      timestamp : in unsigned(31 downto 0) := (others => '0');
      data_LArPix : in std_logic_vector(C_LARPIX_DATA_WIDTH-1 downto 0);
      data_update_LArPix : in std_logic;
      busy_LArPix : out std_logic;
      M_AXIS_ACLK : in std_logic;
      M_AXIS_ARESETN : in std_logic;

      M_AXIS_TVALID : out std_logic;
      M_AXIS_TDATA : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
      M_AXIS_TKEEP : out std_logic_vector(C_M_AXIS_TDATA_WIDTH/8-1 downto 0);
      M_AXIS_TSTRB : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
      M_AXIS_TLAST : out std_logic;
      M_AXIS_TREADY : in std_logic
      );
  end component larpix_to_axi_stream;

  component uart_rx is
    generic (
      CLK_Hz     : INTEGER := C_CLK_HZ;
      CLKIN_Hz   : INTEGER := C_CLKIN_HZ;
      DATA_WIDTH : INTEGER := C_LARPIX_DATA_WIDTH
      );
    port (
      CLK         : IN  STD_LOGIC;
      RST         : IN  STD_LOGIC;
      CLKIN_RATIO : IN  UNSIGNED (7 DOWNTO 0);

      RX          : IN  STD_LOGIC;

      data        : OUT STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
      data_update : OUT STD_LOGIC;

      TC          : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
      );
  end component uart_rx;
    
  signal rst : std_logic;
  signal larpix_data : std_logic_vector (C_LARPIX_DATA_WIDTH-1 downto 0);
  signal larpix_update : std_logic;
  signal larpix_busy : std_logic;

  signal pacman_ts_meta : unsigned(PACMAN_TS'length-1 downto 0);
  signal pacman_ts_aclk : unsigned(PACMAN_TS'length-1 downto 0);

  attribute ASYNC_REG of pacman_ts_meta: signal is "TRUE";
  attribute ASYNC_REG of pacman_ts_aclk: signal is "TRUE";

begin
  -- reset
  rst <= not ARESETN;

  -- uart receiver
  uart_rx_inst : uart_rx port map(
    CLK => ACLK,
    RST => rst,
    CLKIN_RATIO => CLKIN_RATIO,
    RX => UART_RX_IN,
    data => larpix_data,
    data_update => larpix_update,
    TC => open
    );

  -- axi-stream driver
  -- sync timestamp
  aclk_pacman_ts_sync : process (ACLK) is
  begin
    if (rising_edge(ACLK)) then
      pacman_ts_meta <= PACMAN_TS;
      pacman_ts_aclk <= pacman_ts_meta;
    end if;
  end process;

  -- generate axi stream
  larpix_to_axi_stream_inst : larpix_to_axi_stream generic map(
    C_M_AXIS_TDATA_WIDTH => C_M_AXIS_TDATA_WIDTH,
    C_LARPIX_DATA_WIDTH => C_LARPIX_DATA_WIDTH
  )
  port map(
    timestamp => pacman_ts_aclk,
    data_LArPix => larpix_data,
    data_update_LArPix => larpix_update,
    busy_larpix => larpix_busy,
    M_AXIS_ACLK => ACLK,
    M_AXIS_ARESETN => ARESETN,
    M_AXIS_TVALID => M_AXIS_TVALID,
    M_AXIS_TDATA => M_AXIS_TDATA,
    M_AXIS_TKEEP => M_AXIS_TKEEP,
    M_AXIS_TSTRB => M_AXIS_TSTRB,
    M_AXIS_TLAST => M_AXIS_TLAST,
    M_AXIS_TREADY =>  M_AXIS_TREADY
    );

end architecture arch_imp;
