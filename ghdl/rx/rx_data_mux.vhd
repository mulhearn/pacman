library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- rx_data_mux:

entity rx_data_mux is
  port (
    -- clock and active-high reset:
    CLK_I      : in std_logic;
    RST_I      : in std_logic;

    -- channel selection for A and B outputs:
    SEL_A_I    : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);
    SEL_B_I    : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);

    -- incoming data:
    DATA_I     : in  uart_data_array_t;

    -- selected A and B outputs:
    DATA_A_O   : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
    DATA_B_O   : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);

    -- ASIC word type LUT:
    LUT_I       : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- word type for A output:
    WTYPE_A_O : out std_logic_vector(C_BYTE-1 downto 0)
  );
end;

architecture behavioral of rx_data_mux is
  signal clk       : std_logic;
  signal rst       : std_logic;

  signal data_a    : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
  signal data_b    : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);

  type lut_t is array(0 to 3) of std_logic_vector(7 downto 0);
  signal lut       : lut_t;
  signal wtype_a   : std_logic_vector(C_BYTE-1 downto 0);

begin
  clk <= CLK_I;
  rst <= RST_I;

  lut(0) <= LUT_I(7  downto 0);
  lut(1) <= LUT_I(15 downto 8);
  lut(2) <= LUT_I(23 downto 16);
  lut(3) <= LUT_I(31 downto 24);

  --data_b <= (others => '0') when to_integer(unsigned(SEL_B_I)) >= 40
  --          else DATA_I(to_integer(unsigned(SEL_B_I)));

  process (rst, SEL_B_I, DATA_I)
    variable chan     : integer;
    variable data     : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
  begin
    if (rst='1') then
      data   := (others => '0');
    else
      data   := (others => '0');
      chan   := to_integer(unsigned(SEL_B_I));

      if (chan < 40) then
        data   := DATA_I(chan);
      end if;
    end if;
    data_b  <= data;
  end process;

  process (rst, SEL_A_I, DATA_I, lut)
    variable chan     : integer;
    variable data     : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
    variable wtype    : std_logic_vector(C_BYTE-1 downto 0);
  begin
    if (rst='1') then
      data   := (others => '0');
      wtype  := (others => '0');
    else
      data   := (others => '0');
      wtype  := (others => '0');
      chan   := to_integer(unsigned(SEL_A_I));

      if (chan < 40) then
        data   := DATA_I(chan);
        wtype  := lut(to_integer(unsigned(data(1 downto 0))));
      end if;
    end if;
    data_a  <= data;
    wtype_a <= wtype;
  end process;

  process(clk, rst)
  begin
    if rst = '1' then
      DATA_A_O  <= (others => '0');
      DATA_B_O  <= (others => '0');
      WTYPE_A_O <= (others => '0');
    elsif rising_edge(clk) then
      DATA_A_O  <= data_a;
      DATA_B_O  <= data_b;
      WTYPE_A_O <= wtype_a;
    end if;
  end process;



end;
