library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- rx_header: output an RX header for the selected channel based on configurable parameters
--            
-- Note: the word type field is set to zero for data words, so that it may be
-- determined elsewhere form the ASIC data.

entity rx_header is
  port (
    -- clock and active-high reset:
    CLK_I      : in std_logic;
    RST_I      : in std_logic;

    -- channel selection for header output:
    SEL_I      : in  std_logic_vector(C_SELECT_WIDTH-1 downto 0);

    -- headers for rollover and heartbeat sync messages:
    HEADER_A_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    HEADER_B_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    HEADER_C_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    HEADER_D_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    
    -- configurable PACMAN id:
    PACMAN_I           : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    
    -- UART channel array (configurable):
    CHAN_I             : in uart_small_array_t;

    -- outgoing (modified) headers:
    HEADER_O           : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
  );
end;

architecture behavioral of rx_header is
  signal clk       : std_logic;
  signal rst       : std_logic;
  signal header    : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);  
begin

  clk <= CLK_I;
  rst <= RST_I;

  process(rst, SEL_I, HEADER_A_I, HEADER_B_I, HEADER_C_I, HEADER_D_I, PACMAN_I, CHAN_I)
    variable chan       : integer;
  begin
    if (rst='1') then
      header <= (others => '0');
    else
      header <= (others => '0');
      chan := to_integer(unsigned(SEL_I));
      if    (chan = C_NUM_UART+0) then
        header(C_RB_DATA_WIDTH-1 downto 0) <= HEADER_A_I;
      elsif (chan = C_NUM_UART+1) then
        header(C_RB_DATA_WIDTH-1 downto 0) <= HEADER_B_I;
      elsif (chan = C_NUM_UART+2) then
        header(C_RB_DATA_WIDTH-1 downto 0) <= HEADER_C_I;
      elsif (chan = C_NUM_UART+3) then
        header(C_RB_DATA_WIDTH-1 downto 0) <= HEADER_D_I;
      elsif (chan > C_NUM_UART+3) then
        header(C_RB_DATA_WIDTH-1 downto 0) <= (others => '0');
      else
        header (7 downto 0)   <= (others => '0');
        header (15 downto 8)  <= PACMAN_I(7 downto 0);
        header (31 downto 16) <= CHAN_I(chan);
      end if;
    end if;
  end process;
  
  process(clk, rst)
  begin
    if rst = '1' then
      HEADER_O <= (others => '0');
    elsif rising_edge(clk) then
      HEADER_O <= header;
    end if;
  end process;

  
end;
