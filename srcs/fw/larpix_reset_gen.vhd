library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_reset_gen is
  generic (
    -- defined reset lengths
    C_SYNC_RST_CYCLES : integer := 10;
    C_STATE_RST_CYCLES : integer := 24;
    C_HARD_RST_CYCLES : integer := 256
    );
  port (
    MCLK : in std_logic;
    RSTN : in std_logic; -- sync reset with mclk, issues hard reset on rst_sync_n

    -- sofware reset (trigger with high then low)
    SW_RST_CYCLES : in unsigned(31 downto 0);
    SW_RST_TRIG : in std_logic;

    -- hardware reset (trigger with high for 2 MCLK cycle)
    HW_SYNC_TRIG : in std_logic;
    HW_STATE_RST_TRIG : in std_logic;
    HW_HARD_RST_TRIG : in std_logic;

    -- output
    RST_SYNC_N : out std_logic
    );
end larpix_reset_gen;

architecture arch_imp of larpix_reset_gen is
  -- state machine for issuing reset
  type state is (
    IDLE, SW_RESET, HW_RESET, SW_WAIT
    );
  signal mst_exec_state : state := IDLE;

  -- internal signals
  signal rst_cycles : unsigned(31 downto 0);
  signal rst_sync_n_out : std_logic;

  signal sw_rst_trig_srg : std_logic_vector(1 downto 0);
  signal hw_sync_trig_srg : std_logic_vector(1 downto 0);
  signal hw_state_rst_trig_srg : std_logic_vector(1 downto 0);
  signal hw_hard_rst_trig_srg : std_logic_vector(1 downto 0);

  signal sw_rst_trig_clean : std_logic;
  signal hw_sync_trig_clean : std_logic;
  signal hw_state_rst_trig_clean : std_logic;
  signal hw_hard_rst_trig_clean : std_logic;  
  
begin
  RST_SYNC_N <= rst_sync_n_out;

  glitch_rej : process (MCLK, RSTN) is
  begin
    if (rising_edge(MCLK)) then
      sw_rst_trig_srg <= SW_RST_TRIG & sw_rst_trig_srg(sw_rst_trig_srg'length-1);
      hw_sync_trig_srg <= HW_SYNC_TRIG & hw_sync_trig_srg(hw_sync_trig_srg'length-1);
      hw_state_rst_trig_srg <= HW_STATE_RST_TRIG & hw_state_rst_trig_srg(hw_state_rst_trig_srg'length-1);
      hw_hard_rst_trig_srg <= HW_HARD_RST_TRIG & hw_hard_rst_trig_srg(hw_hard_rst_trig_srg'length-1);

      if (sw_rst_trig_srg = "11") then
        sw_rst_trig_clean <= '1';
      else
        sw_rst_trig_clean <= '0';
      end if;

      if (hw_sync_trig_srg = "11") then
        hw_sync_trig_clean <= '1';
      else
        hw_sync_trig_clean <= '0';
      end if;

      if (hw_state_rst_trig_srg = "11") then
        hw_state_rst_trig_clean <= '1';
      else
        hw_state_rst_trig_clean <= '0';
      end if;

      if (hw_hard_rst_trig_srg = "11") then
        hw_hard_rst_trig_clean <= '1';
      else
        hw_hard_rst_trig_clean <= '0';
      end if;
    end if;
  end process;
  
  larpix_reset_fsm : process (MCLK, RSTN) is
  begin
    if (RSTN = '0') then
      mst_exec_state <= HW_RESET;
      rst_sync_n_out <= '0';
      rst_cycles <= to_unsigned(C_HARD_RST_CYCLES, rst_cycles'length) - 1;
      
    elsif (rising_edge(MCLK)) then
        case mst_exec_state is
          when IDLE =>
            rst_sync_n_out <= '1';
            if (sw_rst_trig_clean = '1') then
              rst_cycles <= SW_RST_CYCLES - 1;
              mst_exec_state <= SW_RESET;
            elsif (hw_sync_trig_clean = '1') then
              rst_cycles <= to_unsigned(C_SYNC_RST_CYCLES, rst_cycles'length) - 1;
              mst_exec_state <= HW_RESET;
            elsif (hw_state_rst_trig_clean = '1') then
              rst_cycles <= to_unsigned(C_STATE_RST_CYCLES, rst_cycles'length) - 1;
              mst_exec_state <= HW_RESET;
            elsif (hw_hard_rst_trig_clean = '1') then
              rst_cycles <= to_unsigned(C_HARD_RST_CYCLES, rst_cycles'length) - 1;
              mst_exec_state <= HW_RESET;
            end if;

          when HW_RESET =>
            rst_sync_n_out <= '0';
            rst_cycles <= rst_cycles - 1;
            if (rst_cycles = 0) then
              mst_exec_state <= IDLE;
            end if;

          when SW_RESET =>
            rst_sync_n_out <= '0';
            rst_cycles <= rst_cycles - 1;
            if (rst_cycles = 0) then
              mst_exec_state <= SW_WAIT;
            end if;

          when SW_WAIT =>
            rst_sync_n_out <= '1';
            if (SW_RST_TRIG = '0') then
              mst_exec_state <= IDLE;
            end if;
            
          when others =>
            mst_exec_state <= IDLE;
        end case;
      end if;
  end process;

end arch_imp;
