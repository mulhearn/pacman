library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity rx_buffer is
  port (
-- Do not use _I/_O on ports autorecognized as interfaces by Vivado.    
    ACLK	: in std_logic;
    ARESETN 	: in std_logic;
    CONFIG_I      : in std_logic_vector(C_RX_BUFFER_CONFIG_WIDTH-1 downto 0);    
    DATA_O        : out std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0);      
    VALID_O       : out std_logic;
    LOST_O        : out std_logic;
    ACK_I         : in  std_logic;
    RX_I          : in  std_logic;
    TIMESTAMP_I   : in  std_logic_vector(31 downto 0);
    CHANNEL_I     : in  std_logic_vector(7 downto 0);
    HEADER_I      : in  std_logic_vector(7 downto 0);
    --
    MON_BUSY_O    : out std_logic;
    DEBUG_O       : out std_logic_vector(15 downto 0)
  );
end;

architecture behavioral of rx_buffer is
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

  signal clk       : std_logic;
  signal rst       : std_logic;

  signal rx     : std_logic:='0';
  signal valid   : std_logic:='0';
  signal lost    : std_logic:='0';
  signal ack     : std_logic;

  signal data_rx   : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);      
  signal update    : std_logic;
  signal busy      : std_logic;
begin
  urx: uart_rx port map (
    CLK => aclk,
    RST => rst,
    CLKIN_RATIO => CONFIG_I(7 downto 0),
    CLKIN_PHASE => CONFIG_I(11 downto 8),
    RX   => rx,
    data        => data_rx,
    data_update => update,
    busy        => busy
  );

  
  clk  <= ACLK;
  rst  <= not ARESETN;
  rx <= RX_I;
  VALID_O <= valid;
  LOST_O <= lost;
  ack <= ACK_I;
  MON_BUSY_O <= busy;
  DEBUG_O(0) <= update;
  DEBUG_O(1) <= busy;
  DEBUG_O(2) <= rx;
  
  process(clk)
    variable send_lost : std_logic := '0';
  begin
    if (rst='1') then
      DATA_O <= (others => '0');
      valid <= '0';
      lost <= '0';
    elsif (rising_edge(clk)) then
      send_lost := '0';
      
      if (update='1') then
        DATA_O(C_RX_CHAN_DATA_WIDTH-1 downto C_RX_CHAN_DATA_WIDTH-C_UART_DATA_WIDTH) <= data_rx;
        DATA_O(47 downto 16) <= TIMESTAMP_I;
        DATA_O(15 downto 8) <= CHANNEL_I;
        DATA_O(7 downto 0)  <= HEADER_I;
        if (valid='0') then
          valid <= '1';
        elsif (ack='0') then -- (handles just in time ack)
          send_lost := '1';
        end if;
      elsif (ack='1') then
        valid <= '0';
      end if;

      -- handle send_lost
      if (send_lost='1') then
        lost <= '1';
      else
        lost <= '0';
      end if;               

    end if;
  end process;
end;  

