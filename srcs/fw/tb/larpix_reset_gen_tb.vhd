library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_reset_gen_tb is
  port (
    RST_SYNC_N : out std_logic
    );
end larpix_reset_gen_tb;

architecture arch_imp of larpix_reset_gen_tb is

  component larpix_reset_gen is
    port (
      MCLK : in std_logic;
      RSTN : in std_logic;  
      SW_RST_CYCLES : in unsigned(31 downto 0);
      SW_RST_TRIG : in std_logic;
      HW_SYNC_TRIG : in std_logic;
      HW_STATE_RST_TRIG : in std_logic;
      HW_HARD_RST_TRIG : in std_logic;
      RST_SYNC_N : out std_logic
      );
  end component;

  signal clk : std_logic := '1';
  signal rstn : std_logic := '0';
  
  signal sw_rst_cycles : unsigned(31 downto 0) := x"00000014"; -- 20
  signal sw_rst_trig : std_logic := '0';

  signal hw_sync_trig : std_logic := '0';
  signal hw_state_rst_trig : std_logic := '0';
  signal hw_hard_rst_trig : std_logic := '0';

  signal rst_sync_n_out : std_logic;
  
begin

  clk <= not clk after 50 ns;

  rstn <= '0' after 0 ns,
          '1' after 1000 ns;

  RST_SYNC_N <= rst_sync_n_out;
  
  process
  begin
    wait until rising_edge(clk) and rstn = '1';
    wait for 1000 ns;

    -- software reset
    wait until rising_edge(clk) and rst_sync_n_out = '1';
    sw_rst_trig <= '1';
    wait for 200 ns;
    sw_rst_trig <= '0';
    wait for 1000 ns;

    -- hardware sync
    wait until rising_edge(clk) and rst_sync_n_out = '1';
    hw_sync_trig <= '1';
    wait for 200 ns;
    hw_sync_trig <= '0';
    wait for 1000 ns;
    
    wait until rising_edge(clk) and rst_sync_n_out = '1';
    hw_sync_trig <= '1';
    wait for 10000 ns;
    hw_sync_trig <= '0';
    wait for 1000 ns;

    -- hardware hard reset
    wait until rising_edge(clk) and rst_sync_n_out = '1';
    hw_hard_rst_trig <= '1';
    wait for 200 ns;
    hw_hard_rst_trig <= '0';
    wait for 1000 ns;

    -- hardware state reset
    wait until rising_edge(clk) and rst_sync_n_out = '1';
    hw_state_rst_trig <= '1';
    wait for 200 ns;
    hw_state_rst_trig <= '0';
    wait for 1000 ns;
  end process;

  larpix_reset_gen_inst : larpix_reset_gen port map(
    MCLK => clk,
    RSTN => rstn,
    SW_RST_CYCLES => sw_rst_cycles,
    SW_RST_TRIG => sw_rst_trig,
    HW_SYNC_TRIG => hw_sync_trig,
    HW_STATE_RST_TRIG => hw_state_rst_trig,
    HW_HARD_RST_TRIG => hw_hard_rst_trig,
    RST_SYNC_N => rst_sync_n_out
    );

end arch_imp;
