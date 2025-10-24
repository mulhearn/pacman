library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
use work.atc_pkg.all;

-- Request a config update in a different clock domain

entity config_sync is
  port (
    -- clock and active-high reset for slow clock domain:
    CLK_I	    : in  std_logic;
    RST_I	    : in  std_logic;

    -- asynchronous input configuration, held stable during update request:
    CONFIG_A            : in atc_config_t;

    -- output configuration (synchronized):
    SHADOW_O            : out atc_config_t;

    -- interface to the update request in the fast clock domain
    REPLY_O   : out std_logic;
    REQUEST_A : in  std_logic
  );
end;

architecture behavioral of config_sync is
  signal clk         : std_logic;
  signal rst         : std_logic;
  signal update_comb : std_logic;
  signal done        : std_logic;

  signal shadow      : atc_config_t;

  signal config      : atc_config_t;
  -- flatten record for sure-fire application of attributes:
  signal polarity    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal logic       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_lemo_a  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_lemo_b  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_poke_c  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_poke_d  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_logic_e : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_logic_f : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of polarity     : signal is "TRUE";
  attribute ASYNC_REG of logic        : signal is "TRUE";
  attribute ASYNC_REG of dst_lemo_a   : signal is "TRUE";
  attribute ASYNC_REG of dst_lemo_b   : signal is "TRUE";
  attribute ASYNC_REG of dst_poke_c   : signal is "TRUE";
  attribute ASYNC_REG of dst_poke_d   : signal is "TRUE";
  attribute ASYNC_REG of dst_logic_e  : signal is "TRUE";
  attribute ASYNC_REG of dst_logic_f  : signal is "TRUE";

  component update_reply is
    port (
      CLK_I	    : in  std_logic;
      RST_I	    : in  std_logic;
      UPDATE_O      : out std_logic;
      UPDATE_COMB_O : out std_logic;
      DONE_I        : in  std_logic;
      REQUEST_A     : in  std_logic;
      REPLY_O       : out std_logic
      );
  end component;

begin
  clk <= CLK_I;
  rst <= RST_I;

  --connect flattened signals (for attribute assignment) to the record:
  polarity     <= CONFIG_A.polarity;
  logic        <= CONFIG_A.logic;
  dst_lemo_a   <= CONFIG_A.dst_lemo_a;
  dst_lemo_b   <= CONFIG_A.dst_lemo_b;
  dst_poke_c   <= CONFIG_A.dst_poke_c;
  dst_poke_d   <= CONFIG_A.dst_poke_d;
  dst_logic_e  <= CONFIG_A.dst_logic_e;
  dst_logic_f  <= CONFIG_A.dst_logic_f;



  SHADOW_O <= shadow;

  reply0: update_reply port map (
    CLK_I           => clk,
    RST_I           => rst,
    UPDATE_COMB_O   => update_comb,
    DONE_I          => done,
    REQUEST_A       => REQUEST_A,
    REPLY_O         => REPLY_O
  );

  shadow0: process(clk, rst)
    variable update : std_logic;
  begin
    if (rst = '1') then
      update := '0';
      done <= '0';
      shadow      <= ATC_CONFIG_DEFAULT;
    elsif (rising_edge(clk)) then
      done <= update;
      if (update_comb = '1') then
        update := '1';
        shadow.polarity     <= polarity;
        shadow.logic        <= logic;
        shadow.dst_lemo_a   <= dst_lemo_a;
        shadow.dst_lemo_b   <= dst_lemo_b;
        shadow.dst_poke_c   <= dst_poke_c;
        shadow.dst_poke_d   <= dst_poke_d;
        shadow.dst_logic_e  <= dst_logic_e;
      else
        update := '0';
        shadow              <= shadow;
      end if;
    end if;
  end process;

end;
