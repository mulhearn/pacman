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

  signal run_reg        : std_logic;
  signal increment_rega : std_logic;
  signal increment_regb : std_logic;
  signal clear_reg      : std_logic;

  signal count_next   : unsigned(C_COUNT_BITS-1 downto 0);
  signal count_rega   : unsigned(C_COUNT_BITS-1 downto 0);
  signal count_regb   : unsigned(C_COUNT_BITS-1 downto 0);

begin

  -- Register inputs
  process(CLK_I, RST_I)
  begin
    if RST_I = '1' then
      run_reg        <= '0';
      increment_rega <= '1';
      increment_regb <= '1';
      clear_reg      <= '0';
    elsif rising_edge(CLK_I) then
      run_reg        <= RUN_I;
      increment_rega <= INCREMENT_I;
      increment_regb <= increment_rega;
      clear_reg      <= CLEAR_I;
    end if;
  end process;

  -- Combinatorial next value
  process(run_reg, increment_rega, clear_reg, count_rega)
  begin
    if clear_reg = '1' then
      count_next <= (others => '0');
    elsif run_reg = '1' and increment_rega = '1' and increment_regb = '0' then
      if count_rega < C_COUNT_MAX then
        count_next <= count_rega + 1;
      else
        count_next <= count_rega;  -- saturate at max
      end if;
    else
      count_next <= count_rega;
    end if;
  end process;

  -- Two-stage registered outputs
  process(CLK_I, RST_I)
  begin
    if RST_I = '1' then
      count_rega <= (others => '0');
      count_regb <= (others => '0');
    elsif rising_edge(CLK_I) then
      count_rega <= count_next;
      count_regb <= count_rega;
    end if;
  end process;

  -- Output zero-extended to full bus width
  COUNT_O <= (C_RB_DATA_WIDTH-1 downto C_COUNT_BITS => '0') & std_logic_vector(count_regb);

end behavioral;


