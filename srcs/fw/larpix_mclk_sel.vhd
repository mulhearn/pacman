library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity larpix_mclk_sel is
  generic(
    C_ACLK_PERIOD : real := 10.000; -- ns (100MHz)
    C_AUX_CLK_PERIOD : real := 50.000; -- ns (20MHz)
    C_VCO_MAX_FREQ : real := 1.600; -- Ghz
    C_PFD_MAX_FREQ : real := 0.450; -- Ghz
    C_VCO_MIN_FREQ : real := 0.800; -- Ghz
    C_PFD_MIN_FREQ : real := 0.019; -- Ghz
    C_MCLK_PERIOD : real := 100.000 -- ns (20MHz)
    );
  port (
    ACLK : in std_logic; -- default clock
    AUX_CLK : in std_logic; -- aux clock
    RSTN : in std_logic; -- async reset
    CLK_SEL : in std_logic; -- high to enable aux clock

    -- Synchronous statuses
    CLK_STAT_ACLK : out std_logic; -- which clock is currently used
    CLK_STAT_MCLK : out std_logic;
    CLK_VALID_ACLK : out std_logic; -- high if selected clock is locked
    CLK_VALID_MCLK : out std_logic;
    LOCKED_ACLK : out std_logic_vector(1 downto 0); -- PLL status
    LOCKED_MCLK : out std_logic_vector(1 downto 0);

    -- Output clock
    MCLK : out std_logic -- generated clock
    );
end larpix_mclk_sel;

architecture arch_imp of larpix_mclk_sel is

  constant C_PLL0_DIV : real := CEIL(1.000 / C_ACLK_PERIOD / C_PFD_MAX_FREQ);
  constant C_PLL1_DIV : real := CEIL(1.000 / C_AUX_CLK_PERIOD / C_PFD_MAX_FREQ);
  constant C_CLKFBOUT0_MULT : real := CEIL(C_VCO_MIN_FREQ * C_ACLK_PERIOD * C_PLL0_DIV);
  constant C_CLKFBOUT1_MULT : real := CEIL(C_VCO_MIN_FREQ * C_AUX_CLK_PERIOD * C_PLL0_DIV);
  --constant C_MCLK0_DIV : real := C_MCLK_PERIOD / C_ACLK_PERIOD * C_CLKFBOUT0_MULT / C_PLL0_DIV / 2.0;
  constant C_MCLK0_DIV : real := C_MCLK_PERIOD / C_ACLK_PERIOD * C_CLKFBOUT0_MULT / C_PLL0_DIV;
  --constant C_MCLK1_DIV : real := C_MCLK_PERIOD / C_AUX_CLK_PERIOD * C_CLKFBOUT1_MULT / C_PLL1_DIV / 2.0;
  constant C_MCLK1_DIV : real := C_MCLK_PERIOD / C_AUX_CLK_PERIOD * C_CLKFBOUT1_MULT / C_PLL1_DIV;

  attribute ASYNC_REG : string;
  
  component PLLE2_BASE is 
    generic(
      CLKIN1_PERIOD : real;
      CLKOUT0_DIVIDE : integer;
      CLKOUT0_DUTY_CYCLE : real;
      CLKOUT0_PHASE : real;
      DIVCLK_DIVIDE : integer;
      CLKFBOUT_MULT : integer
      );
    port(
      CLKIN1 : in std_logic;
      CLKFBIN : in std_logic;
      RST : in std_logic;
      CLKOUT0 : out std_logic;
      CLKOUT1 : out std_logic;
      CLKOUT2 : out std_logic;
      CLKOUT3 : out std_logic;
      CLKOUT4 : out std_logic;
      CLKOUT5 : out std_logic;
      CLKFBOUT : out std_logic;
      LOCKED : out std_logic;
      PWRDWN : in std_logic
      );
  end component;
  
  component BUFGMUX is
    port(
      O : out std_logic;
      I0 : in std_logic;
      I1 : in std_logic;
      S : in std_logic
      );
  end component;
  
  signal rst : std_logic;

  -- pll 0 signals
  signal mclk0 : std_logic;
  signal clk0_fbout : std_logic;
  signal locked0 : std_logic;

  -- pll 1 signals
  signal mclk1 : std_logic;
  signal clk1_fbout : std_logic;
  signal locked1 : std_logic;

  -- clock mux signals
  signal clk_sel_mclk0_meta : std_logic;
  signal clk_sel_mclk0 : std_logic;
  signal clk_valid_mclk0_meta : std_logic;
  signal clk_valid_mclk0 : std_logic;

  -- output signals
  signal locked_async : std_logic_vector(1 downto 0);
  signal clk_sel_async : std_Logic;
  signal clk_valid_async : std_logic;
  
  signal clk_stat_aclk_meta : std_logic;
  signal clk_stat_aclk_out : std_logic;
  signal clk_valid_aclk_meta : std_logic;
  signal clk_valid_aclk_out : std_logic;
  signal locked_aclk_meta : std_logic_vector(1 downto 0);
  signal locked_aclk_out : std_logic_vector(1 downto 0);
  signal clk_stat_mclk_meta : std_logic;
  signal clk_stat_mclk_out : std_logic;
  signal clk_valid_mclk_meta : std_logic;
  signal clk_valid_mclk_out : std_logic;
  signal locked_mclk_meta : std_logic_vector(1 downto 0);
  signal locked_mclk_out : std_logic_vector(1 downto 0);
  
  signal mclk2x : std_logic := '0';
  signal mclk_out : std_logic := '0';

  attribute ASYNC_REG of clk_sel_mclk0_meta: signal is "TRUE";
  attribute ASYNC_REG of clk_sel_mclk0: signal is "TRUE";
  attribute ASYNC_REG of clk_valid_mclk0_meta: signal is "TRUE";
  attribute ASYNC_REG of clk_valid_mclk0: signal is "TRUE";
  
  attribute ASYNC_REG of clk_stat_aclk_meta: signal is "TRUE";
  attribute ASYNC_REG of clk_stat_aclk_out: signal is "TRUE";
  attribute ASYNC_REG of clk_valid_aclk_meta: signal is "TRUE";
  attribute ASYNC_REG of clk_valid_aclk_out: signal is "TRUE";
  attribute ASYNC_REG of locked_aclk_meta: signal is "TRUE";
  attribute ASYNC_REG of locked_aclk_out: signal is "TRUE";
  
  attribute ASYNC_REG of clk_stat_mclk_meta: signal is "TRUE";
  attribute ASYNC_REG of clk_stat_mclk_out: signal is "TRUE";
  attribute ASYNC_REG of clk_valid_mclk_meta: signal is "TRUE";
  attribute ASYNC_REG of clk_valid_mclk_out: signal is "TRUE";
  attribute ASYNC_REG of locked_mclk_meta: signal is "TRUE";
  attribute ASYNC_REG of locked_mclk_out: signal is "TRUE";

begin
  -- Combinatoric signals
  rst <= not RSTN;
  locked_async <= locked1 & locked0;
  clk_sel_async <= CLK_SEL and locked1;
  clk_valid_async <= locked0 when clk_sel_async = '0' else
                     locked1 when clk_sel_async = '1';

  -- Out signals
  LOCKED_ACLK <= locked_aclk_out;
  LOCKED_MCLK <= locked_mclk_out;
  CLK_STAT_ACLK <= clk_stat_aclk_out;
  CLK_STAT_MCLK <= clk_stat_mclk_out;
  CLK_VALID_ACLK <= clk_valid_aclk_out;
  CLK_VALID_MCLK <= clk_valid_mclk_out;

  MCLK <= mclk_out;

  -- Frequency generation for default clock
  pll0 : PLLE2_BASE generic map(
    CLKIN1_PERIOD => C_ACLK_PERIOD,
    CLKOUT0_DIVIDE => integer(C_MCLK0_DIV),
    CLKOUT0_DUTY_CYCLE => 0.5,
    CLKOUT0_PHASE => 0.0,
    DIVCLK_DIVIDE => integer(C_PLL0_DIV),
    CLKFBOUT_MULT => integer(C_CLKFBOUT0_MULT)
    )
    port map(
      CLKIN1 => ACLK,
      CLKFBIN => clk0_fbout,
      RST => rst,
      CLKOUT0 => mclk0,
      CLKOUT1 => open,
      CLKOUT2 => open,
      CLKOUT3 => open,
      CLKOUT4 => open,
      CLKOUT5 => open,
      CLKFBOUT => clk0_fbout,
      LOCKED => locked0,
      PWRDWN => '0'
      );

  -- Frequency generation for aux clock
  pll1 : PLLE2_BASE generic map(
    CLKIN1_PERIOD => C_AUX_CLK_PERIOD,
    CLKOUT0_DIVIDE => integer(C_MCLK1_DIV),
    CLKOUT0_DUTY_CYCLE => 0.5,
    CLKOUT0_PHASE => 0.0,
    DIVCLK_DIVIDE => integer(C_PLL0_DIV),
    CLKFBOUT_MULT => integer(C_CLKFBOUT1_MULT)
    )
    port map(
      CLKIN1 => AUX_CLK,
      CLKFBIN => clk1_fbout,
      RST => rst,
      CLKOUT0 => mclk1,
      CLKOUT1 => open,
      CLKOUT2 => open,
      CLKOUT3 => open,
      CLKOUT4 => open,
      CLKOUT5 => open,
      CLKFBOUT => clk1_fbout,
      LOCKED => locked1,
      PWRDWN => '0'
      );

  -- Clock switch
  bufgmux_mclk : BUFGMUX port map(
--    O => mclk2x,
    O => mclk_out,
    I0 => mclk0,
    I1 => mclk1,
    S => clk_sel_mclk0
    );
  process (mclk0, RSTN) is
  begin
    if (RSTN = '0') then
      clk_sel_mclk0_meta <= '0';
      clk_sel_mclk0 <= '0';
      
    elsif (rising_edge(mclk0)) then
      clk_sel_mclk0_meta <= clk_sel_async;
      clk_sel_mclk0 <= clk_sel_mclk0_meta;
    end if;
  end process;
--  process (mclk2x, RSTN) is
--  begin
--    if (RSTN = '0') then
--      mclk_out <= '0';
      
--    elsif (rising_edge(mclk2x)) then
--      mclk_out <= not mclk_out;
--    end if;
--  end process;
      
  -- Synchronize output signals
  aclk_sync : process (ACLK, RSTN) is
  begin
    if (RSTN = '0') then
      clk_stat_aclk_meta <= '0';
      clk_stat_aclk_out <= '0';
      locked_aclk_meta <= (others => '0');
      locked_aclk_out <= (others => '0');
      clk_valid_aclk_meta <= '0';
      clk_valid_aclk_out <= '0';
      
    elsif (rising_edge(ACLK)) then
      clk_stat_aclk_meta <= clk_sel_async;
      clk_stat_aclk_out <= clk_stat_aclk_meta;
      locked_aclk_meta <= locked_async;
      locked_aclk_out <= locked_aclk_meta;
      clk_valid_aclk_meta <= clk_valid_async;
      clk_valid_aclk_out <= clk_valid_aclk_meta;
    end if;
  end process;
  mclk_sync : process (mclk_out, RSTN) is
  begin
    if (RSTN = '0') then
      clk_stat_mclk_meta <= '0';
      clk_stat_mclk_out <= '0';
      locked_mclk_meta <= (others => '0');
      locked_mclk_out <= (others => '0');
      clk_valid_mclk_meta <= '0';
      clk_valid_mclk_out <= '0';
      
    elsif (rising_edge(mclk_out)) then
      clk_stat_mclk_meta <= clk_sel_async;
      clk_stat_mclk_out <= clk_stat_mclk_meta;
      locked_mclk_meta <= locked_async;
      locked_mclk_out <= locked_mclk_meta;
      clk_valid_mclk_meta <= clk_valid_async;
      clk_valid_mclk_out <= clk_valid_mclk_meta;
    end if;
  end process;
  
end arch_imp;
