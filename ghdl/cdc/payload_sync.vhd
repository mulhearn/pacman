library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

-- payload_sync.vhd
--
-- Synchronizes a payload from a different clock domain.  The output
-- is only updated when busy is low.
--

entity payload_sync is
  generic ( PAYLOAD_WIDTH : integer := C_RB_DATA_WIDTH );

  port (
    -- clock and active-high reset for slow clock domain:
    CLK_I       : in  std_logic;
    RST_I	: in  std_logic;
    BUSY_I	: in  std_logic;

    -- The synchronized update signal (poke) and it's associated payload.
    PAYLOAD_O   : out std_logic_vector(PAYLOAD_WIDTH-1 downto 0);

    -- payload from the producing domain, assumed stable when
    PAYLOAD_A   : in  std_logic_vector(PAYLOAD_WIDTH-1 downto 0) -- A: asynchronous (CDC) input
  );
end;

architecture behavioral of payload_sync is
  signal clk          : std_logic;
  signal rst          : std_logic;
  signal update_comb  : std_logic;
  signal update       : std_logic;
  signal payload      : std_logic_vector(PAYLOAD_WIDTH-1 downto 0);
  signal payload_reg : std_logic_vector(PAYLOAD_WIDTH-1 downto 0);
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of payload_reg: signal is "TRUE";


begin
  clk <= CLK_I;
  rst <= RST_I;

  payload0: process(clk, rst)
  begin
    if (rst = '1') then
      payload_reg <= (others => '0');
    elsif (rising_edge(clk)) then
      if (BUSY_I = '0') then
        payload_reg <= PAYLOAD_A;
      else
        payload_reg <= payload_reg;
      end if;
    end if;
  end process;

  PAYLOAD_O <= payload_reg;


end;
