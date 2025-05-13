library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity ADC_CLK_DIV is
  port (
    ACLK    : in std_logic;
    CLK_DIV : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    ARESETN : in std_logic;

    ADC_CLK : out std_logic
  );
end entity ADC_CLK_DIV;

architecture behavioral of ADC_CLK_DIV is
  signal clk     : std_logic;
  signal clk_o   : std_logic;
  signal cnt     : integer;
  signal rst     : std_logic;
  signal limit   : integer;

begin
  clk     <= ACLK;
  rst     <= not ARESETN;
  limit   <= to_integer(unsigned(CLK_DIV));
  ADC_CLK <= clk_o;

  process(clk,rst)
  begin
    if (rst = '1' or limit = 0) then
      cnt     <= 1;
      clk_o   <= clk;
    else
      if (rising_edge(clk) or falling_edge(clk)) then
        if (cnt >= limit) then
          cnt     <= 1;
          clk_o   <= not clk_o;
        else
          cnt <= cnt +1;
        end if;
      end if;
    end if;
  end process;
end behavioral;
        
