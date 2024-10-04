library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.version.all;
use work.common.all;
use work.register_map.all;

entity global_registers is
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

    ANALOG_PWR_EN_O     : out std_logic;
    TILE_EN_O           : out std_logic_vector(C_NUM_TILE-1 downto 0);
    ADC_EN_O            : out std_logic
    );
end;

architecture behavioral of global_registers is
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

  -- output registers:
  signal enables   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)   := (others => '0');
  signal scratch_a : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)   := (others => '0');
  signal scratch_b : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)   := (others => '0');
    
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
  
  -- registers
  TILE_EN_O  <= enables(C_NUM_TILE-1 downto 0);
  ANALOG_PWR_EN_O <= enables(16);
  ADC_EN_O <= enables(20);
  
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
        if (scope=C_SCOPE_GLOBAL) and (role=C_ROLE_GLOBAL) then
          rdata <= x"EEEEEEEE";
          if (reg=C_ADDR_GLOBAL_SCRA) then
            rdata <= scratch_a;
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_SCRB) then
            rdata <= scratch_b;
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_FW_MAJOR) then
            rdata <= std_logic_vector(to_unsigned(C_FW_MAJOR,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_FW_MINOR) then
            rdata <= std_logic_vector(to_unsigned(C_FW_MINOR,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_FW_BUILD) then
            rdata <= std_logic_vector(to_unsigned(C_FW_BUILD,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_HW_CODE) then
            rdata <= std_logic_vector(to_unsigned(C_HW_CODE,rdata'length));
            rack  <= '1';            
          elsif (reg=C_ADDR_GLOBAL_ENABLES) then
            rdata <= enables;
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
      enables   <= (others => '0');
      scratch_a <= (others => '0');
      scratch_b <= (others => '0');
    elsif (rising_edge(clk)) then
      wack <= '0';      
      if (wupdate='1') then
        scope := to_integer(unsigned(waddr(15 downto 12)));
        role  := to_integer(unsigned(waddr(11 downto 8)));
        reg   := to_integer(unsigned(waddr(7 downto 0)));              
        if (scope=C_SCOPE_GLOBAL) and (role=C_ROLE_GLOBAL) then
          if (reg=C_ADDR_GLOBAL_SCRA) then
            scratch_a <= wdata;
            wack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_SCRB) then
            scratch_b <= wdata;                                             
            wack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_ENABLES) then
            enables <= wdata;
            wack  <= '1';            
          end if;
        end if;
      end if;
    end if;
  end process;  
end;  

