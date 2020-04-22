library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_counter_tb is
  port (
    COUNTER : out unsigned(31 downto 0);
    COUNTER_PREV : out unsigned(31 downto 0);
    ROLLOVER_SYNC : out std_logic
    );
end larpix_counter_tb;

architecture arch_imp of larpix_counter_tb is

  component larpix_counter is
    generic(
      C_ROLLOVER_VALUE : unsigned(31 downto 0)
      );
    port (
      MCLK : in std_logic;
      RSTN : in std_logic;
      COUNTER : out unsigned(31 downto 0);
      COUNTER_PREV : out unsigned(31 downto 0);
      ROLLOVER_SYNC : out std_logic
      );
  end component;
  
  signal clk : std_logic := '1';
  signal rstn : std_logic := '0';

  signal counter_out : unsigned(31 downto 0);
  signal counter_prev_out : unsigned(31 downto 0);
  signal rollover_sync_out : std_logic;
  
begin

  clk <= not clk after 50 ns;

  COUNTER <= counter_out;
  COUNTER_PREV <= counter_prev_out;
  ROLLOVER_SYNC <= rollover_sync_out;

  process
  begin
    rstn <= '0';
    wait for 1000 ns;
    rstn <= '1';
    wait until rising_edge(clk) and counter_out = x"0000000F";
    rstn <= '0';
    wait for 1000 ns;
    wait until rising_edge(clk);
    rstn <= '1';
    wait until rising_edge(clk) and counter_out = x"FFFFFFFF";
    wait for 1000 ns;
  end process;

  larpix_counter_inst : larpix_counter generic map(
    C_ROLLOVER_VALUE => x"000000ff"
    )
  port map(
    MCLK => clk,
    RSTN => rstn,
    COUNTER => counter_out,
    COUNTER_PREV => counter_prev_out,
    ROLLOVER_SYNC => rollover_sync_out
    );

end arch_imp;
