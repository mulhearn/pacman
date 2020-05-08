library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_trig_to_axi_stream_tb is
  generic(
    C_M_AXIS_TDATA_WIDTH : integer := 128; -- width of AXIS bus
    C_M_AXIS_TDATA_TYPE : std_logic_vector(7 downto 0) := x"54" -- ASCII T
    );
  port (
    M_AXIS_TVALID	: out std_logic;
    M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TKEEP    : out std_logic_vector(C_M_AXIS_TDATA_WIDTH/8-1 downto 0);
    M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M_AXIS_TLAST	: out std_logic
    );
end larpix_trig_to_axi_stream_tb;

architecture implementation of larpix_trig_to_axi_stream_tb is                     

  component larpix_trig_to_axi_stream is
    port (
      TRIG_TYPE           : in std_logic_vector(7 downto 0);
      TRIG_TIMESTAMP      : in unsigned(31 downto 0) := (others => '0');
      M_AXIS_ACLK         : in std_logic;
      M_AXIS_ARESETN      : in std_logic;
      M_AXIS_TVALID       : out std_logic;
      M_AXIS_TDATA        : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
      M_AXIS_TKEEP        : out std_logic_vector(C_M_AXIS_TDATA_WIDTH/8-1 downto 0);
      M_AXIS_TSTRB        : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
      M_AXIS_TLAST        : out std_logic;
      M_AXIS_TREADY       : in std_logic
      );
  end component;

  signal trig_type : std_logic_vector(7 downto 0) := x"00";
  signal trig_timestamp : unsigned(31 downto 0) := (others => '0');

  signal clk : std_logic := '1';
  signal mclk : std_logic := '1';
  signal rstn : std_logic := '0';

  signal tvalid_out : std_logic;
  signal tdata_out : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);

begin

  mclk <= not mclk after 53 ns; -- check clock crossing
  
  clk <= not clk after 5 ns;
  rstn <= '0' after 0 ns,
          '1' after 100 ns;

  trig_timestamp <= trig_timestamp + 1 after 106 ns;
  
  M_AXIS_TVALID <= tvalid_out;
  M_AXIS_TDATA <= tdata_out;

  process is
  begin
    wait until rstn = '1';
    wait until rising_edge(clk);
    wait until rising_edge(mclk);

    -- test single channel trigger
    trig_type <= x"01";
    wait until tvalid_out = '1';
    wait until tvalid_out = '0';
    wait until rising_edge(mclk);
    trig_type <= x"00";

    -- test multi trigger
    wait until rising_edge(mclk);
    trig_type <= x"01";
    wait until rising_edge(mclk);
    trig_type <= x"03";
    wait until rising_edge(mclk);
    trig_type <= x"02";
    wait until rising_edge(mclk);
    trig_type <= x"00";
    wait until rising_edge(mclk);

  end process;
  
  larpix_trig_to_axi_stream_inst : larpix_trig_to_axi_stream port map (
      TRIG_TYPE => trig_type,
      TRIG_TIMESTAMP => trig_timestamp,
      M_AXIS_ACLK => clk,
      M_AXIS_ARESETN => rstn,
      M_AXIS_TVALID => tvalid_out,
      M_AXIS_TDATA => tdata_out,
      M_AXIS_TKEEP => M_AXIS_TKEEP,
      M_AXIS_TSTRB => M_AXIS_TSTRB,
      M_AXIS_TLAST => M_AXIS_TLAST,
      M_AXIS_TREADY => '1'
      );

end implementation;
