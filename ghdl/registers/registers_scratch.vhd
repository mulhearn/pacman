library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registers_scratch is
  generic (
    C_DATA_WIDTH  : integer  := 32;
    C_ADDR_WIDTH  : integer  := 16;
    C_SCOPE       : integer  := 16#F#;  -- GLOBAL
    C_ROLE        : integer  := 16#1#;  -- DEBUGGING
    C_REG_SCRA    : integer  := 16#0#;
    C_REG_SCRB    : integer  := 16#4#;
    C_REG_STAT    : integer  := 16#8#;
    C_REG_ROA     : integer  := 16#C#;
    C_REG_ROB     : integer  := 16#10#;
    C_VAL_ROA     : unsigned(31 downto 0)  := x"11111111";
    C_VAL_ROB     : unsigned(31 downto 0)  := x"22222222"
    );      
  port (
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK    : out  std_logic;
    
    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out  std_logic;
    --
    DEBUG               : out  std_logic_vector(C_DATA_WIDTH-1 downto 0)
    );
begin
  assert C_ADDR_WIDTH>=8;
end;

architecture behavioral of registers_scratch is
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
  signal rdata    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal rack     : std_logic := '0';
  
  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
  signal wdata    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal wack     : std_logic := '0';

  -- registers
  signal scra    : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
  signal scrb    : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '1');
  signal stat    : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
  
begin
  DEBUG <= scra;
  clk <= ACLK;
  
  --outputs:
  S_REGBUS_RB_RDATA	 <= rdata;
  S_REGBUS_RB_RACK	 <= rack;
  S_REGBUS_RB_WACK	 <= wack;

  --inputs: (already registered at preceding stage)
  rupdate  <= S_REGBUS_RB_RUPDATE;
  raddr    <= S_REGBUS_RB_RADDR;
  wupdate  <= S_REGBUS_RB_WUPDATE;
  waddr    <= S_REGBUS_RB_WADDR;
  wdata    <= S_REGBUS_RB_WDATA;
    
  process(clk)
  begin
    if (falling_edge(clk)) then
      rst <= not ARESETN;
    end if;
  end process;

  -- Handle Read Request:
  process(clk)
  variable scope   : integer;
  variable role    : integer;
  variable reg     : integer;
  begin  
    if (rst = '1') then
      rdata <= x"00000000";
      rack <= '0';
    else
      if (rising_edge(clk)) then
        if (rupdate='0') then
          rdata <= x"00000000";
          rack <= '0';
        else
          scope := to_integer(unsigned(raddr(15 downto 12)));
          role  := to_integer(unsigned(raddr(11 downto 8)));
          reg   := to_integer(unsigned(raddr(7 downto 0)));          
          if ((scope=C_SCOPE) and (role=C_ROLE)) then
            if (reg=C_REG_SCRA) then
              rdata <= scra;
              rack  <= '1';
            elsif (reg=C_REG_SCRB) then
              rdata <= scrb;
              rack  <= '1';
            elsif (reg=C_REG_STAT) then
              rdata <= stat;
              rack  <= '1';
            elsif (reg=C_REG_ROA) then
              rdata <= std_logic_vector(C_VAL_ROA);
              rack  <= '1';
            elsif (reg=C_REG_ROB) then
              rdata <= std_logic_vector(C_VAL_ROB);
              rack  <= '1';
            else
                -- this is an error, invalid register
                rdata <= x"EEEEEEEE";
                rack  <= '0';
            end if;
          else
            -- this is not an error, just a request outside our scope/role
            rdata <= x"00000000";
            rack  <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Handle Write Request:
  process(clk)
  variable scope   : integer;
  variable role    : integer;
  variable reg     : integer;
  begin  
    if (rst = '1') then
      scra <= x"00000000";
      scrb <= x"00000000";
    else
      if (rising_edge(clk)) then
        if (wupdate='0') then
            wack  <= '0';          
        else
          scope := to_integer(unsigned(waddr(15 downto 12)));
          role  := to_integer(unsigned(waddr(11 downto 8)));
          reg   := to_integer(unsigned(waddr(7 downto 0)));          
          if ((scope=C_SCOPE) and (role=C_ROLE)) then
            if (reg=C_REG_SCRA) then
              scra<= wdata;
              wack  <= '1';
            elsif (reg=C_REG_SCRB) then
              scrb<= wdata;
              wack  <= '1';
            else
                -- this is an error, invalid register
                wack  <= '0';
            end if;
          else
            -- this is not an error, just a request outside our scope/role
            wack  <= '0';
          end if;
        end if;
      end if;   
    end if;
  end process;
  
end;  

