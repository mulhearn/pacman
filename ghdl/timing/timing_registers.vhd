library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;

entity timing_registers is
  port (
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK    : out std_logic;
    
    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out std_logic;

    TRIG_UPDATE_O       : out std_logic;
    TRIG_CONFIG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    TRIG_BUSY_I         : in std_logic;

    SYNC_UPDATE_O       : out std_logic;
    SYNC_CONFIG_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    SYNC_BUSY_I         : in std_logic;

    STATUS_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    TIMESTAMP_I         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)    
    );
end;

architecture behavioral of timing_registers is
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal rdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal rack     : std_logic := '0';
  
  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal wdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal wack     : std_logic := '0';

  signal sync_cfg : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal trig_cfg : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  
begin
  -- Clock and reset inputs:
  clk <= ACLK;
  rst <= not ARESETN;
  
  --REGBUS read signals
  rupdate  <= S_REGBUS_RB_RUPDATE;
  raddr    <= S_REGBUS_RB_RADDR;
  S_REGBUS_RB_RDATA <= rdata;
  S_REGBUS_RB_RACK  <= rack;
  --REGBUS write signals
  wupdate  <= S_REGBUS_RB_WUPDATE;
  waddr    <= S_REGBUS_RB_WADDR;
  wdata    <= S_REGBUS_RB_WDATA;
  S_REGBUS_RB_WACK	 <= wack;

  TRIG_CONFIG_O <= trig_cfg;
  SYNC_CONFIG_O <= sync_cfg;
  
  -- Handle Read Request:
  process(clk, rst)
    variable scope   : integer range 0 to 16#F#;
    variable role    : integer range 0 to 16#F#;
    variable reg     : integer range 0 to 16#FF#;
  begin  
    if (rst = '1') then
      rack <= '0';
      rdata <= x"00000000";
    elsif (rising_edge(clk)) then
      rack <= '0';
      if (rupdate='1') then
        scope := to_integer(unsigned(raddr(15 downto 12)));
        role  := to_integer(unsigned(raddr(11 downto 8)));
        reg   := to_integer(unsigned(raddr(7 downto 0)));
        rdata <= x"00000000";
        if (scope=C_SCOPE_GLOBAL) and (role=C_ROLE_TIMING) then
          rdata <= x"EEEEEEEE";
          if (reg=C_ADDR_TIMING_STATUS) then
            rdata <= STATUS_I;
            rack  <= '1';
          elsif (reg=C_ADDR_TIMING_STAMP) then
            rdata <= TIMESTAMP_I;
            rack  <= '1';
          elsif (reg=C_ADDR_TIMING_TRIG) then
            rdata <= trig_cfg;
            rack  <= '1';
          elsif (reg=C_ADDR_TIMING_SYNC) then
            rdata <= sync_cfg;
            rack  <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
        
  -- Handle Write Request:
  process(clk, rst)
    variable scope   : integer range 0 to 16#F#;
    variable role    : integer range 0 to 16#F#;
    variable reg     : integer range 0 to 16#FF#;    
  begin  
    if (rst = '1') then
      wack  <= '0';
      trig_cfg <= (others => '0');
      sync_cfg <= (others => '0');
      TRIG_UPDATE_O <= '0';
      SYNC_UPDATE_O <= '0';
    elsif (rising_edge(clk)) then
      TRIG_UPDATE_O <= '0';
      SYNC_UPDATE_O <= '0';
      wack <= '0';      
      if (wupdate='1') then
        scope := to_integer(unsigned(waddr(15 downto 12)));
        role  := to_integer(unsigned(waddr(11 downto 8)));
        reg   := to_integer(unsigned(waddr(7 downto 0)));              
        if (scope=C_SCOPE_GLOBAL) and (role=C_ROLE_TIMING) then
          if (reg=C_ADDR_TIMING_TRIG) then
            trig_cfg <= wdata;
            TRIG_UPDATE_O <= '1';
            wack  <= '1';
          elsif (reg=C_ADDR_TIMING_SYNC) then            
            sync_cfg <= wdata;
            SYNC_UPDATE_O <= '1';
            wack  <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
  
end;  

