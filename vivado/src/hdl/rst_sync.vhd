library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

-- rst_sync.vhd
--
-- synchronize the deassertion of asynchronous reset, leaving assertion asynchronous.
--

entity rst_sync is
  port (
    --clock
    CLK_I  : in  std_logic;

    -- asynchronous reset in:
    RST_A  : in  std_logic;

    -- asynchronous assert, synchronous deassert reset out:
    RST_O  : out  std_logic
  );
end;

architecture behavioral of rst_sync is
  signal clk       : std_logic;
  signal rst       : std_logic;
  signal rst_sync1 : std_logic := '1';
  signal rst_sync2 : std_logic := '1';

  attribute ASYNC_REG : string;
  attribute SHREG_EXTRACT  : string;
  attribute ASYNC_REG of rst_sync1: signal is "TRUE";
  attribute ASYNC_REG of rst_sync2: signal is "TRUE";
  attribute SHREG_EXTRACT of rst_sync1 : signal is "NO";
  attribute SHREG_EXTRACT of rst_sync2 : signal is "NO";

begin
  clk <= CLK_I;
  rst <= RST_A;
  RST_O <= rst_sync2;

  rst_process : process (rst, clk)
  begin
    if (rst = '1') then
      rst_sync1 <= '1';
      rst_sync2 <= '1';
    elsif rising_edge(clk) then
      rst_sync1 <= '0';
      rst_sync2 <= rst_sync1;
    end if;
  end process;

end;
