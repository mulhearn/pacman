library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_clk_to_axi_stream_tb is
  port(
    M_AXIS_TVALID       : out std_logic;
    M_AXIS_TDATA        : out std_logic_vector(127 downto 0);
    M_AXIS_TKEEP        : out std_logic_vector(15 downto 0);
    M_AXIS_TSTRB        : out std_logic_vector(15 downto 0);
    M_AXIS_TLAST        : out std_logic
    );
end larpix_clk_to_axi_stream_tb;

architecture implementation of larpix_clk_to_axi_stream_tb is
  component larpix_clk_to_axi_stream is
    generic(
      C_M_AXIS_TDATA_WIDTH : integer := 128; -- width of AXIS bus
      C_M_AXIS_TDATA_TYPE : std_logic_vector(7 downto 0) := x"53"; -- ASCII S
      C_SYNC_FLAG : std_logic_vector(7 downto 0) := x"53"; -- ASCII S
      C_HB_FLAG : std_logic_vector(7 downto 0) := x"48"; -- ASCII H
      C_CLK_SRC_FLAG : std_logic_vector(7 downto 0) := x"43" -- ASCII C 
      );
    port (
      TIMESTAMP : in unsigned(31 downto 0) := (others => '0');
      TIMESTAMP_PREV : in unsigned(31 downto 0) := (others => '0');
      TIMESTAMP_SYNC : in std_logic;
      CLK_SRC : in std_logic;
      HB_EN : in std_logic;
      HB_CYCLES : in unsigned(31 downto 0);
      M_AXIS_ACLK       : in std_logic;
      M_AXIS_ARESETN	: in std_logic;
      M_AXIS_TVALID	: out std_logic;
      M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
      M_AXIS_TKEEP      : out std_logic_vector(C_M_AXIS_TDATA_WIDTH/8-1 downto 0);
      M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
      M_AXIS_TLAST	: out std_logic;
      M_AXIS_TREADY	: in std_logic
    );
  end component;
  
  component larpix_counter is
    generic(
      C_ROLLOVER_VALUE : unsigned(31 downto 0) := x"000000FF"
      );
    port (
      MCLK : in std_logic;
      RSTN : in std_logic;
      COUNTER : out unsigned(31 downto 0);
      COUNTER_PREV : out unsigned(31 downto 0);
      ROLLOVER_SYNC : out std_logic
      );
  end component;

  signal mclk : std_logic := '1';
  signal clk : std_logic := '1';
  signal rstn : std_logic := '0';

  signal timestamp : unsigned(31 downto 0) := x"87654321";
  signal timestamp_prev : unsigned(31 downto 0) := x"10FEDCBA";
  signal timestamp_sync : std_logic := '0';
  signal clk_src : std_logic := '0';
  signal hb_en : std_logic := '0';
  signal hb_cycles : unsigned(31 downto 0) := x"00000020";

  signal tvalid : std_logic := '1';

begin

  clk <= not clk after 5 ns;
  mclk <= not mclk after 50 ns;

  M_AXIS_TVALID <= tvalid;

  process is
  begin
    -- test reset generation
    rstn <= '0';
    wait for 1000 ns;
    rstn <= '1';
    wait until (tvalid = '1') and rising_edge(clk);
    wait for 1000 ns;
    
    -- test reset glitch rejection
    rstn <= '0';
    wait for 200 ns;
    rstn <= '1';
    wait for 1000 ns;

    -- test heart beat generation
    hb_en <= '1';
    wait until (tvalid = '1') and rising_edge(clk);
    wait until (tvalid = '1') and rising_edge(clk);
    wait until (tvalid = '1') and rising_edge(clk);

    -- test disable heart beat generation
    hb_en <= '0';
    wait for 10000 ns;

    -- test clock source switch
    wait until rising_edge(mclk);
    clk_src <= not clk_src;
    wait until (tvalid = '1') and rising_edge(clk);
    
    -- test rollover
    wait until (tvalid = '1') and rising_edge(clk);
  end process;
  
  larpix_clk_to_axi_stream_inst : larpix_clk_to_axi_stream port map(
    TIMESTAMP => timestamp,
    TIMESTAMP_PREV => timestamp_prev,
    TIMESTAMP_SYNC => timestamp_sync,
    CLK_SRC => clk_src,
    HB_EN => hb_en,
    HB_CYCLES => hb_cycles,
    M_AXIS_ACLK => clk,
    M_AXIS_ARESETN => rstn,
    M_AXIS_TVALID => tvalid,
    M_AXIS_TDATA => M_AXIS_TDATA,
    M_AXIS_TKEEP => M_AXIS_TKEEP,
    M_AXIS_TSTRB => M_AXIS_TSTRB,
    M_AXIS_TLAST => M_AXIS_TLAST,
    M_AXIS_TREADY => '1'
    );
    
  larpix_counter_inst : larpix_counter port map (
      MCLK => mclk,
      RSTN => rstn,
      COUNTER => timestamp,
      COUNTER_PREV => timestamp_prev,
      ROLLOVER_SYNC => timestamp_sync
      );
        
end implementation;
