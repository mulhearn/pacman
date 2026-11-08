library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
--use work.common.all;

entity legacy_1v4 is
  generic (
    constant C_NUM_PS_LEGACY     : integer := 32;
    constant C_NUM_PS            : integer := 40;
    constant C_NUM_SYNC         : integer := 10;
    constant C_NUM_TRIG         : integer := 10;
    constant C_NUM_TRIG_LEGACY  : integer := 8;
    constant C_NUM_EN           : integer := 10;
    constant C_NUM_EN_LEGACY    : integer := 8;
    constant ADC_DATA_WIDTH     : integer :=13
  );
  port (
    LEGACY_PISO_I               : in  std_logic_vector(C_NUM_PS_LEGACY -1 downto 0);
    PISO_O                      : out std_logic_vector(C_NUM_PS -1 downto 0);
    POSI_I                      : in  std_logic_vector(C_NUM_PS -1 downto 0);
    LEGACY_POSI_O               : out std_logic_vector(C_NUM_PS_LEGACY -1 downto 0);
    SYNCN_I                     : in  std_logic_vector(C_NUM_SYNC -1 downto 0);
    LEGACY_RSTN_O               : out std_logic;
    TRIG_I                      : in  std_logic_vector(C_NUM_TRIG -1 downto 0);
    LEGACY_SYNCN_O              : out std_logic_vector(C_NUM_TRIG_LEGACY -1 downto 0);
    TILE_EN_I                   : in  std_logic_vector(C_NUM_EN -1 downto 0);
    LEGACY_TILE_EN_O            : out std_logic_vector(C_NUM_EN_LEGACY -1 downto 0)


    ---------------------------------------------------------
    ------------------------adc------------------------------
    --ADC_EN_O            : out std_logic;
    --ADC_CLK_O           : out std_logic;
    --ADC_DATA_I          : in  std_logic_vector(ADC_DATA_WIDTH-2 downto 0);
    --ADC_DOF_I           : in  std_logic
    );
end entity;

architecture behavioral of legacy_1v4 is
begin
  --PISO
  PISO_O(31 downto 0)         <= LEGACY_PISO_I;
  PISO_O(39 downto 32)        <= POSI_I(39 downto 32);
  --POSI
  LEGACY_POSI_O               <= POSI_I(31 downto 0);

  --SYNC
  LEGACY_RSTN_O                <= '0' when (SYNCN_I /= (SYNCN_I'range => '1')) else '1';

  --TRIG
  LEGACY_SYNCN_O              <= TRIG_I(7 downto 0);

  --TILE_EN
  LEGACY_TILE_EN_O            <= TILE_EN_I(7 downto 0);

  --ADC
  --ADC_EN_O                  <= '0';
  --ADC_CLK_O                 <= '0';
end behavioral;