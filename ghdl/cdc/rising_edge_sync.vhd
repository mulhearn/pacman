library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity rising_edge_sync is
  -- DEBOUNCE_CYCLES: minimum clock-cycles before next pulse
  --
  -- Note that only values > 3 have any effect, as rising edge
  -- detection requires 3 clock-cycles minimum
  generic ( DEBOUNCE_CYCLES : integer := 4 );

  port (
    --clock and active-high reset in receiver clock-domain
    CLK_I  : in  std_logic;
    RST_I  : in  std_logic;

    --asynchronous signal in
    ASYNC_SIGNAL_I : in std_logic;  --CDC

    --polarity of input signal (0 means active high, 1 is active low)
    POLARITY_I     : in std_logic;

    --a rising edge (from low to high) on the inputs causes UPDATE_O to go high
    --for one clock cycle.
    UPDATE_O       : out std_logic
  );
end;

architecture behavioral of rising_edge_sync is
  signal clk    : std_logic;
  signal rst    : std_logic;

  -- double flopping at clock domain crossing:
  signal signal_meta : std_logic; -- metastable
  signal signal_sync : std_logic; -- likely stable

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of signal_meta: signal is "TRUE";
  attribute ASYNC_REG of signal_sync: signal is "TRUE";

  type debounce_pipe_t is array (natural range <>) of std_logic;
  signal signal_pipe : debounce_pipe_t(1 downto 0);

  signal pulse : std_logic := '0';

begin
  clk <= CLK_I;
  rst <= RST_I;
  UPDATE_O <= pulse;

  -- double flop synchronization of update signal
  -- synchronize request into board domain
  signal_process : process(clk, rst)

  begin
    if (rst = '1') then
      signal_meta <= '1';
      signal_sync <= '1';
      signal_pipe <= (others => '1');
    elsif (rising_edge(clk)) then
      signal_meta    <= ASYNC_SIGNAL_I;
      signal_sync    <= signal_meta;
      signal_pipe(0) <= signal_sync;
      signal_pipe(1) <= signal_pipe(0);
    end if;
  end process;


  --output occurs when rising edge
  pulse_process : process(clk, rst)
    variable timeout : integer := 0;
  begin
    if (rst = '1') then
      pulse <= '0';
    elsif (rising_edge(clk)) then
      if (signal_sync = '1' and signal_pipe(0) = '1' and signal_pipe(1) = '0' and timeout=0) then
        timeout := DEBOUNCE_CYCLES;
        pulse <= '1';
      else
        pulse <= '0';
      end if;

      if (timeout > 0) then
        timeout := timeout - 1;
      end if;


    end if;
  end process;



end;
