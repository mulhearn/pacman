library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity larpix_mclk_sel_tb is
  port(
    CLK_STAT_ACLK : out std_logic;
    CLK_STAT_MCLK : out std_logic;    
    CLK_VALID_ACLK : out std_logic;
    CLK_VALID_MCLK : out std_logic;    
    LOCKED_ACLK : out std_logic_vector(1 downto 0);
    LOCKED_MCLK : out std_logic_vector(1 downto 0);    
    MCLK : out std_logic
    );
end larpix_mclk_sel_tb;

architecture arch_imp of larpix_mclk_sel_tb is
  component larpix_mclk_sel is
    generic(
      C_ACLK_PERIOD : real := 10.000; -- ns (100MHz)
      C_AUX_CLK_PERIOD : real := 10.000; -- ns (100MHz)
      C_MCLK_PERIOD : real := 10.000 -- ns (100MHz)
      );
    port (
      ACLK : in std_logic;
      AUX_CLK : in std_logic;
      RSTN : in std_logic;
      CLK_SEL : in std_logic;
      MCLK_COUNT : in std_logic_vector(7 downto 0);
      CLK_STAT_ACLK : out std_logic;
      CLK_STAT_MCLK : out std_logic;
      CLK_VALID_ACLK : out std_logic;
      CLK_VALID_MCLK : out std_logic;      
      LOCKED_ACLK : out std_logic_vector(1 downto 0);
      LOCKED_MCLK : out std_logic_vector(1 downto 0);
      MCLK : out std_logic
      );
  end component;

  signal clk : std_logic := '1';
  signal clk_aux : std_logic := '1';
  signal clk_aux_flaky : std_logic := '1';
  signal clk_aux_cnt : unsigned(11 downto 0) := x"000";
  signal rstn : std_logic := '0';
  signal clk_sel : std_logic := '0';
  signal mclk_count_set : std_logic_vector(7 downto 0) := b"00000101";
  
begin
  clk <= not clk after 5 ns;
  clk_aux <= not clk_aux after 15 ns;

  flaky_clock : process (clk_aux) is
  begin
    if (clk_aux'event) then
      clk_aux_cnt <= clk_aux_cnt + 1;
      -- drop the aux clock at some point
      if (clk_aux_cnt > 3072) then
        clk_aux_flaky <= '0';
      else
        clk_aux_flaky <= clk_aux;
      end if;
    end if;
  end process;
  
  process is
  begin
    -- reset
    rstn <= '0';
    wait for 100 ns;
    rstn <= '1';
    wait until rstn <= '1' and rising_edge(clk);

    -- switch clocks
    wait for 10000 ns;
    clk_sel <= not clk_sel;
    wait for 10000 ns;

    -- switch clock speed (slower)
    mclk_count_set <= x"09";
    wait for 10000 ns;

    -- switch clock speed (faster)
    mclk_count_set <= x"00";
    wait for 10000 ns;
    -- reset clock speed
    mclk_count_set <= x"04";
    wait for 10000 ns;
  end process;

  larpix_mclk_sel_inst : larpix_mclk_sel generic map(
    C_ACLK_PERIOD => 10.000,
    C_AUX_CLK_PERIOD => 30.000
    )
    port map(
      ACLK => clk,
      AUX_CLK => clk_aux_flaky,
      RSTN => rstn,
      CLK_SEL => clk_sel,
      MCLK_COUNT => mclk_count_set,
      CLK_STAT_ACLK => CLK_STAT_ACLK,
      CLK_STAT_MCLK => CLK_STAT_MCLK,      
      CLK_VALID_ACLK => CLK_VALID_ACLK,
      CLK_VALID_MCLK => CLK_VALID_MCLK,      
      LOCKED_ACLK => LOCKED_ACLK,
      LOCKED_MCLK => LOCKED_MCLK,      
      MCLK => MCLK
      );
    
end arch_imp;
