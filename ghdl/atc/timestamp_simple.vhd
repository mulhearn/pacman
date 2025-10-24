library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

--timestamp_simple

entity timestamp_simple is
  port (
    CLK_I	        : in  std_logic;
    RST_I	        : in  std_logic;
    TIMESTAMP_O         : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    TOGGLE_O            : out std_logic;
    TSYNC_O             : out std_logic
  );
end;

architecture behavioral of timestamp_simple is
  signal clk       : std_logic;
  signal rst       : std_logic;
  signal counter   : unsigned(C_TIMESTAMP_WIDTH-1 downto 0) := (others => '0');
  signal toggle    : std_logic;
  signal tsync     : std_logic;

begin
  clk <= CLK_I;
  rst <= RST_I;
  TIMESTAMP_O <= std_logic_vector(counter);
  TOGGLE_O    <= toggle;
  TSYNC_O     <= tsync;

  process(clk, rst)
  begin
    if (rst='1') then
      counter <= (others => '0');
      toggle  <= '0';
      tsync   <= '1';
    elsif (rising_edge(clk)) then
      tsync   <= '0';
      toggle  <= not toggle;

      counter <= counter + 1;

    end if;
  end process;
end;
