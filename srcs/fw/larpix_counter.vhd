library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- mimics the behavior of the larpix-v2 ASIC timestamp with aux signals to
-- identify resets and rollovers
entity larpix_counter is
  generic(
    C_REJECT_CYCLES : integer := 3;
    C_RESET_DELAY : integer := 2;
    C_ROLLOVER_VALUE : unsigned(31 downto 0) := x"FFFFFFFF"
    );
  port (
    MCLK : in std_logic;
    RSTN : in std_logic;

    -- counter values
    COUNTER : out unsigned(31 downto 0);
    COUNTER_PREV : out unsigned(31 downto 0);

    -- '1' for 1 MCLK clock cycle if rollover or sync (latched counter on COUNTER_PREV)
    ROLLOVER_SYNC : out std_logic
    );
end larpix_counter;

architecture arch_imp of larpix_counter is

  type state is ( IDLE,
                  RESET_WT,
                  RESET );
  signal fsm_state : state := IDLE;   

  -- internal signals
  signal counter_out : unsigned(31 downto 0) := (others => '0');
  signal counter_prev_out : unsigned(31 downto 0) := (others => '0');
  signal rollover_sync_out : std_logic := '0';
  signal rstn_srg : std_logic_vector(C_REJECT_CYCLES-1 downto 0);
  signal rst_srg : std_logic_vector(C_RESET_DELAY-1 downto 0);
  
begin
  
  COUNTER <= counter_out;
  COUNTER_PREV <= counter_prev_out;
  ROLLOVER_SYNC <= rollover_sync_out;

  process (MCLK) is
  begin
    if (rising_edge(MCLK)) then
        -- increment counters
        counter_out <= counter_out + 1;
        rstn_srg <= RSTN & rstn_srg(rstn_srg'length-1 downto 1);
        rst_srg <= (not RSTN) & rst_srg(rst_srg'length-1 downto 1);
        
        case fsm_state is
          when IDLE =>
            rollover_sync_out <= '0';
            -- forced reset
            if (unsigned(rstn_srg) = 0) then
              fsm_state <= RESET;
            -- rollover
            elsif (counter_out = C_ROLLOVER_VALUE) then
              counter_prev_out <= counter_out;
              counter_out <= (others => '0');
              rollover_sync_out <= '1';
              fsm_state <= IDLE;
            end if;
            
          when RESET =>
            if (unsigned(rst_srg) = 0) then
              rollover_sync_out <= '1';
              counter_prev_out <= counter_out;
              counter_out <= (others => '0');
              fsm_state <= IDLE;
            end if;
            
          when others =>
            fsm_state <= IDLE;
        end case;
      end if;
  end process;

end arch_imp;
