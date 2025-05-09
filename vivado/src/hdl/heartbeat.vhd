library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity heartbeat is
  generic (
    constant CHANNEL   : integer := 16#48#;  -- ASCII H
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

architecture behavioral of heartbeat is
  signal clk        : std_logic;
  signal rst        : std_logic;

  signal valid      : std_logic;
  signal ready      : std_logic;

  signal count      : integer;

begin
  clk <= ACLK;
  rst   <= not ARESETN;

  VALID_O <= valid;
  ready <= READY_I;

  process(clk,rst)
  begin
    if (rst='1') then
      count <= 0;
      valid <= '0';
      DATA_O <= (others => '0');
    elsif (rising_edge(clk)) then
      if ((valid='1') and (ready='1')) then
        valid <= '0';
      end if;

      if ((EN_I='1') and ((count+1) >= unsigned(CYCLES_I))) then
        if ((valid='0') or ((valid='1') and (ready='1'))) then
          valid <= '1';
          count <= 0;
          DATA_O <= (others => '0');
          DATA_O(63 downto 32) <= TIMESTAMP_I;
          DATA_O(15 downto 8) <= std_logic_vector(to_unsigned(CHANNEL, C_BYTE));
          DATA_O(7 downto 0)  <= std_logic_vector(to_unsigned(HEADER, C_BYTE));
        end if;
      else
        count <= count + 1;
      end if;
    end if;
  end process;

end;
