library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;


-- Noticed at TB: Could save one clock cycle of ~660 :-) by pulling
-- txstart earlier (as soon as input buffer is valid and tx is
-- currently busy).  

entity tx_buffer is
  port (
-- Do not use _I/_O on ports autorecognized as interfaces by Vivado.
    ACLK	: in std_logic;
    ARESETN 	: in std_logic;
    UCLK_I	: in std_logic;
    CONFIG_I    : in std_logic_vector(C_TX_BUFFER_CONFIG_WIDTH-1 downto 0);
    
    DATA_I      : in std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);      
    VALID_I     : in std_logic;
    ACK_O       : out std_logic;
    TX_O          : out std_logic;
    --
    MON_BUSY_O    : out std_logic;
    DEBUG_O       : out std_logic_vector(15 downto 0)
  );
begin
  assert C_TX_BUFFER_CONFIG_WIDTH>=12;
end;

architecture behavioral of tx_buffer is
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

  signal clk       : std_logic;
  signal rst       : std_logic;
  
  signal valid     : std_logic;
  signal ack     : std_logic := '0';
  signal txstart      : std_logic := '0';
  signal busy      : std_logic;
begin
  uart0: uart_tx port map(
    CLK=>CLK,
    RST=>rst,
    CLKOUT_RATIO=>CONFIG_I(7 downto 0),
    CLKOUT_PHASE=>CONFIG_I(11 downto 8),
    MCLK=>UCLK_I,
    TX=>TX_O,
    DATA=>DATA_I,
    DATA_UPDATE=>txstart,
    BUSY=>busy
  );
  clk <= ACLK;
  rst <= not ARESETN;
  valid <= VALID_I;
  ACK_O <= ack;
  MON_BUSY_O <= busy;
  DEBUG_O(0) <= txstart;
  DEBUG_O(1) <= busy;
  
  -- input is buffered when valid input present and ack is sent: 
  process(clk)
  begin
    if (rst='1') then
      txstart <= '0';
      ack <= '0';
    elsif (rising_edge(clk)) then
      if ((valid_i='1') and (txstart='0') and (busy='0')) then
        txstart <= '1';
      elsif ((txstart='1') and (busy='1')) then
        txstart <= '0';
        ack <= '1';        
      end if;
      if (ack='1') then
        ack <= '0';
      end if;
    end if;
  end process;
  
end;  

