library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_stream_to_larpix_tb is
  port(
    larpix_data : out std_logic_vector(63 downto 0);
    larpix_update : out std_logic;
    ready : out std_logic
);
end axi_stream_to_larpix_tb;

architecture tb of axi_stream_to_larpix_tb is
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

  signal clk : std_logic := '1';
  signal rstn : std_logic;
  signal tvalid : std_logic;
  signal tdata : std_logic_vector(127 downto 0);
  signal tstrb : std_logic_vector(15 downto 0);
  signal tkeep : std_logic_vector(15 downto 0);
  signal tlast : std_logic;

  signal busy : std_logic;

  signal update : std_logic;
  
begin
  clk <= not clk after 5 ns;

  rstn <= '1' after 0 ns,
          '0' after 100 ns,
          '1' after 300 ns;

  tvalid <= '0' after 0 ns,
            '1' after 500 ns, -- first word
            '0' after 510 ns,
            '1' after 600 ns, -- second word
            '0' after 610 ns,
            '1' after 700 ns, -- etc
            '0' after 710 ns,
            '1' after 800 ns,
            '0' after 810 ns;

  tdata <= x"8877665544332211010203040506FF44" after 500 ns,
           x"88776655443322110102030405060044" after 600 ns,
           x"0000000000000000010203040506FF44" after 700 ns,
           x"88776655443322110000000000000000" after 800 ns;

  tstrb <= x"FFFF";

  tkeep <= x"FFFF" after 0 ns,
           x"00FF" after 700 ns,
           x"FF00" after 800 ns;

  tlast <= '1';

  busy <= '0' after 0 ns,
          not update;

  -- ports
  larpix_update <= update;

  u0 : axi_stream_to_larpix port map(
    data_LArPix => larpix_data,
    data_update_LArPix => update,
    busy_LArPix => busy,

    S_AXIS_ACLK => clk,
    S_AXIS_ARESETN => rstn,

    S_AXIS_TREADY => ready,
    S_AXIS_TDATA => tdata,
    S_AXIS_TSTRB => tstrb,
    S_AXIS_TKEEP => tkeep,
    S_AXIS_TLAST => tlast,
    S_AXIS_TVALID => tvalid
    );
  
end architecture;
