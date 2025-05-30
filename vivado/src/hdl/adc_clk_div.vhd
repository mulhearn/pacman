library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_clk_div is
  port (
    ACLK           : in  std_logic;
    ARESETN        : in  std_logic;
    CLKPAR_I       : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    
    ADC_CLK_O      : out std_logic
    );
end entity adc_clk_div;

architecture behavioral of adc_clk_div is
  signal clk_i  : std_logic;
  signal rst    : std_logic;
  signal pass   : std_logic := '1';
  
  --signal clk_o  : std_logic := '0';
  signal clk_d  : std_logic := '0';
  
begin
  clk_i       <= ACLK;
  rst         <= not ARESETN;
  ADC_CLK_O   <= clk_i when (pass = '1') else
                 clk_d;
  
  process(clk_i,rst)
    variable div : integer := 0;
    variable cnt : integer := 0;
  begin
    if (rst = '1') then
      clk_d <= '0';
      pass  <= '0';
      cnt   := 1;
    else
      if (rising_edge(clk_i)) then
        div := to_integer(unsigned(CLKPAR_I));
        if (div = 0 or div = 1) then
          pass <= '1';
          clk_d <= '0';
        else
          pass <= '0';
          if (clk_d = '1') then
            clk_d   <= '0';
            cnt     := cnt +1;
          else
            if (cnt >= div) then
              clk_d <= '1';
              cnt   := 1 ;
            else
              cnt   := cnt + 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
end behavioral;
  

  
