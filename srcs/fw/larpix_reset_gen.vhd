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
  
begin
  RST_SYNC_N <= rst_sync_n_out;
  
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
            if (SW_RST_TRIG = '1') then
              rst_cycles <= SW_RST_CYCLES - 1;
              mst_exec_state <= SW_RESET;
            elsif (HW_SYNC_TRIG = '1') then
              rst_cycles <= to_unsigned(C_SYNC_RST_CYCLES, rst_cycles'length) - 1;
              mst_exec_state <= HW_RESET;
            elsif (HW_STATE_RST_TRIG = '1') then
              rst_cycles <= to_unsigned(C_STATE_RST_CYCLES, rst_cycles'length) - 1;
              mst_exec_state <= HW_RESET;
            elsif (HW_HARD_RST_TRIG = '1') then
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
