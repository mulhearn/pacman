library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.common.all;

--  Defines a testbench (without any ports)
entity poke_bridge is
  port (
    CLK_FAST_I : in std_logic;
    RST_FAST_I : in std_logic;

    CLK_SLOW_I : in std_logic;
    RST_SLOW_I : in std_logic;

    POKE_C_O            : out std_logic;  -- CDC
    MASK_C_O            : out std_logic_vector(C_NUM_TILE-1 downto 0); -- CDC
    POKE_D_O            : out std_logic;  -- CDC 
    MASK_D_O            : out std_logic_vector(C_NUM_TILE-1 downto 0); -- CDC

    -- The following configuration registers may be written at any time,
    -- but will have no impact until the next ACT_UPDATE_CONFIGS request.

    -- polarity of ATC inputs and outputs (active-high=0, active-low=1):
    CONFIG_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    
    -- polarity of ATC inputs and outputs (active-high=0, active-low=1):
    POLARITY_O          : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- configure the logic that produces stimuli E and F
    LOGIC_O             : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    
    -- destination for input stimuli: (where they are going, and for how long)
    DST_LEMO_A_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_LEMO_B_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_POKE_C_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_POKE_D_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_LOGIC_E_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_LOGIC_F_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- interface to counters:
    -- The counts are as reported at the last UPDATE_COUNTS, which also resets
    -- the running counters.  (You can update once, then read all counts at leisure)
    COUNT_SELECT_O      : out std_logic_vector(C_ATC_COUNT_SELECT_WIDTH-1 downto 0);
    COUNT_I             : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- these registers are in out clock domain (CLK):
    STATUS_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    TIMESTAMP_I         : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0)    
  );



end poke_bridge;

architecture behaviour of poke_bridge is
  signal clk_fast    : std_logic;
  signal rst_fast    : std_logic;
  signal clk_slow    : std_logic;
  signal rst_slow    : std_logic;

  signal update_fast : std_logic := '0';
  signal update_slow : std_logic;
  signal update_comb : std_logic;
  signal request     : std_logic;
  signal busy        : std_logic;
  signal reply       : std_logic;
  signal done        : std_logic;

  component update_request is
    port (
      CLK_I	    : in  std_logic;
      RST_I	    : in  std_logic;
      UPDATE_I      : in std_logic;
      BUSY_O        : out std_logic;
      REQUEST_O     : out std_logic;
      ASYNC_REPLY_I : in std_logic
      );
  end component;

  component update_reply is
    port (
      CLK_I	      : in  std_logic;
      RST_I	      : in  std_logic;
      UPDATE_O        : out std_logic;
      UPDATE_COMB_O   : out std_logic;
      ASYNC_REQUEST_I : in  std_logic;
      DONE_I          : in  std_logic; 
      REPLY_O         : out std_logic
    );
  end component;

begin
  dut0: update_request port map (
    CLK_I          => clk,
    RST_I          => rst,
    UPDATE_I       => update_fast,
    BUSY_O         => busy,
    REQUEST_O      => request,
    ASYNC_REPLY_I  => reply
    );

  dut2: update_reply port map (
    CLK_I           => uclk,
    RST_I           => rst,
    UPDATE_O        => update_slow,
    UPDATE_COMB_O   => update_comb,
    ASYNC_REQUEST_I => request,
    DONE_I          => done,
    REPLY_O         => reply
  );


end behaviour;
