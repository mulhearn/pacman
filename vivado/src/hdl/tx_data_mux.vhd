library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- tx_data_mux:

entity tx_data_mux is
  port (
    -- clock and active-high reset:
    CLK_I      : in std_logic;
    RST_I      : in std_logic;

    -- channel selection for outputs:
    SEL_I    : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);

    -- incoming data:
    DATA_I     : in  uart_data_array_t;

    -- selected output:
    DATA_O     : out std_logic_vector(C_UART_DATA_WIDTH-1 downto 0)
  );
end;

architecture behavioral of tx_data_mux is
  signal clk       : std_logic;
  signal rst       : std_logic;

  signal data_next : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);

begin
  clk <= CLK_I;
  rst <= RST_I;

  process (rst, SEL_I, DATA_I)
    variable chan     : integer;
    variable data     : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
  begin
    if (rst='1') then
      data   := (others => '0');
    else
      data   := (others => '0');
      chan   := to_integer(unsigned(SEL_I));

      if (chan < 40) then
        data   := DATA_I(chan);
      end if;
    end if;
    data_next  <= data;
  end process;

  process(clk, rst)
  begin
    if rst = '1' then
      DATA_O  <= (others => '0');
    elsif rising_edge(clk) then
      DATA_O  <= data_next;
    end if;
  end process;



end;
