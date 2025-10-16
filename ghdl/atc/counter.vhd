library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity counter is

  port (
    --clock and active high reset:
    CLK_I       : in  std_logic;
    RST_I       : in  std_logic;

    -- increment the count
    INCREMENT_I : in  std_logic;
    -- count runs only while run is high
    RUN_I       : in  std_logic;
    -- count resets to zero on clear
    CLEAR_I     : in  std_logic;
    -- current count
    COUNT_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
end;

architecture behavioral of counter is
signal clk              : std_logic;
signal rst              : std_logic;
signal running          : std_logic;
signal update_in        : std_logic;
signal update_z         : std_logic := '0';
constant COUNT_MAX      : unsigned(31 downto 0) := to_unsigned(100000000 - 1, C_RB_DATA_WIDTH);
begin

clk            <= CLK_I;
rst            <= RST_I;
update_in      <= INCREMENT_I;

process(clk, rst)
  variable count : unsigned(31 downto 0) := (others => '0');
begin
  if rst = '1' then
    update_z    <= '0';
    count       := (others => '0');
    COUNT_O <= std_logic_vector(count);
  elsif rising_edge(clk) then
    update_z <= update_in;

    if  CLEAR_I  = '1' then
      count := (others => '0');
    elsif (RUN_I = '1') and (update_in = '1' and update_z = '0') then
      if count < COUNT_MAX then
        count := count + 1;
      end if;
    end if;
    COUNT_O <= std_logic_vector(count);
  end if;
end process;





end;
