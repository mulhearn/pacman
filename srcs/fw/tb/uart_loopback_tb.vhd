library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_loopback_tb is port (
      M_AXIS_TVALID       : out std_logic;
      M_AXIS_TDATA        : out std_logic_vector(127 downto 0);
      M_AXIS_TKEEP        : out std_logic_vector(15 downto 0);
      M_AXIS_TSTRB        : out std_logic_vector(15 downto 0);
      M_AXIS_TLAST        : out std_logic;
      FIFO_COUNT          : out std_logic_vector(8 downto 0)
      );
end uart_loopback_tb;

architecture tb of uart_loopback_tb is
  component larpix_uart_rx is
    generic (
      C_CLK_HZ : integer := 100000000;
      C_CLKIN_HZ : integer := 10000000;
      C_CHANNEL : std_logic_vector (7 downto 0) := x"FF";
      C_DATA_TYPE : std_logic_vector (7 downto 0) := x"44";
      C_LARPIX_DATA_WIDTH : integer := 64;
      C_M_AXIS_TDATA_WIDTH : integer := 128
      );
    port (
      ACLK : in std_logic;
      ARESETN : in std_logic;
      CLKIN_RATIO : in unsigned (7 downto 0);
      PACMAN_TS : in unsigned (31 downto 0);
      UART_RX_IN : in std_logic;
      M_AXIS_TVALID : out std_logic;
      M_AXIS_TDATA : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
      M_AXIS_TKEEP : out std_logic_vector(C_M_AXIS_TDATA_WIDTH/8-1 downto 0);
      M_AXIS_TSTRB : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
      M_AXIS_TLAST : out std_logic;
      M_AXIS_TREADY : in std_logic
      );
  end component larpix_uart_rx;

  component larpix_uart_tx is
    generic (
      C_S_AXIS_TDATA_WIDTH : integer := 128;
      C_LARPIX_DATA_WIDTH : integer := 64;
      C_CHANNEL : std_logic_vector(7 downto 0) := x"FF";
      C_DATA_TYPE : std_logic_vector(7 downto 0) := x"44";
      C_FIFO_COUNT_WIDTH : integer := 9
      );
    port (
      ACLK : in std_logic;
      ARESETN : in std_logic;
      MCLK : in std_logic;
      UART_TX_OUT : out std_logic;
      CLKOUT_RATIO : in unsigned (7 downto 0);
      FIFO_COUNT : out std_logic_vector (8 downto 0);
      S_AXIS_TREADY : out std_logic;
      S_AXIS_TDATA : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
      S_AXIS_TSTRB : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
      S_AXIS_TKEEP : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
      S_AXIS_TLAST : in std_logic;
      S_AXIS_TVALID : in std_logic
      );
  end component larpix_uart_tx;

  signal clk : std_logic := '1';
  signal mclk : std_logic := '1';
  signal rstn : std_logic := '0';
  signal tvalid : std_logic;
  signal tdata : std_logic_vector(127 downto 0);
  signal tstrb : std_logic_vector(15 downto 0);
  signal tkeep : std_logic_vector(15 downto 0);
  signal tlast : std_logic;
  signal tready : std_logic;

  signal uart_rx : std_logic;
  signal uart_tx : std_logic;

  signal counter : unsigned(31 downto 0) := ( others => '0');

  signal M_AXIS_TVALID_OUT : std_logic;
  signal M_AXIS_TDATA_OUT : std_logic_vector(127 downto 0);
  signal M_AXIS_TKEEP_OUT : std_logic_vector(15 downto 0);
  signal M_AXIS_TSTRB_OUT : std_logic_vector(15 downto 0);
  signal M_AXIS_TLAST_OUT : std_logic;
  signal FIFO_COUNT_OUT : std_logic_vector(8 downto 0);

  constant tx_msgs : integer := 4;
  type tx_data_array is array (tx_msgs-1 downto 0) of std_logic_vector(127 downto 0);
  constant tx_data : tx_data_array := (
    x"99887766554433220000000000000000",
    x"0000000000000000010203040506FF44",
    x"08070605040302010102030405060044",
    x"8877665544332211010203040506FF44" -- first tx
    );
  type tx_keep_array is array (tx_msgs-1 downto 0) of std_logic_vector(15 downto 0);
  constant tx_keep : tx_keep_array := (
    x"FF00",
    x"00FF",
    x"FFFF",
    x"FFFF" -- first tx
    );
  signal tx_data_idx : integer := 0;
  
begin
  clk <= not clk after 5 ns;
  mclk <= not mclk after 50 ns;

  rstn <= '0' after 0 ns,
          '1' after 1000 ns;

  counter <= counter + 1 after 100 ns;

  M_AXIS_TVALID <= M_AXIS_TVALID_OUT;
  M_AXIS_TDATA <= M_AXIS_TDATA_OUT;
  M_AXIS_TKEEP <= M_AXIS_TKEEP_OUT;
  M_AXIS_TSTRB <= M_AXIS_TSTRB_OUT;
  M_AXIS_TLAST <= M_AXIS_TLAST_OUT;
  FIFO_COUNT <= FIFO_COUNT_OUT;

  process
  begin
    tvalid <= '0';
    wait until mclk'event and mclk = '1' and rstn = '1';
    
    tdata <= tx_data(tx_data_idx);
    tvalid <= '1';
    tstrb <= x"FFFF";
    tkeep <= tx_keep(tx_data_idx);
    tlast <= '1';

    wait until tready'event and tready = '1';
    tvalid <= '0';
    -- Uncomment to wait for response
    -- wait until M_AXIS_TVALID_OUT'event and M_AXIS_TVALID_OUT = '1';
    -- 

    tx_data_idx <= (tx_data_idx + 1) mod tx_msgs;
  end process;

  larpix_uart_tx_inst : larpix_uart_tx port map(
    ACLK => clk,
    ARESETN => rstn,
    MCLK => mclk,
    UART_TX_OUT => uart_tx,
    CLKOUT_RATIO => x"02",
    FIFO_COUNT => FIFO_COUNT_OUT,
    S_AXIS_TREADY => tready,
    S_AXIS_TDATA => tdata,
    S_AXIS_TSTRB => tstrb,
    S_AXIS_TKEEP => tkeep,
    S_AXIS_TLAST => tlast,
    S_AXIS_TVALID => tvalid
    );

  larpix_uart_rx_inst : larpix_uart_rx port map(
    ACLK => clk,
    ARESETN => rstn,
    CLKIN_RATIO => x"02",
    PACMAN_TS => counter,
    UART_RX_IN => uart_rx,
    M_AXIS_TVALID => M_AXIS_TVALID_OUT,
    M_AXIS_TDATA => M_AXIS_TDATA_OUT,
    M_AXIS_TKEEP => M_AXIS_TKEEP_OUT,
    M_AXIS_TSTRB => M_AXIS_TSTRB_OUT,
    M_AXIS_TLAST => M_AXIS_TLAST_OUT,
    M_AXIS_TREADY => '1'
    );

  -- loopback
  uart_rx <= uart_tx;

end architecture;
