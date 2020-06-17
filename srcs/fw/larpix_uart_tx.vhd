library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity larpix_uart_tx is
  generic (
    C_CLK_HZ : integer := 100000000;
    C_CLKOUT_HZ : integer := 10000000;
    C_CLKOUT_PHASE : integer := 1;
    C_S_AXIS_TDATA_WIDTH : integer := 128;
    C_LARPIX_DATA_WIDTH : integer := 64;
    C_CHANNEL : std_logic_vector(7 downto 0) := x"FF";
    C_DATA_TYPE : std_logic_vector(7 downto 0) := x"44";
    C_FIFO_COUNT_WIDTH : integer := 9
    );
  port (
    --C_CHANNEL : in std_logic_vector(7 downto 0) := x"FF";
    
    ACLK : in std_logic;
    ARESETN : in std_logic;

    -- uart
    MCLK : in std_logic;
    UART_TX_OUT : out std_logic;
    CLKOUT_RATIO : in unsigned (7 downto 0);
    FIFO_COUNT : out std_logic_vector (C_FIFO_COUNT_WIDTH-1 downto 0);
    UART_TX_BUSY : out std_logic;
    
    -- axi-stream slave
    S_AXIS_TREADY : out std_logic;
    S_AXIS_TDATA : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    S_AXIS_TSTRB : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
    S_AXIS_TKEEP : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
    S_AXIS_TLAST : in std_logic;
    S_AXIS_TVALID : in std_logic
    );
end larpix_uart_tx;

architecture arch_imp of larpix_uart_tx is
  
  component axi_stream_to_larpix is
    generic (
      C_S_AXIS_TDATA_WIDTH : integer := C_S_AXIS_TDATA_WIDTH;
      C_LARPIX_DATA_WIDTH : integer := C_LARPIX_DATA_WIDTH;
      C_CHANNEL : std_logic_vector(7 downto 0) := C_CHANNEL;
      C_DATA_TYPE : std_logic_vector(7 downto 0) := C_DATA_TYPE
      );
    port (
      --C_CHANNEL : in std_logic_vector(7 downto 0) := C_CHANNEL;
      data_LArPix         : out std_logic_vector(C_LARPIX_DATA_WIDTH-1 downto 0);
      data_update_LArPix  : out std_logic;
      busy_LArPix         : in std_logic;
      S_AXIS_ACLK         : in std_logic;
      S_AXIS_ARESETN      : in std_logic;
      S_AXIS_TREADY       : out std_logic;
      S_AXIS_TDATA        : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
      S_AXIS_TSTRB        : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
      S_AXIS_TKEEP        : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
      S_AXIS_TLAST        : in std_logic;
      S_AXIS_TVALID       : in std_logic
      );
  end component axi_stream_to_larpix;

  component uart_tx is
    generic (
      CLK_HZ : integer := C_CLK_HZ;
      CLKOUT_HZ : integer := C_CLKOUT_HZ;
      CLKOUT_PHASE : integer := C_CLKOUT_PHASE;
      DATA_WIDTH : INTEGER := C_LARPIX_DATA_WIDTH
      );
    port (
      CLK         : IN  STD_LOGIC;
      RST          : IN  STD_LOGIC;
      CLKOUT_RATIO : IN UNSIGNED (7 downto 0);
      MCLK         : IN STD_LOGIC;
      TX           : OUT STD_LOGIC;
      data         : IN  STD_LOGIC_VECTOR (DATA_WIDTH-1 DOWNTO 0);
      data_update  : IN  STD_LOGIC;
      busy         : OUT STD_LOGIC;
      TC          : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
      );
  end component uart_tx;
  
  component fifo_64x512 is
    port (
      rst : in STD_LOGIC;
      wr_clk : in STD_LOGIC;
      rd_clk : in STD_LOGIC;
      din : in STD_LOGIC_VECTOR ( C_LARPIX_DATA_WIDTH-1 downto 0 );
      wr_en : in STD_LOGIC;
      rd_en : in STD_LOGIC;
      dout : out STD_LOGIC_VECTOR ( C_LARPIX_DATA_WIDTH-1 downto 0 );
      full : out STD_LOGIC;
      almost_full : out STD_LOGIC;
      wr_ack : out STD_LOGIC;
      empty : out STD_LOGIC;
      valid : out STD_LOGIC;
      wr_data_count : out STD_LOGIC_VECTOR ( C_FIFO_COUNT_WIDTH-1 downto 0 )
      );
  end component fifo_64x512;

  signal larpix_update : std_logic;
  signal larpix_data : std_logic_vector ( C_LARPIX_DATA_WIDTH-1 downto 0 );

  signal fifo_busy : std_logic;
  signal fifo_full : std_logic;
  signal fifo_almost_full : std_logic;
  signal fifo_wr_ack : std_logic;
  signal fifo_rd_en : std_logic;
  signal fifo_empty : std_logic;
  signal fifo_valid : std_logic;

  signal uart_update : std_logic;
  signal uart_busy : std_logic;
  signal uart_data : std_logic_vector ( C_LARPIX_DATA_WIDTH-1 downto 0 );

begin
  
  UART_TX_BUSY <= uart_busy;

  -- axi-stream receiver
  axi_stream_to_larpix_inst : axi_stream_to_larpix port map(
    data_LArPix => larpix_data,
    data_update_LArPix => larpix_update,
    busy_LArPix => fifo_busy,
    S_AXIS_ACLK => ACLK,
    S_AXIS_ARESETN => ARESETN,
    S_AXIS_TREADY => S_AXIS_TREADY,
    S_AXIS_TDATA => S_AXIS_TDATA,
    S_AXIS_TSTRB => S_AXIS_TSTRB,
    S_AXIS_TKEEP => S_AXIS_TKEEP,
    S_AXIS_TLAST => S_AXIS_TLAST,
    S_AXIS_TVALID => S_AXIS_TVALID
    );

  -- clock domain crossing FIFO
  fifo_rd_en <= (not uart_busy) and (not fifo_empty) and (not fifo_valid);
  fifo_busy <= fifo_full or fifo_almost_full or fifo_wr_ack;
  fifo_64x512_inst : fifo_64x512 port map(
    rst => ARESETN,
    wr_clk => ACLK,
    rd_clk => ACLK,
    din => larpix_data,
    wr_en => larpix_update,
    rd_en => fifo_rd_en,
    dout => uart_data,
    full => fifo_full,
    almost_full => fifo_almost_full,
    wr_ack => fifo_wr_ack,
    empty => fifo_empty,
    valid => fifo_valid,
    wr_data_count => FIFO_COUNT
    );

  -- drive uart pin
  uart_tx_inst : uart_tx port map(
    MCLK => MCLK,
    CLK => ACLK,
    RST => ARESETN,
    CLKOUT_RATIO => CLKOUT_RATIO,
    TX => UART_TX_OUT,
    data => uart_data,
    data_update => fifo_valid,
    busy => uart_busy,
    TC => open
    );

end arch_imp;

  
    
