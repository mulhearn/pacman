library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- heartbeat:  presents a periodic heartbeat on channel CHANNEL to the RX buffer

entity heartbeat is
  port (
    CLK_I         : in  std_logic;
    RST_I         : in  std_logic;
    EN_I          : in  std_logic;
    CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    TIMESTAMP_O   : out  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    VALID_O       : out std_logic;
    READY_I       : in  std_logic;
    TIMESTAMP_I   : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
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
  clk <= CLK_I;
  rst <= RST_I;

  VALID_O <= valid;
  ready <= READY_I;

  process(clk,rst)
  begin
    if (rst='1') then
      count <= 0;
      valid <= '0';
      TIMESTAMP_O <= (others => '0');
    elsif (rising_edge(clk)) then
      if ((valid='1') and (ready='1')) then
        TIMESTAMP_O <= (others => '0');
        valid <= '0';
      end if;
      if ((EN_I='1') and ((count+1) >= unsigned(CONFIG_I))) then
        if ((valid='0') or ((valid='1') and (ready='1'))) then
          valid <= '1';
          count <= 0;
          TIMESTAMP_O <= TIMESTAMP_I;
        end if;
      else
        count <= count + 1;
      end if;
    end if;
  end process;

end;
