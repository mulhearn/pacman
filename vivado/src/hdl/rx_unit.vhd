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
      CYCLES_I               : in  uart_reg_array_t;
      BUSYS_I                : in  uart_reg_array_t;
      ACKS_I                 : in  uart_reg_array_t;
      LOSTS_I                : in  uart_reg_array_t;

      
      CONFIG_O               : out uart_reg_array_t;
      LOOK_I                 : in  uart_rx_data_array_t;
      COMMAND_O              : out uart_command_array_t      
    );  
  end component;

    component rx_chan is
    port (
      ACLK        : in std_logic;
      ARESETN     : in std_logic;
      CONFIG_I    : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      COMMAND_I   : in  std_logic_vector(C_COMMAND_WIDTH-1 downto 0);
      STATUS_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CYCLES_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      BUSYS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ACKS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LOSTS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    
      LOOK_O      : out std_logic_vector(C_RX_CHAN_DATA_WIDTH-1 downto 0);        
      RX_I        : in  std_logic;
      DEBUG_O     : out  std_logic_vector(15 downto 0)
    );  
  end component;
  
  signal clk      : std_logic;
  signal rst      : std_logic;

  -- tx registers
  signal status  : uart_reg_array_t := (others => x"FFFFFFFF");
  signal cycles  : uart_reg_array_t;
  signal busys   : uart_reg_array_t;
  signal acks    : uart_reg_array_t;
  signal losts   : uart_reg_array_t;
  
  signal config  : uart_reg_array_t;

  signal command    : uart_command_array_t;

  -- rx data
  signal look    : uart_rx_data_array_t := (others => x"DDDDDDDDCCCCCCCCBBBBBBBBAAAAAAAA");
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
    CYCLES_I            => cycles,
    BUSYS_I             => busys,
    ACKS_I              => acks,
    LOSTS_I             => losts,   

    LOOK_I              => look,
    COMMAND_O           => command
  );

  clk <= ACLK;
  rst <= not ARESETN;  

  grxchan0: for i in 0 to 39 generate
    rxchan0: rx_chan port map (
      ACLK       => aclk,
      ARESETN    => aresetn,
      CONFIG_I   => config(i),
      COMMAND_I  => command(i),
      STATUS_O   => status(i),
      CYCLES_O   => cycles(i),
      BUSYS_O    => busys(i),
      ACKS_O     => acks(i),
      LOSTS_O    => losts(i),
      LOOK_O    => look(i),
      RX_I       => PISO_I(i)
    );
  end generate grxchan0;
    
  DEBUG_O <= (others => '0');
end;  
