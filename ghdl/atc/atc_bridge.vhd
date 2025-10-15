library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.common.all;
use work.atc_pkg.all;

entity atc_bridge is
  port (
    CLK_A_I : in std_logic;
    RST_A_I : in std_logic;

    CONFIG_REQ_I  : in std_logic;
    CONFIG_I      : in atc_config_t;
    
    POKE_C_I      : in std_logic;  -- CDC
    MASK_C_I      : in std_logic_vector(C_NUM_TILE-1 downto 0);
    POKE_D_I      : in std_logic;  -- CDC 
    MASK_D_I      : in std_logic_vector(C_NUM_TILE-1 downto 0);

    STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    CLK_B_I       : in std_logic;
    RST_B_I       : in std_logic;

    CONFIG_O      : out atc_config_t;

    POKE_C_O      : out std_logic; 
    MASK_C_O      : out std_logic_vector(C_NUM_TILE-1 downto 0);
    POKE_D_O      : out std_logic;
    MASK_D_O      : out std_logic_vector(C_NUM_TILE-1 downto 0)
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
      PAYLOAD_WIDTH => 10 
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
      PAYLOAD_WIDTH => 10 
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
  
  STATUS_O <= status;  
  status(0) <= cfg_busy;
  status(1) <= pkc_busy;
  status(2) <= pkd_busy;
  
  
  
  

end behaviour;
