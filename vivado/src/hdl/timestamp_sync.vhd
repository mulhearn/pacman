library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

--timestamp_sync

entity timestamp_sync is
  port (
    CLK_I	        : in  std_logic;
    RST_I	        : in  std_logic;
    TIMESTAMP_O         : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    TOGGLE_A            : in std_logic;
    TSYNC_A             : in std_logic
  );
end;

architecture behavioral of timestamp_sync is
  signal clk       : std_logic;
  signal rst       : std_logic;
  signal counter   : unsigned(C_TIMESTAMP_WIDTH-1 downto 0) := (others => '0');

  -- double flopping at clock domain crossing:
  signal toggle_meta : std_logic; -- metastable
  signal toggle_sync : std_logic; -- likely stable
  signal toggle_prev : std_logic;

  -- double flopping at clock domain crossing:
  signal tsync_meta : std_logic; -- metastable
  signal tsync_sync : std_logic; -- likely stable
  signal tsync_prev : std_logic;

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of toggle_meta: signal is "TRUE";
  attribute ASYNC_REG of toggle_sync: signal is "TRUE";
  attribute ASYNC_REG of tsync_meta: signal is "TRUE";
  attribute ASYNC_REG of tsync_sync: signal is "TRUE";

begin
  clk <= CLK_I;
  rst <= RST_I;
  TIMESTAMP_O <= std_logic_vector(counter);

  -- double flop synchronization of toggle:
  process(clk, rst)
  begin
    if (rst = '1') then
      toggle_meta <= '0';
      toggle_sync <= '0';
      toggle_prev <= '0';
    elsif (rising_edge(clk)) then
      toggle_meta <= TOGGLE_A;
      toggle_sync <= toggle_meta;
      toggle_prev <= toggle_sync;
    end if;
  end process;

  process(clk, rst)
  begin
    if (rst = '1') then
      tsync_meta <= '0';
      tsync_sync <= '0';
      tsync_prev <= '0';
    elsif (rising_edge(clk)) then
      tsync_meta <= TSYNC_A;
      tsync_sync <= tsync_meta;
      tsync_prev <= tsync_sync;
    end if;
  end process;

  process(clk, rst)
  begin
    if (rst='1') then
      counter <= (others => '0');
    elsif (rising_edge(clk)) then
      if (toggle_prev /= toggle_sync) then
        counter <= counter + 1;
      end if;
      if (tsync_sync = '1') then
        counter <= (others => '0');
      end if;
    end if;
  end process;
end;
