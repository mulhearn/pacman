library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity timing_unit is
  port (
    ACLK                 : in std_logic;
    ARESETN              : in std_logic;
    UCLK_I               : in  std_logic;    
    
    S_REGBUS_RB_RADDR	 : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	 : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RUPDATE  : in  std_logic;
    S_REGBUS_RB_RACK     : out std_logic;
    
    S_REGBUS_RB_WUPDATE  : in  std_logic;
    S_REGBUS_RB_WADDR	 : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	 : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK     : out std_logic;
    
    GLB_CLK_O            : out std_logic;
    TRIG_O               : out std_logic_vector(C_NUM_TILE-1 downto 0);
    SYNC_O               : out std_logic_vector(C_NUM_TILE-1 downto 0)
  );
end timing_unit;

architecture behaviour of timing_unit is
  component timing_registers is
    port (
      ACLK	             : in std_logic;
      ARESETN	             : in std_logic;

      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;

      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      TRIG_UPDATE_O          : out std_logic;
      TRIG_CONFIG_O          : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      TRIG_BUSY_I            : in std_logic;

      SYNC_UPDATE_O          : out std_logic;
      SYNC_CONFIG_O          : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SYNC_BUSY_I            : in std_logic
      );
  end component;

  component slow_broadcast is
    generic (
      constant C_BROADCAST_WIDTH : integer := C_NUM_TILE;
      constant C_CONFIG_WIDTH : integer := C_RB_DATA_WIDTH
    );
    port (
      -- Clock Domain A: (Fast Clock)
      CLK_A_I	        : in  std_logic;
      RST_A_I	        : in  std_logic;
      UPDATE_A_I	        : in  std_logic;
      CONFIG_A_I          : in  std_logic_vector(C_CONFIG_WIDTH-1 downto 0);
      BUSY_A_O	        : out std_logic;

      -- Clock Domain B: (Slow Clock)
      CLK_B_I             : in  std_logic;
      BROADCAST_B_O          : out std_logic_vector(C_BROADCAST_WIDTH-1 downto 0);

      DEBUG_O             : out std_logic_vector(7 downto 0)
    );
  end component;
  
  signal rst            : std_logic;
  signal trig_update    : std_logic;
  signal trig_config    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal trig_busy      : std_logic;
  signal sync_update    : std_logic;
  signal sync_config    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal sync_busy      : std_logic;

begin
  uut0: timing_registers port map (
    ACLK                => ACLK,   
    ARESETN             => ARESETN,
    S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,  
    S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,   
    S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,   
    S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,    
    S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE, 
    S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,   
    S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,   
    S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,
    TRIG_UPDATE_O       => trig_update,
    TRIG_CONFIG_O       => trig_config,
    TRIG_BUSY_I         => trig_busy,
    SYNC_UPDATE_O       => sync_update,
    SYNC_CONFIG_O       => sync_config,
    SYNC_BUSY_I         => sync_busy
  );

  trig0: slow_broadcast port map (
    CLK_A_I  => ACLK,
    RST_A_I  => rst,
    UPDATE_A_I => trig_update,
    CONFIG_A_I => trig_config,
    BUSY_A_O => trig_busy,
    CLK_B_I => UCLK_I,
    BROADCAST_B_O => TRIG_O
  );

  sync0: slow_broadcast port map (
    CLK_A_I  => ACLK,
    RST_A_I  => rst,
    UPDATE_A_I => sync_update,
    CONFIG_A_I => sync_config,
    BUSY_A_O => sync_busy,
    CLK_B_I => UCLK_I,
    BROADCAST_B_O => SYNC_O
  );

  rst <= not ARESETN;
  GLB_CLK_O <= UCLK_I;
  
end behaviour;
        
