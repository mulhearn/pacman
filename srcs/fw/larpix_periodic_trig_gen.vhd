library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_periodic_trig_gen is
  generic(
    LEN : unsigned(7 downto 0) := x"14"
    );
  port (
    ACLK : in std_logic;
    ARESETN : in std_logic;

    -- config
    EN : in std_logic;
    CYCLES : in unsigned(31 downto 0);

    -- output
    O : out std_logic
    );
end larpix_periodic_trig_gen;

architecture implementation of larpix_periodic_trig_gen is                     

  type state is ( IDLE,
                  TRIG );
  signal mst_exec_state : state;

  signal trig_out : std_logic;

  signal trigger_counter : unsigned(31 downto 0);
  signal trigger_len_counter : unsigned(7 downto 0);

begin

  O <= trig_out;

  trig_fsm : process (ACLK, ARESETN) is
  begin
    if (rising_edge(ACLK)) then
      if (ARESETN = '0') then -- synchronous reset
        trig_out <= '0';
        trigger_counter <= (others => '0');
        trigger_len_counter <= (others => '0');
        mst_exec_state <= IDLE;

      else
        -- increment counter
        if (trigger_counter > 0) then
          trigger_counter <= trigger_counter - 1;
        end if;
        
        -- fsm
        case (mst_exec_state) is
          when IDLE =>
            trig_out <= '0';
            
            if (trigger_counter = 0 and EN = '1') then
              trigger_counter <= CYCLES;
              trigger_len_counter <= LEN;
              mst_exec_state <= TRIG;
            end if;
            
          when TRIG =>
            trig_out <= '1';
            if (trigger_len_counter > 0) then
              trigger_len_counter <= trigger_len_counter - 1;
            end if;

            if (trigger_len_counter = 0) then
              mst_exec_state <= IDLE;
            end if;

          when others =>
            mst_exec_state <= IDLE;
        end case;
      end if;
    end if;
  end process;

end implementation;
