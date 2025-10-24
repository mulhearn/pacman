library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- rx_chan:  single UART RX channel
--
-- this is a wrapper for the (known to work) uart_rx which is
-- preserved from the legacy firmware.  I plan to update the uart_rx
-- once I have solid ASIC testing regimen, so comments are limited for
-- this version.


entity rx_chan is

  port (
    --clock and active-high reset
    CLK_I          : in  std_logic;
    RST_I       : in  std_logic;

    CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DATA_O        : out  std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
    TIMESTAMP_O   : out  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    VALID_O       : out  std_logic;
    READY_I       : in std_logic;
    RX_I          : in std_logic;
    LOOPBACK_I    : in std_logic;
    TIMESTAMP_I   : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
end;

architecture behavioral of rx_chan is
  component uart_rx is
   port (
      CLK         : in   std_logic;
      RST         : in   std_logic;
      CLKIN_RATIO : in   std_logic_vector (7 downto 0);
      CLKIN_PHASE : in   std_logic_vector (3 downto 0);
      RX          : in   std_logic;
      DATA        : out  std_logic_vector (C_UART_DATA_WIDTH-1 DOWNTO 0);
      DATA_UPDATE : out  std_logic;
      BUSY        : out  std_logic
    );
  end component;

  signal clk        : std_logic;
  signal rst        : std_logic := '1';

  signal status     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal status_z   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal udata       : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0) := (others => '0');
  signal valid      : std_logic;
  signal ready      : std_logic;

  signal rx         : std_logic:='0';

  signal update     : std_logic;
  signal busy       : std_logic;
  signal busy_z     : std_logic;

  signal start      : std_logic:='0';
  signal lost       : std_logic:='0';
begin
  urx: uart_rx port map (
    CLK => clk,
    RST => rst,
    CLKIN_RATIO => CONFIG_I(7 downto 0),
    CLKIN_PHASE => CONFIG_I(11 downto 8),
    RX          => rx,
    data        => udata,
    data_update => update,
    busy        => busy
  );

  clk <= CLK_I;
  rst <= RST_I;

  VALID_O <= valid;
  ready <= READY_I;

  with CONFIG_I(17 downto 16) select
    rx <= RX_I when "00",
    LOOPBACK_I when "01",
    '0' when "10",
    '1' when others;

  process(clk,rst)
    variable mode : integer range 0 to 3 := 0;

  begin
    if (rst='1') then
      DATA_O <= (others => '0');
      TIMESTAMP_O <= (others => '0');
      valid  <= '0';
      lost   <= '0';
      mode := 0;
    elsif (rising_edge(clk)) then
      lost   <= '0';
      mode := to_integer(unsigned(CONFIG_I(13 downto 12)));
      if (mode = 1) then
        if (update = '1') then
          DATA_O <= udata;
          TIMESTAMP_O <= TIMESTAMP_I;
          if ((valid = '1') and (ready='0')) then
            lost <= '1';
          else
            valid <= '1';
          end if;
        elsif (ready='1') then
          valid <= '0';
          -- we hold DATA_O and TIMESTAMP_O until valid data replaces it, so
          -- that most recent RX is available in the LOOK register
        end if;
      else
        DATA_O <= (others => '0');
        TIMESTAMP_O <= (others => '0');
        valid  <= '0';
      end if;
    end if;
  end process;

  -- provide non-delayed status for convenient debugging
  DEBUG_O  <= status;
  -- status is registered:
  STATUS_O <= status_z;

  status(0) <= busy;
  status(1) <= valid;
  status(2) <= ready;

  status(4) <= start;
  status(5) <= update;
  status(6) <= lost;

  status(8) <= rx;

  process(clk,rst)
  begin
    if (rst='1') then
      status_z <= (others => '0');
      busy_z <= '0';
    elsif (rising_edge(clk)) then
      status_z <= status;
      busy_z <= busy;
    end if;
  end process;

  process(clk,rst)
  begin
    if (rst='1') then
      start <= '0';
    elsif (rising_edge(clk)) then
      if (busy_z='0') and (busy='1') then
        start <= '1';
      else
        start <= '0';
      end if;
    end if;
  end process;
end;
