library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_loopback_tb is port (
      M_AXIS_TVALID       : out std_logic;
      M_AXIS_TDATA        : out std_logic_vector(127 downto 0);
      M_AXIS_TKEEP        : out std_logic_vector(15 downto 0);
      M_AXIS_TSTRB        : out std_logic_vector(15 downto 0);
      M_AXIS_TLAST        : out std_logic
      );
end axi_loopback_tb;

architecture tb of axi_loopback_tb is
  component axi_stream_to_larpix is
    generic (
      C_S_AXIS_TDATA_WIDTH        : integer := 128;
      C_LARPIX_DATA_WIDTH         : integer := 64;
      C_CHANNEL                   : std_logic_vector(7 downto 0) := x"FF";
      C_DATA_TYPE                 : std_logic_vector(7 downto 0) := x"44"
      );
    port (
      data_LArPix         : out std_logic_vector(C_LARPIX_DATA_WIDTH-1 downto 0);
      data_update_LArPix  : out std_logic;
      busy_LArPix         : in std_logic;
    
      S_AXIS_ACLK	        : in std_logic;
      S_AXIS_ARESETN	: in std_logic;

      S_AXIS_TREADY	: out std_logic;
      S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
      S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
      S_AXIS_TKEEP      : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
      S_AXIS_TLAST	: in std_logic;
      S_AXIS_TVALID	: in std_logic
    );
  end component;

  component larpix_to_axis_stream is
    generic(
      C_M_AXIS_TDATA_WIDTH    : integer := 128;
      C_LARPIX_DATA_WIDTH     : integer := 64;
      C_M_AXIS_TDATA_TYPE     : std_logic_vector(7 downto 0) := x"44";
      C_M_AXIS_TDATA_CHANNEL  : std_logic_vector(7 downto 0) := x"FF"
      );
    port (
      timestamp           : in unsigned(31 downto 0) := (others => '0');

      data_LArPix         : in std_logic_vector(C_LARPIX_DATA_WIDTH-1 downto 0);
      data_update_LArPix  : in std_logic;
      busy_LArPix         : out std_logic;

      M_AXIS_ACLK         : in std_logic;
      M_AXIS_ARESETN      : in std_logic;

      M_AXIS_TVALID       : out std_logic;
      M_AXIS_TDATA        : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
      M_AXIS_TKEEP     : out std_logic_vector(C_M_AXIS_TDATA_WIDTH/8-1 downto 0);
      M_AXIS_TSTRB        : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
      M_AXIS_TLAST        : out std_logic;
      M_AXIS_TREADY       : in std_logic
      );
  end component;

  signal clk : std_logic := '1';
  signal rstn : std_logic := '0';
  signal tvalid : std_logic := '0';
  signal tdata : std_logic_vector(127 downto 0);
  signal tstrb : std_logic_vector(15 downto 0);
  signal tkeep : std_logic_vector(15 downto 0);
  signal tlast : std_logic;
  signal tready : std_logic;

  signal busy : std_logic;
  signal data : std_logic_vector(63 downto 0);
  signal update : std_logic;

  signal counter : unsigned(31 downto 0) := ( others => '0');

  signal M_AXIS_TVALID_out : std_logic;
  signal M_AXIS_TDATA_out : std_logic_vector(127 downto 0);
  signal M_AXIS_TKEEP_out : std_logic_vector(15 downto 0);
  signal M_AXIS_TSTRB_out : std_logic_vector(15 downto 0);
  signal M_AXIS_TLAST_out : std_logic;

  constant tx_msgs : integer := 4;
  type tx_data_array is array (tx_msgs-1 downto 0) of std_logic_vector(127 downto 0);
  constant tx_data : tx_data_array := (
    x"88776655443322110000000000000000",
    x"0000000000000000010203040506FF44",
    x"88776655443322110102030405060044",
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

  rstn <= '0' after 0 ns,
          '1' after 100 ns;

  counter <= counter + 1 after 10 ns;

  process
  begin
    wait until clk'event and clk = '1' and rstn = '1';
    
    tdata <= tx_data(tx_data_idx);
    tvalid <= '1';
    tstrb <= x"FFFF";
    tkeep <= tx_keep(tx_data_idx);
    tlast <= '1';

    wait until tready'event and tready = '1';

    tx_data_idx <= (tx_data_idx + 1) mod tx_msgs;
    tvalid <= '0';
  end process;

  -- ports
  M_AXIS_TVALID <= M_AXIS_TVALID_out;
  M_AXIS_TDATA <= M_AXIS_TDATA_out;
  M_AXIS_TKEEP <= M_AXIS_TKEEP_out;
  M_AXIS_TSTRB <= M_AXIS_TSTRB_out;
  M_AXIS_TLAST <= M_AXIS_TLAST_out;

  u0 : axi_stream_to_larpix port map(
    data_LArPix => data,
    data_update_LArPix => update,
    busy_LArPix => busy,

    S_AXIS_ACLK => clk,
    S_AXIS_ARESETN => rstn,

    S_AXIS_TREADY => tready,
    S_AXIS_TDATA => tdata,
    S_AXIS_TSTRB => tstrb,
    S_AXIS_TKEEP => tkeep,
    S_AXIS_TLAST => tlast,
    S_AXIS_TVALID => tvalid
    );

  u1 : larpix_to_axi_stream port map(
      timestamp => counter,

      data_LArPix => data,
      data_update_LArPix => update,
      busy_LArPix => busy,

      M_AXIS_ACLK => clk,
      M_AXIS_ARESETN => rstn,

      M_AXIS_TVALID => M_AXIS_TVALID_out,
      M_AXIS_TDATA => m_axis_tdata_out,
      M_AXIS_TKEEP => m_axis_tkeep_out,
      M_AXIS_TSTRB => m_axis_tstrb_out,
      M_AXIS_TLAST => m_axis_tlast_out,
      M_AXIS_TREADY => '1'
      );
  
end architecture;
