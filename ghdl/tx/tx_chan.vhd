library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity tx_chan is
  port (
    ACLK          : in  std_logic;
    ARESETN       : in  std_logic;
    UCLK_I        : in  std_logic;    
    CONFIG_I      : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    
    GFLAGS_I      : in  std_logic_vector(C_TX_GFLAGS_WIDTH-1 downto 0);
    DATA_I        : in  std_logic_vector(C_TX_DATA_WIDTH-1 downto 0);
    VALID_I       : in  std_logic;
    READY_O       : out std_logic;
    TX_O          : out std_logic;
    --
    DEBUG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
end;

architecture behavioral of tx_chan is
  component uart_tx is
    port (
      CLK          : IN  STD_LOGIC;
      RST          : IN  STD_LOGIC;
      CLKOUT_RATIO : IN  STD_LOGIC_VECTOR (7 downto 0);
      CLKOUT_PHASE : IN  STD_LOGIC_VECTOR (3 downto 0);    
      -- UART TX
      MCLK        : IN  STD_LOGIC;
      TX          : OUT STD_LOGIC;
      -- received data
      DATA        : IN  STD_LOGIC_VECTOR (C_UART_DATA_WIDTH-1 DOWNTO 0);
      DATA_UPDATE : IN  STD_LOGIC; -- must be held high until busy goes high
      BUSY        : OUT STD_LOGIC
    );
  end component uart_tx;
  
  signal clk         : std_logic;
  signal rst         : std_logic;

  signal status      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal status_z    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  
  signal valid       : std_logic;
  signal ready       : std_logic;
  signal busy        : std_logic;
  signal busy_z      : std_logic;
  signal start       : std_logic;

  signal tx          : std_logic;
  
  -- STATES:
  signal txoff       : std_logic;  -- valid=0 into all TXs
  signal hrdy        : std_logic;  -- ready=1 from all TXs
  signal mode        : integer range 0 to 3;
  
begin
  uart0: uart_tx port map(
    CLK=>clk,
    RST=>rst,
    CLKOUT_RATIO=>CONFIG_I(7 downto 0),
    CLKOUT_PHASE=>CONFIG_I(11 downto 8),
    MCLK=>UCLK_I,
    TX=>tx,
    DATA=>DATA_I,
    DATA_UPDATE=>valid,
    BUSY=>busy
  );

  clk <= ACLK;
  rst   <= not ARESETN;
  
  STATUS_O <= status_z;
  READY_O  <= ready;
  TX_O     <= tx;

  txoff    <= GFLAGS_I(0);
  hrdy     <= GFLAGS_I(1);

  mode <= to_integer(unsigned(CONFIG_I(13 downto 12)));
  
  process(clk,rst)
  begin
    if (rst='1') then
      valid <= '0';
    elsif (rising_edge(clk)) then
      if ((txoff='1') or (mode=0)) then
        valid <= '0';
      else
        valid <= VALID_I;
      end if;
    end if;
  end process;

  process(clk,rst)
  begin
    if (rst='1') then
      ready <= '0';
      busy_z <= '0';
    elsif (rising_edge(clk)) then
      busy_z <= busy;
      if ((hrdy='1') or (mode=0)) then
        ready <= '1';
      elsif (mode=1) then
        if (valid='1' and busy='1' and busy_z='0') then
          ready <= '1';
        else
          ready <= '0';
        end if;
      elsif (mode=2) then
        ready <= '0';
      end if;
    end if;
  end process;

  
  -- provide non-delayed status for convenient debugging
  DEBUG_O  <= status;
  
  status(0) <= busy;
  status(1) <= VALID_I;
  status(2) <= ready;
  status(3) <= start;
  status(8) <= valid;
  
  process(clk,rst)
  begin
    if (rst='1') then
      status_z <= (others => '0');                  
    elsif (rising_edge(clk)) then
      status_z <= status;
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

