library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_channel is
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
    UART_TX : out STD_LOGIC;
    UART_RX_BUSY : out STD_LOGIC;
    UART_TX_BUSY : out STD_LOGIC
  );
end uart_channel;

architecture arch_imp of uart_channel is
  component larpix_uart_tx is
    generic(
      C_CHANNEL : STD_LOGIC_VECTOR ( 7 downto 0 ) := C_CHANNEL
      );
  port (
    ACLK : in STD_LOGIC;
    ARESETN : in STD_LOGIC;
    MCLK : in STD_LOGIC;
    UART_TX_OUT : out STD_LOGIC;
    CLKOUT_RATIO : in STD_LOGIC_VECTOR ( 7 downto 0 );
    CLKOUT_PHASE : in STD_LOGIC_VECTOR ( 3 downto 0 );    
    FIFO_COUNT : out STD_LOGIC_VECTOR ( 8 downto 0 );
    UART_TX_BUSY : out STD_LOGIC;
    S_AXIS_TREADY : out STD_LOGIC;
    S_AXIS_TDATA : in STD_LOGIC_VECTOR ( 127 downto 0 );
    S_AXIS_TSTRB : in STD_LOGIC_VECTOR ( 15 downto 0 );
    S_AXIS_TKEEP : in STD_LOGIC_VECTOR ( 15 downto 0 );
    S_AXIS_TLAST : in STD_LOGIC;
    S_AXIS_TVALID : in STD_LOGIC
  );
  end component larpix_uart_tx;
  
  component larpix_uart_rx is
    generic (
      C_CHANNEL : STD_LOGIC_VECTOR ( 7 downto 0 ) := C_CHANNEL
      );
  port (
    ACLK : in STD_LOGIC;
    ARESETN : in STD_LOGIC;
    MCLK : in STD_LOGIC;
    CLKIN_RATIO : in STD_LOGIC_VECTOR ( 7 downto 0 );
    CLKIN_PHASE : in STD_LOGIC_VECTOR ( 7 downto 0 );
    PACMAN_TS : in UNSIGNED ( 31 downto 0 );
    UART_RX_IN : in STD_LOGIC;
    UART_RX_BUSY : out STD_LOGIC;
    M_AXIS_TVALID : out STD_LOGIC;
    M_AXIS_TDATA : out STD_LOGIC_VECTOR ( 127 downto 0 );
    M_AXIS_TKEEP : out STD_LOGIC_VECTOR ( 15 downto 0 );
    M_AXIS_TSTRB : out STD_LOGIC_VECTOR ( 15 downto 0 );
    M_AXIS_TLAST : out STD_LOGIC;
    M_AXIS_TREADY : in STD_LOGIC
    );
  end component larpix_uart_rx;

  component axi_lite_reg_space is
    generic (
    C_S_AXI_LITE_DATA_WIDTH : integer := 32;
    C_S_AXI_LITE_ADDR_WIDTH : integer := 32;
    C_RW_REG0_DEFAULT : std_logic_vector(31 downto 0) := x"00000002";
    C_RW_REG1_DEFAULT : std_logic_vector(31 downto 0) := x"00000001";
    C_RW_REG2_DEFAULT : std_logic_vector(31 downto 0) := x"00000000";
    C_RW_REG3_DEFAULT : std_logic_vector(31 downto 0) := x"00000000";
    C_RO_REG0_OFFSET : std_logic_vector(11 downto 0) := x"000";
    C_RO_REG1_OFFSET : std_logic_vector(11 downto 0) := x"004";
    C_RO_REG2_OFFSET : std_logic_vector(11 downto 0) := x"008";
    C_RO_REG3_OFFSET : std_logic_vector(11 downto 0) := X"00C";
    C_RW_REG0_OFFSET : std_logic_vector(11 downto 0) := x"010";
    C_RW_REG1_OFFSET : std_logic_vector(11 downto 0) := x"014";
    C_RW_REG2_OFFSET : std_logic_vector(11 downto 0) := x"018";
    C_RW_REG3_OFFSET : std_logic_vector(11 downto 0) := X"01C"
    );
    port (
    RW_REG0            : out std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    RW_REG1            : out std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    RW_REG2            : out std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    RW_REG3            : out std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    RO_REG0            : in std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    RO_REG1            : in std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    RO_REG2            : in std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    RO_REG3            : in std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    update : out std_logic;
    S_AXI_LITE_ACLK  : in std_logic;
    S_AXI_LITE_ARESETN  : in std_logic;
    S_AXI_LITE_AWADDR  : in std_logic_vector(C_S_AXI_LITE_ADDR_WIDTH-1 downto 0);
    S_AXI_LITE_AWPROT  : in std_logic_vector(2 downto 0) := "000";
    S_AXI_LITE_AWVALID  : in std_logic;
    S_AXI_LITE_AWREADY  : out std_logic;
    S_AXI_LITE_WDATA  : in std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    S_AXI_LITE_WSTRB  : in std_logic_vector((C_S_AXI_LITE_DATA_WIDTH/8)-1 downto 0);
    S_AXI_LITE_WVALID  : in std_logic;
    S_AXI_LITE_WREADY  : out std_logic;
    S_AXI_LITE_BRESP  : out std_logic_vector(1 downto 0);
    S_AXI_LITE_BVALID  : out std_logic;
    S_AXI_LITE_BREADY  : in std_logic;
    S_AXI_LITE_ARADDR  : in std_logic_vector(C_S_AXI_LITE_ADDR_WIDTH-1 downto 0);
    S_AXI_LITE_ARPROT  : in std_logic_vector(2 downto 0) := "000";
    S_AXI_LITE_ARVALID  : in std_logic;
    S_AXI_LITE_ARREADY  : out std_logic;
    S_AXI_LITE_RDATA  : out std_logic_vector(C_S_AXI_LITE_DATA_WIDTH-1 downto 0);
    S_AXI_LITE_RRESP  : out std_logic_vector(1 downto 0);
    S_AXI_LITE_RVALID  : out std_logic;
    S_AXI_LITE_RREADY  : in std_logic
    );
  end component;
  
  signal ACLK_1 : STD_LOGIC;
  signal ARESETN_1 : STD_LOGIC;
  signal C_CHANNEL_1 : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal MCLK_1 : STD_LOGIC;
  signal PACMAN_TS_1 : UNSIGNED ( 31 downto 0 );
  signal S_AXIS_1_TDATA : STD_LOGIC_VECTOR ( 127 downto 0 );
  signal S_AXIS_1_TKEEP : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal S_AXIS_1_TLAST : STD_LOGIC;
  signal S_AXIS_1_TREADY : STD_LOGIC;
  signal S_AXIS_1_TSTRB : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal S_AXIS_1_TVALID : STD_LOGIC;
  signal S_AXI_LITE_1_ARADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal S_AXI_LITE_1_ARPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal S_AXI_LITE_1_ARREADY : STD_LOGIC;
  signal S_AXI_LITE_1_ARVALID : STD_LOGIC;
  signal S_AXI_LITE_1_AWADDR : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal S_AXI_LITE_1_AWPROT : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal S_AXI_LITE_1_AWREADY : STD_LOGIC;
  signal S_AXI_LITE_1_AWVALID : STD_LOGIC;
  signal S_AXI_LITE_1_BREADY : STD_LOGIC;
  signal S_AXI_LITE_1_BRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal S_AXI_LITE_1_BVALID : STD_LOGIC;
  signal S_AXI_LITE_1_RDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal S_AXI_LITE_1_RREADY : STD_LOGIC;
  signal S_AXI_LITE_1_RRESP : STD_LOGIC_VECTOR ( 1 downto 0 );
  signal S_AXI_LITE_1_RVALID : STD_LOGIC;
  signal S_AXI_LITE_1_WDATA : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal S_AXI_LITE_1_WREADY : STD_LOGIC;
  signal S_AXI_LITE_1_WSTRB : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal S_AXI_LITE_1_WVALID : STD_LOGIC;
  signal UART_RX_1 : STD_LOGIC;
  signal larpix_uart_rx_0_M_AXIS_TDATA : STD_LOGIC_VECTOR ( 127 downto 0 );
  signal larpix_uart_rx_0_M_AXIS_TKEEP : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal larpix_uart_rx_0_M_AXIS_TLAST : STD_LOGIC;
  signal larpix_uart_rx_0_M_AXIS_TREADY : STD_LOGIC;
  signal larpix_uart_rx_0_M_AXIS_TSTRB : STD_LOGIC_VECTOR ( 15 downto 0 );
  signal larpix_uart_rx_0_M_AXIS_TVALID : STD_LOGIC;
  signal larpix_uart_tx_0_FIFO_COUNT : STD_LOGIC_VECTOR ( 8 downto 0 );
  signal larpix_uart_tx_0_UART_TX_OUT : STD_LOGIC;
  signal CLKIN_RATIO_1 : std_logic_vector ( 7 downto 0 );
  signal CLKOUT_PHASE : std_logic_vector ( 3 downto 0 );
  signal CLKIN_PHASE : std_logic_vector (7 downto 0 );
  signal POSI_POLARITY : std_logic;
  signal PISO_POLARITY : std_logic;
  signal RW_REG0 : std_logic_vector (31 downto 0);
  signal RW_REG1 : std_logic_vector (31 downto 0);
  signal RW_REG2 : std_logic_vector (31 downto 0);
  signal RW_REG3 : std_logic_vector (31 downto 0);  

begin
  ACLK_1 <= ACLK;
  ARESETN_1 <= ARESETN;
  C_CHANNEL_1(7 downto 0) <= C_CHANNEL(7 downto 0);
  MCLK_1 <= MCLK;
  M_AXIS_tdata(127 downto 0) <= larpix_uart_rx_0_M_AXIS_TDATA(127 downto 0);
  M_AXIS_tkeep(15 downto 0) <= larpix_uart_rx_0_M_AXIS_TKEEP(15 downto 0);
  M_AXIS_tlast <= larpix_uart_rx_0_M_AXIS_TLAST;
  M_AXIS_tstrb(15 downto 0) <= larpix_uart_rx_0_M_AXIS_TSTRB(15 downto 0);
  M_AXIS_tvalid <= larpix_uart_rx_0_M_AXIS_TVALID;
  PACMAN_TS_1(31 downto 0) <= PACMAN_TS(31 downto 0);
  S_AXIS_1_TDATA(127 downto 0) <= S_AXIS_tdata(127 downto 0);
  S_AXIS_1_TKEEP(15 downto 0) <= S_AXIS_tkeep(15 downto 0);
  S_AXIS_1_TLAST <= S_AXIS_tlast;
  S_AXIS_1_TSTRB(15 downto 0) <= S_AXIS_tstrb(15 downto 0);
  S_AXIS_1_TVALID <= S_AXIS_tvalid;
  S_AXIS_tready <= S_AXIS_1_TREADY;
  S_AXI_LITE_1_ARADDR(31 downto 0) <= S_AXI_LITE_araddr(31 downto 0);
  S_AXI_LITE_1_ARPROT(2 downto 0) <= S_AXI_LITE_arprot(2 downto 0);
  S_AXI_LITE_1_ARVALID <= S_AXI_LITE_arvalid;
  S_AXI_LITE_1_AWADDR(31 downto 0) <= S_AXI_LITE_awaddr(31 downto 0);
  S_AXI_LITE_1_AWPROT(2 downto 0) <= S_AXI_LITE_awprot(2 downto 0);
  S_AXI_LITE_1_AWVALID <= S_AXI_LITE_awvalid;
  S_AXI_LITE_1_BREADY <= S_AXI_LITE_bready;
  S_AXI_LITE_1_RREADY <= S_AXI_LITE_rready;
  S_AXI_LITE_1_WDATA(31 downto 0) <= S_AXI_LITE_wdata(31 downto 0);
  S_AXI_LITE_1_WSTRB(3 downto 0) <= S_AXI_LITE_wstrb(3 downto 0);
  S_AXI_LITE_1_WVALID <= S_AXI_LITE_wvalid;
  S_AXI_LITE_arready <= S_AXI_LITE_1_ARREADY;
  S_AXI_LITE_awready <= S_AXI_LITE_1_AWREADY;
  S_AXI_LITE_bresp(1 downto 0) <= S_AXI_LITE_1_BRESP(1 downto 0);
  S_AXI_LITE_bvalid <= S_AXI_LITE_1_BVALID;
  S_AXI_LITE_rdata(31 downto 0) <= S_AXI_LITE_1_RDATA(31 downto 0);
  S_AXI_LITE_rresp(1 downto 0) <= S_AXI_LITE_1_RRESP(1 downto 0);
  S_AXI_LITE_rvalid <= S_AXI_LITE_1_RVALID;
  S_AXI_LITE_wready <= S_AXI_LITE_1_WREADY;

  UART_RX_1 <= UART_RX xor PISO_POLARITY;
  UART_TX <= larpix_uart_tx_0_UART_TX_OUT xor POSI_POLARITY;
  larpix_uart_rx_0_M_AXIS_TREADY <= M_AXIS_tready;
  
  CLKIN_RATIO_1(7 downto 0) <= RW_REG0(7 downto 0);
  CLKOUT_PHASE(3 downto 0) <= RW_REG1(3 downto 0);
  CLKIN_PHASE(7 downto 0) <= RW_REG2(7 downto 0);
  POSI_POLARITY <= RW_REG3(0);
  PISO_POLARITY <= RW_REG3(1);

  axi_lite_reg_space_0 : axi_lite_reg_space
     port map (
      s_AXI_LITE_ACLK => ACLK_1,
      S_AXI_LITE_ARESETN => ARESETN_1,
      RW_REG0(31 downto 0) => RW_REG0(31 downto 0),
      RW_REG1 => RW_REG1(31 downto 0),
      RW_REG2 => RW_REG2(31 downto 0),
      RW_REG3 => RW_REG3(31 downto 0),      
      RO_REG0(8 downto 0) => larpix_uart_tx_0_FIFO_COUNT(8 downto 0),
      RO_REG0(31 downto 9) => (others => '0'),
      RO_REG1 => (others => '0'),
      RO_REG2 => (others => '0'),
      RO_REG3 => (others => '0'),      
      update => open,
      S_AXI_LITE_araddr(31 downto 0) => S_AXI_LITE_1_ARADDR(31 downto 0),
      S_AXI_LITE_arprot(2 downto 0) => S_AXI_LITE_1_ARPROT(2 downto 0),
      S_AXI_LITE_arready => S_AXI_LITE_1_ARREADY,
      S_AXI_LITE_arvalid => S_AXI_LITE_1_ARVALID,
      S_AXI_LITE_awaddr(31 downto 0) => S_AXI_LITE_1_AWADDR(31 downto 0),
      S_AXI_LITE_awprot(2 downto 0) => S_AXI_LITE_1_AWPROT(2 downto 0),
      S_AXI_LITE_awready => S_AXI_LITE_1_AWREADY,
      S_AXI_LITE_awvalid => S_AXI_LITE_1_AWVALID,
      S_AXI_LITE_bready => S_AXI_LITE_1_BREADY,
      S_AXI_LITE_bresp(1 downto 0) => S_AXI_LITE_1_BRESP(1 downto 0),
      S_AXI_LITE_bvalid => S_AXI_LITE_1_BVALID,
      S_AXI_LITE_rdata(31 downto 0) => S_AXI_LITE_1_RDATA(31 downto 0),
      S_AXI_LITE_rready => S_AXI_LITE_1_RREADY,
      S_AXI_LITE_rresp(1 downto 0) => S_AXI_LITE_1_RRESP(1 downto 0),
      S_AXI_LITE_rvalid => S_AXI_LITE_1_RVALID,
      S_AXI_LITE_wdata(31 downto 0) => S_AXI_LITE_1_WDATA(31 downto 0),
      S_AXI_LITE_wready => S_AXI_LITE_1_WREADY,
      S_AXI_LITE_wstrb(3 downto 0) => S_AXI_LITE_1_WSTRB(3 downto 0),
      S_AXI_LITE_wvalid => S_AXI_LITE_1_WVALID
      );
  
  larpix_uart_rx_0: component larpix_uart_rx
     port map (
      ACLK => ACLK_1,
      ARESETN => ARESETN_1,
      CLKIN_RATIO(7 downto 0) => CLKIN_RATIO_1(7 downto 0),
      CLKIN_PHASE(7 downto 0) => CLKIN_PHASE(7 downto 0),
      MCLK => MCLK_1,
      M_AXIS_TDATA(127 downto 0) => larpix_uart_rx_0_M_AXIS_TDATA(127 downto 0),
      M_AXIS_TKEEP(15 downto 0) => larpix_uart_rx_0_M_AXIS_TKEEP(15 downto 0),
      M_AXIS_TLAST => larpix_uart_rx_0_M_AXIS_TLAST,
      M_AXIS_TREADY => larpix_uart_rx_0_M_AXIS_TREADY,
      M_AXIS_TSTRB(15 downto 0) => larpix_uart_rx_0_M_AXIS_TSTRB(15 downto 0),
      M_AXIS_TVALID => larpix_uart_rx_0_M_AXIS_TVALID,
      PACMAN_TS(31 downto 0) => PACMAN_TS_1(31 downto 0),
      UART_RX_IN => UART_RX_1,
      UART_RX_BUSY => UART_RX_BUSY
      );
  
  larpix_uart_tx_0: component larpix_uart_tx
     port map (
      ACLK => ACLK_1,
      ARESETN => ARESETN_1,
      CLKOUT_RATIO(7 downto 0) => CLKIN_RATIO_1(7 downto 0),
      CLKOUT_PHASE(3 downto 0) => CLKOUT_PHASE(3 downto 0),      
      FIFO_COUNT(8 downto 0) => larpix_uart_tx_0_FIFO_COUNT(8 downto 0),
      MCLK => MCLK_1,
      S_AXIS_TDATA(127 downto 0) => S_AXIS_1_TDATA(127 downto 0),
      S_AXIS_TKEEP(15 downto 0) => S_AXIS_1_TKEEP(15 downto 0),
      S_AXIS_TLAST => S_AXIS_1_TLAST,
      S_AXIS_TREADY => S_AXIS_1_TREADY,
      S_AXIS_TSTRB(15 downto 0) => S_AXIS_1_TSTRB(15 downto 0),
      S_AXIS_TVALID => S_AXIS_1_TVALID,
      UART_TX_OUT => larpix_uart_tx_0_UART_TX_OUT,
      UART_TX_BUSY => UART_TX_BUSY
    );
end arch_imp;
