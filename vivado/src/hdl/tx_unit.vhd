library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity tx_unit is
  port (
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;
    UCLK_I	        : in std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK    : out  std_logic;
    
    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out  std_logic;

    POSI_O                : out std_logic_vector(C_NUM_UART-1 downto 0);
    --
    DEBUG_O               : out  std_logic_vector(31 downto 0)
    );
end;

architecture behavioral of tx_unit is
  component tx_chan is
    port (
      ACLK        : in std_logic;
      ARESETN     : in std_logic;
      UCLK_I      : in std_logic;
      CONFIG_I    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      COMMAND_I   : in  std_logic_vector(C_COMMAND_WIDTH-1 downto 0);
      STATUS_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    
      LOOK_O      : out std_logic_vector(C_TX_CHAN_DATA_WIDTH-1 downto 0);        
      SEND_I      : in std_logic_vector(C_TX_CHAN_DATA_WIDTH-1 downto 0);
      TX_O        : out std_logic;
      DEBUG_O     : out  std_logic_vector(15 downto 0)
    );
  end component;
  
  component tx_registers is
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

      STATUS_I            : in uart_reg_array_t;
      CONFIG_O            : out uart_reg_array_t;
      SEND_O              : out uart_tx_data_array_t;
      LOOK_I              : in uart_tx_data_array_t;
      COMMAND_O           : out uart_command_array_t
      );
  end component;
  signal clk       : std_logic;
  signal rst       : std_logic;

  -- tx registers
  signal status    : uart_reg_array_t := (others => x"FFFFFFFF");
  signal config    : uart_reg_array_t;
  signal send      : uart_tx_data_array_t;
  signal cmd       : uart_command_array_t;
  signal start     : std_logic_vector(C_NUM_UART-1 downto 0) := (others => '0');

  signal look      : uart_tx_data_array_t;

  
begin
  reg0: tx_registers port map (
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
    STATUS_I              => status,
    CONFIG_O              => config,
    SEND_O                => send,
    LOOK_I                => look,
    COMMAND_O             => cmd
    );

  gtxchan0: for i in 0 to 39 generate
    txchan0: tx_chan
      port map(
        ACLK       => ACLK,      
        ARESETN    => ARESETN,   
        UCLK_I     => UCLK_I,    
        CONFIG_I   => config(i),
        COMMAND_I  => cmd(i),   
        STATUS_O   => status(i),   
        LOOK_O     => look(i),      
        SEND_I     => send(i),    
        TX_O       => POSI_O(i) 
      );
  end generate gtxchan0;
  
  clk <= ACLK;
  rst <= not ARESETN;
  DEBUG_O <= (others => '0');
end;  

