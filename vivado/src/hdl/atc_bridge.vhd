library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.common.all;
use work.atc_pkg.all;

entity atc_bridge is
  port (
    -- Interface to clock domain A:  (sys_clk)
    CLK_A_I       : in  std_logic;
    RST_A_I       : in  std_logic;

    CONFIG_REQ_I  : in  std_logic;
    CONFIG_I      : in  atc_config_t;

    POKE_C_I      : in  std_logic;
    MASK_C_I      : in  std_logic_vector(C_NUM_TILE-1 downto 0);
    POKE_D_I      : in  std_logic;
    MASK_D_I      : in  std_logic_vector(C_NUM_TILE-1 downto 0);

    COUNT_REQ_I   : in  std_logic;
    COUNT_CMD_I   : in  std_logic_vector(C_BYTE_WIDTH-1 downto 0);
    COUNT_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    TIMESTAMP_O   : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);

    -- Interface to clock domain B:  (asic_clk)
    CLK_B_I       : in  std_logic;
    RST_B_I       : in  std_logic;

    CONFIG_O      : out atc_config_t;

    COUNT_REQ_O   : out std_logic;
    COUNT_CMD_O   : out std_logic_vector(C_BYTE_WIDTH-1 downto 0);
    COUNT_I       : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    POKE_C_O      : out std_logic;
    MASK_C_O      : out std_logic_vector(C_NUM_TILE-1 downto 0);
    POKE_D_O      : out std_logic;
    MASK_D_O      : out std_logic_vector(C_NUM_TILE-1 downto 0);

    TIMESTAMP_TOGGLE_I : in std_logic;
    TIMESTAMP_TSYNC_I  : in std_logic
  );
end atc_bridge;

architecture behaviour of atc_bridge is
  signal clk_a       : std_logic;
  signal rst_a       : std_logic;

  signal clk_b       : std_logic;
  signal rst_b       : std_logic;

  signal cfg_request : std_logic;
  signal cfg_busy    : std_logic;
  signal cfg_reply   : std_logic;

  signal pkc_request : std_logic;
  signal pkc_busy    : std_logic;
  signal pkc_reply   : std_logic;

  signal pkd_request : std_logic;
  signal pkd_busy    : std_logic;
  signal pkd_reply   : std_logic;

  signal cnt_request : std_logic;
  signal cnt_busy    : std_logic;
  signal cnt_reply   : std_logic;

  signal status      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  component update_request is
    port (
      CLK_I	    : in  std_logic;
      RST_I	    : in  std_logic;
      REQUEST_I     : in std_logic;
      BUSY_O        : out std_logic;
      REQUEST_O     : out std_logic;
      REPLY_A       : in std_logic
      );
  end component;

  component config_sync is
    port (
      CLK_I	 : in  std_logic;
      RST_I	 : in  std_logic;
      CONFIG_A   : in  atc_config_t;
      SHADOW_O   : out atc_config_t;
      REPLY_O    : out std_logic;
      REQUEST_A  : in  std_logic
    );
  end component;

  component poke_sync is
    generic ( PAYLOAD_WIDTH : integer := 16 );
    port (
      CLK_I	  : in  std_logic;
      RST_I	  : in  std_logic;
      POKE_O      : out std_logic;
      PAYLOAD_O   : out std_logic_vector(PAYLOAD_WIDTH-1 downto 0);
      REPLY_O     : out std_logic;
      REQUEST_A   : in  std_logic;
      PAYLOAD_A   : in  std_logic_vector(PAYLOAD_WIDTH-1 downto 0)
    );
  end component;

  component payload_sync is
    generic ( PAYLOAD_WIDTH : integer := C_RB_DATA_WIDTH );
    port (
      CLK_I       : in  std_logic;
      RST_I	  : in  std_logic;
      BUSY_I	  : in  std_logic;
      PAYLOAD_O   : out std_logic_vector(PAYLOAD_WIDTH-1 downto 0);
      PAYLOAD_A   : in  std_logic_vector(PAYLOAD_WIDTH-1 downto 0)
    );
  end component;

  component timestamp_sync is
    port (
      CLK_I	        : in  std_logic;
      RST_I	        : in  std_logic;
      TIMESTAMP_O         : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      TOGGLE_A            : in std_logic;
      TSYNC_A             : in std_logic
      );
  end component;



begin
  clk_a <= CLK_A_I;
  rst_a <= RST_A_I;

  clk_b <= CLK_B_I;
  rst_b <= RST_B_I;

  cfgreq0: update_request port map (
    CLK_I          => clk_a,
    RST_I          => rst_a,
    REQUEST_I      => CONFIG_REQ_I,
    BUSY_O         => cfg_busy,
    REQUEST_O      => cfg_request,
    REPLY_A        => cfg_reply
  );

  cfgsync0: config_sync port map (
    CLK_I          => clk_b,
    RST_I          => rst_b,
    CONFIG_A       => CONFIG_I,
    SHADOW_O       => CONFIG_O,
    REPLY_O        => cfg_reply,
    REQUEST_A      => cfg_request
  );

  pkcreq0: update_request port map (
    CLK_I          => clk_a,
    RST_I          => rst_a,
    REQUEST_I      => POKE_C_I,
    BUSY_O         => pkc_busy,
    REQUEST_O      => pkc_request,
    REPLY_A        => pkc_reply
  );

  pokec0: poke_sync
    generic map(
      PAYLOAD_WIDTH => C_NUM_TILE
    )
    port map (
    CLK_I      => clk_b,
    RST_I      => rst_b,
    POKE_O     => POKE_C_O,
    PAYLOAD_O  => MASK_C_O,
    REPLY_O    => pkc_reply,
    REQUEST_A  => pkc_request,
    PAYLOAD_A  => MASK_C_I
  );

  pkdreq0: update_request port map (
    CLK_I          => clk_a,
    RST_I          => rst_a,
    REQUEST_I      => POKE_D_I,
    BUSY_O         => pkd_busy,
    REQUEST_O      => pkd_request,
    REPLY_A        => pkd_reply
  );

  poked0: poke_sync
    generic map(
      PAYLOAD_WIDTH => C_NUM_TILE
    )
    port map (
    CLK_I      => clk_b,
    RST_I      => rst_b,
    POKE_O     => POKE_D_O,
    PAYLOAD_O  => MASK_D_O,
    REPLY_O    => pkd_reply,
    REQUEST_A  => pkd_request,
    PAYLOAD_A  => MASK_D_I
  );

  cntreq0: update_request port map (
    CLK_I          => clk_a,
    RST_I          => rst_a,
    REQUEST_I      => COUNT_REQ_I,
    BUSY_O         => cnt_busy,
    REQUEST_O      => cnt_request,
    REPLY_A        => cnt_reply
  );

  cnt0: poke_sync
    generic map(
      PAYLOAD_WIDTH => C_BYTE_WIDTH
    )
    port map (
    CLK_I      => clk_b,
    RST_I      => rst_b,
    POKE_O     => COUNT_REQ_O,
    PAYLOAD_O  => COUNT_CMD_O,
    REPLY_O    => cnt_reply,
    REQUEST_A  => cnt_request,
    PAYLOAD_A  => COUNT_CMD_I
  );

  cntreg0: payload_sync port map (
    CLK_I      => clk_a,
    RST_I      => rst_a,
    BUSY_I     => cnt_busy,
    PAYLOAD_O  => COUNT_O,
    PAYLOAD_A  => COUNT_I
  );

  dut2: timestamp_sync port map (
    CLK_I              => clk_a,
    RST_I              => rst_a,
    TIMESTAMP_O        => TIMESTAMP_O,
    TOGGLE_A           => TIMESTAMP_TOGGLE_I,
    TSYNC_A            => TIMESTAMP_TSYNC_I
  );

  -- status register:

  status(0) <= cfg_busy;
  status(1) <= pkc_busy;
  status(2) <= pkd_busy;
  status(3) <= cnt_busy;

  process(clk_a, rst_a)
  begin
    if rst_a = '1' then
      STATUS_O <= (others => '0');  -- reset all bits
    elsif rising_edge(clk_a) then
      STATUS_O <= status;           -- register the combinatorial input
    end if;
  end process;


end behaviour;
