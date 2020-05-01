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

  component uart_channel is
  generic (
    C_CHANNEL : STD_LOGIC_VECTOR ( 7 downto 0 ) := x"FF"
    );
  port (
    ACLK : in STD_LOGIC;
    ARESETN : in STD_LOGIC;
    MCLK : in STD_LOGIC;
    M_AXIS_tdata : out STD_LOGIC_VECTOR ( 127 downto 0 );
    M_AXIS_tkeep : out STD_LOGIC_VECTOR ( 15 downto 0 );
    M_AXIS_tlast : out STD_LOGIC;
    M_AXIS_tready : in STD_LOGIC;
    M_AXIS_tstrb : out STD_LOGIC_VECTOR ( 15 downto 0 );
    M_AXIS_tvalid : out STD_LOGIC;
    PACMAN_TS : in UNSIGNED ( 31 downto 0 );
    S_AXIS_tdata : in STD_LOGIC_VECTOR ( 127 downto 0 );
    S_AXIS_tkeep : in STD_LOGIC_VECTOR ( 15 downto 0 );
    S_AXIS_tlast : in STD_LOGIC;
    S_AXIS_tready : out STD_LOGIC;
    S_AXIS_tstrb : in STD_LOGIC_VECTOR ( 15 downto 0 );
    S_AXIS_tvalid : in STD_LOGIC;
    S_AXI_LITE_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_LITE_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_LITE_arready : out STD_LOGIC;
    S_AXI_LITE_arvalid : in STD_LOGIC;
    S_AXI_LITE_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_LITE_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    S_AXI_LITE_awready : out STD_LOGIC;
    S_AXI_LITE_awvalid : in STD_LOGIC;
    S_AXI_LITE_bready : in STD_LOGIC;
    S_AXI_LITE_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_LITE_bvalid : out STD_LOGIC;
    S_AXI_LITE_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_LITE_rready : in STD_LOGIC;
    S_AXI_LITE_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    S_AXI_LITE_rvalid : out STD_LOGIC;
    S_AXI_LITE_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    S_AXI_LITE_wready : out STD_LOGIC;
    S_AXI_LITE_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    S_AXI_LITE_wvalid : in STD_LOGIC;
    UART_RX : in STD_LOGIC;
    UART_TX : out STD_LOGIC
  );
  end component;

  signal clk : std_logic := '1';
  signal mclk : std_logic := '1';
  signal rstn : std_logic := '0';
  signal tvalid : std_logic;
  signal tdata : std_logic_vector(127 downto 0);
  signal tstrb : std_logic_vector(15 downto 0);
  signal tkeep : std_logic_vector(15 downto 0);
  signal tlast : std_logic;
  signal tready : std_logic;

  signal slave_tready : std_logic := '0';

  signal uart_rx : std_logic;
  signal uart_tx : std_logic;

  signal counter : unsigned(31 downto 0) := ( others => '0');

  signal M_AXIS_TVALID_OUT : std_logic;
  signal M_AXIS_TDATA_OUT : std_logic_vector(127 downto 0);
  signal M_AXIS_TKEEP_OUT : std_logic_vector(15 downto 0);
  signal M_AXIS_TSTRB_OUT : std_logic_vector(15 downto 0);
  signal M_AXIS_TLAST_OUT : std_logic;

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

  process
  begin
    tvalid <= '0';
    wait until mclk'event and mclk = '1' and rstn = '1';
    
    tdata <= tx_data(tx_data_idx);
    tvalid <= '1';
    tstrb <= tx_keep(tx_data_idx);
    tkeep <= tx_keep(tx_data_idx);
    tlast <= '1';

    wait until tready'event and tready = '1';
    -- Uncomment to wait for response
    -- wait until M_AXIS_TVALID_OUT'event and M_AXIS_TVALID_OUT = '1';
    -- 

    tx_data_idx <= (tx_data_idx + 1) mod tx_msgs;
  end process;

  process
  begin
    slave_tready <= '0';
    wait until M_AXIS_TVALID_OUT'event and M_AXIS_TVALID_OUT = '1';
    wait for 1000 ns;
    wait until rising_edge(clk);
    slave_tready <= '1';
    wait until rising_edge(clk);
    slave_tready <= '0';
  end process;

  uart_channel_inst : uart_channel port map(
    ACLK => clk,
    ARESETN => rstn,
    MCLK => mclk,
    M_AXIS_tdata => M_AXIS_TDATA_OUT,
    M_AXIS_tkeep => M_AXIS_TKEEP_OUT,
    M_AXIS_tlast => M_AXIS_TLAST_OUT,
    M_AXIS_tready => slave_tready,
    M_AXIS_tstrb => M_AXIS_TSTRB_OUT,
    M_AXIS_tvalid => M_AXIS_TVALID_OUT,
    PACMAN_TS => counter,
    S_AXIS_tdata => tdata,
    S_AXIS_tkeep => tkeep,
    S_AXIS_tlast => tlast,
    S_AXIS_tready => tready,
    S_AXIS_tstrb => tstrb,
    S_AXIS_tvalid => tvalid,
    S_AXI_LITE_araddr => x"00000000",
    S_AXI_LITE_arprot => b"000",
    S_AXI_LITE_arready => open,
    S_AXI_LITE_arvalid => '0',
    S_AXI_LITE_awaddr => x"00000000",
    S_AXI_LITE_awprot => b"000",
    S_AXI_LITE_awready => open,
    S_AXI_LITE_awvalid => '0',
    S_AXI_LITE_bready => '0',
    S_AXI_LITE_bresp => open,
    S_AXI_LITE_bvalid => open,
    S_AXI_LITE_rdata => open,
    S_AXI_LITE_rready => '0',
    S_AXI_LITE_rresp => open,
    S_AXI_LITE_rvalid => open,
    S_AXI_LITE_wdata => x"00000000",
    S_AXI_LITE_wready => open,
    S_AXI_LITE_wstrb => b"0000",
    S_AXI_LITE_wvalid => '0',
    UART_RX => uart_rx,
    UART_TX => uart_tx
    );

  -- loopback
  uart_rx <= uart_tx;

end architecture;
