library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity timestamp_fast_sync is

  port (
    CLK_I	      : in  std_logic;
    RST_I	      : in  std_logic;    
    TIMESTAMP_SLOW_I  : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    TIMESTAMP_FAST_O  : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0)
    );
end;

architecture behavioral of timestamp_fast_sync is
  signal clk             : std_logic;
  signal rst             : std_logic;
  signal timestamp_good  : unsigned(C_TIMESTAMP_WIDTH-1 downto 0);
  signal timestamp_prev  : unsigned(C_TIMESTAMP_WIDTH-1 downto 0);


  -- double flopping at clock domain crossing:
  signal timestamp_meta : unsigned(C_TIMESTAMP_WIDTH-1 downto 0) := (others => '0'); -- metastable
  signal timestamp_sync : unsigned(C_TIMESTAMP_WIDTH-1 downto 0) := (others => '0');
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of timestamp_meta: signal is "TRUE";
  attribute ASYNC_REG of timestamp_sync: signal is "TRUE";

begin
  clk  <= CLK_I;
  rst  <= RST_I;
  TIMESTAMP_FAST_O <= std_logic_vector(timestamp_good);

  -- double flop synchronization of timestamp (from slow to fast)
  process(clk, rst)
  begin
    if (rst = '1') then
      timestamp_meta <= (others => '0');
      timestamp_sync <= (others => '0');
      timestamp_good <= (others => '0');
      timestamp_prev <= (others => '0');
    elsif (rising_edge(clk)) then
      timestamp_prev <= timestamp_good;
      timestamp_meta <= unsigned(TIMESTAMP_SLOW_I);
      timestamp_sync <= timestamp_meta;
      -- suppress single cycle clock domain crossing glitches by only accepting
      -- valid transitions (reset or increment):
      if (timestamp_sync = to_unsigned(0, timestamp_sync'length)) then
        timestamp_good <= (others => '0');
      elsif (timestamp_sync = timestamp_good+1) then
        timestamp_good <= timestamp_sync;
      end if;
    end if;
  end process;

end;
