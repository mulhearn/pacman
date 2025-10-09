library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity async_input is
  port (
    CLK_I  : in  std_logic;
    RST_I  : in  std_logic;

    ASYNC_SIGNAL_I : in std_logic;
    POLARITY_I     : in std_logic;
    UPDATE_O       : out std_logic
  );
end;

architecture behavioral of async_input is
  signal clk    : std_logic; 
  signal rst    : std_logic;

  -- double flopping at clock domain crossing:
  signal signal_meta : std_logic; -- metastable
  signal signal_sync : std_logic; -- likely stable
  
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of signal_meta: signal is "TRUE";
  attribute ASYNC_REG of signal_sync: signal is "TRUE";

  signal signal_prev : std_logic;

  signal pulse : std_logic;     
    
begin
  UPDATE_O <= pulse;
  
  -- double flop synchronization of update signal
  -- synchronize request into board domain
  signal_process : process(clk, rst)
  begin
    if (rst = '1') then
      signal_meta <= '1';
      signal_sync <= '1';
      signal_prev <= '1';
    elsif (rising_edge(clk)) then
      if (POLARITY_I='1') then
        signal_meta <= not ASYNC_SIGNAL_I;
      else
        signal_meta <= ASYNC_SIGNAL_I;
      end if;
      signal_sync <= signal_meta;
      signal_prev <= signal_sync; 
    end if;
  end process;


  --output occurs when rising edge
  pulse_process : process(clk, rst)
  begin
    if (rst = '1') then
      pulse <= '0';
    elsif (rising_edge(clk)) then
      if (signal_sync = '1' and signal_prev = '0') then
        pulse <= '1';
      else
        pulse <= '0';
      end if;
    end if;
  end process;



end;
