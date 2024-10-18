library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity rollover is
  generic (
    constant CHANNEL   : integer := 16#53#;  -- ASCII S
    constant HEADER    : integer := 16#53#   -- ASCII S
  );
  port (
    ACLK          : in  std_logic;
    ARESETN       : in  std_logic;
    EN_I          : in  std_logic;
    CYCLES_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DATA_O        : out  std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);
    VALID_O       : out  std_logic;
    READY_I       : in std_logic;
    TIMESTAMP_I   : in  std_logic_vector(31 downto 0);
    DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
end;

architecture behavioral of rollover is
  signal clk        : std_logic;
  signal rst        : std_logic;

  signal valid      : std_logic;
  signal ready      : std_logic;

begin
  clk <= ACLK;
  rst   <= not ARESETN;

  VALID_O <= valid;
  ready <= READY_I;

  process(clk,rst)
    variable sent  : std_logic := '0';
  begin
    if (rst='1') then
      sent := '0';
      valid <= '0';
      DATA_O <= (others => '0');
    elsif (rising_edge(clk)) then
      if ((valid='1') and (ready='1')) then
        valid <= '0';
      end if;

      if (not (unsigned(TIMESTAMP_I) = unsigned(CYCLES_I))) then
        sent := '0';
      elsif ((EN_I='1') and (sent='0')) then
        if ((valid='0') or ((valid='1') and (ready='1'))) then
          valid <= '1';
          sent := '1';
          DATA_O <= (others => '0');
          DATA_O(63 downto 32) <= TIMESTAMP_I;
          DATA_O(15 downto 8) <= std_logic_vector(to_unsigned(CHANNEL, C_BYTE));
          DATA_O(7 downto 0)  <= std_logic_vector(to_unsigned(HEADER, C_BYTE));
        end if;
      end if;
    end if;
  end process;

end;
