library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

--rollover:  presents a rollover on channel CHANNEL to the RX buffer.

entity rollover is
  port (
    --clock and active-high reset
    CLK_I         : in  std_logic;
    RST_I         : in  std_logic;

    EN_I          : in  std_logic;
    CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    TIMESTAMP_O   : out  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    VALID_O       : out  std_logic;
    READY_I       : in std_logic;
    TIMESTAMP_I   : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
end;

architecture behavioral of rollover is
  signal clk        : std_logic;
  signal rst        : std_logic;

  signal valid      : std_logic;
  signal ready      : std_logic;

begin
  clk <= CLK_I;
  rst <= RST_I;

  VALID_O <= valid;
  ready <= READY_I;

  process(clk,rst)
    variable sent  : std_logic := '0';
  begin
    if (rst='1') then
      sent := '0';
      valid <= '0';
      TIMESTAMP_O <= (others => '0');
    elsif (rising_edge(clk)) then
      if ((valid='1') and (ready='1')) then
        valid <= '0';
        TIMESTAMP_O <= (others => '0');
      end if;
      if (not (to_integer(unsigned(TIMESTAMP_I)) = to_integer(unsigned(CONFIG_I)))) then
        sent := '0';
      elsif ((EN_I='1') and (sent='0')) then
        if ((valid='0') or ((valid='1') and (ready='1'))) then
          valid <= '1';
          sent := '1';
          TIMESTAMP_O <= TIMESTAMP_I;
        end if;
      end if;
    end if;
  end process;

end;
