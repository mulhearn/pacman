library ieee;
use ieee.std_logic_1164.all;
use work.common.all;

-- atc_pkg.vhd
-- ATC specific defitions and constants

package atc_pkg is
  type atc_config_t is record
    polarity      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    logic         : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    dst_lemo_a    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    dst_lemo_b    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    dst_poke_c    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    dst_poke_d    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    dst_logic_e   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    dst_logic_f   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  end record;

  constant ATC_CONFIG_DEFAULT : atc_config_t := (
    polarity    => (others => '0'),
    logic       => (others => '0'),
    dst_lemo_a  => (others => '0'),
    dst_lemo_b  => (others => '0'),
    dst_poke_c  => (others => '0'),
    dst_poke_d  => (others => '0'),
    dst_logic_e => (others => '0'),
    dst_logic_f => (others => '0')
  );
end package;
