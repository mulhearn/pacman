library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

--timestamp

entity timestamp_slow is
  port (
    UCLK_I	        : in  std_logic;
    URST_I	        : in  std_logic;
    TIMESTAMP_O         : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0)
  );
end;

architecture behavioral of timestamp_slow is
  signal clk       : std_logic;
  signal rst       : std_logic;
  signal counter : unsigned(C_TIMESTAMP_WIDTH-1 downto 0) := (others => '0');
  
begin
  clk <= UCLK_I;
  rst <= URST_I;

  TIMESTAMP_O <= std_logic_vector(counter);
  
  -- clock domain B process
  process(clk, rst)
  begin
    if (rst='1') then
      counter <= (others => '0');
    elsif (rising_edge(clk)) then
      counter <= counter + 1;
    end if;
  end process;
end;
