library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity rx_unit is
  port (
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK    : out  std_logic;
    
    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out  std_logic;

    LOOPBACK_I            : in std_logic_vector(C_NUM_UART-1 downto 0);
    PISO_I                : in std_logic_vector(C_NUM_UART-1 downto 0);
    --
    DEBUG_O               : out  std_logic_vector(31 downto 0)
    );
end;

architecture behavioral of rx_unit is
  component rx_registers is
    port (
      ACLK	        : in std_logic;
      ARESETN	        : in std_logic;
      
      S_REGBUS_RB_RADDR	     : in  std_logic_vector(15 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(31 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;
      
      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(15 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(31 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;
      
      STATUS_I               : in  uart_reg_array_t;
      CONFIG_O               : out uart_reg_array_t;
      LOST_I                 : in  uart_reg_array_t;
      LOOK_I                 : in  uart_rx_data_array_t;
      COMMAND_O              : out uart_command_array_t      
    );  
  end component;
    
  signal clk      : std_logic;
  signal rst      : std_logic;

  -- tx registers
  signal status  : uart_reg_array_t := (others => x"FFFFFFFF");
  signal config  : uart_reg_array_t;
  signal lost    : uart_reg_array_t;
  signal send    : uart_command_array_t;

  -- rx data
  signal data    : uart_rx_data_array_t := (others => x"DDDDDDDDCCCCCCCCBBBBBBBBAAAAAAAA");
  signal valid     : std_logic_vector(C_NUM_UART-1 downto 0);
  signal ack       : std_logic_vector(C_NUM_UART-1 downto 0);
  signal mon_busy  : std_logic_vector(C_NUM_UART-1 downto 0);    
  
begin
  reg0: rx_registers port map (
    ACLK           => ACLK,
    ARESETN        => ARESETN,
    S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
    S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
    S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
    S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
    S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
    S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
    S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
    S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,
    STATUS_I            => status,
    CONFIG_O            => config,
    LOST_I              => lost,
    LOOK_I              => data,
    COMMAND_O           => send
  );
  
  DEBUG_O(0) <= valid(0);
  DEBUG_O(1) <= mon_busy(0);
  DEBUG_O(3) <= '1';
  DEBUG_O(7 downto 4) <= send(0)(3 downto 0);
  clk <= ACLK;
  rst <= not ARESETN;
end;  
