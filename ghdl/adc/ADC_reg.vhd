library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity ADC_reg is
  generic (
    C_SCOPE       : integer  := 16#D#;
    C_ROLE        : integer  := 16#1#;
    C_REG_TRIG    : integer  := 16#0#;
    C_REG_DIVS    : integer  := 16#4#;
    C_REG_ADC_EN  : integer  := 16#8#;
    C_REG_LAST_W  : integer  := 16#C#;
    C_REG_ROB     : integer  := 16#10#;
    C_VAL_ROB     : unsigned(31 downto 0)  := x"22222222"
    );      
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

    TRIG_MODE           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    CLK_DIV             : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    ADC_EN              : out std_logic;
    LAST_W              : in  std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
    );
end entity ADC_reg;

architecture behavioral of ADC_reg is
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal rdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rack     : std_logic := '0';
  
  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal wdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal wack     : std_logic := '0';

  -- registers
  signal trig     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal divs     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal adce     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal lw32     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');


begin
  --inputs:
  clk       <= ACLK;
  rst       <= not ARESETN;
  lw32(C_RB_DATA_WIDTH-1 downto C_RB_DATA_WIDTH-BRAM_ADDR_WIDTH)  <= LAST_W;
  lw32(C_RB_DATA_WIDTH-BRAM_ADDR_WIDTH-1 downto 0) <= (others => '0');
  
  --outputs:
  TRIG_MODE <= trig;
  CLK_DIV   <= divs;
  ADC_EN    <= adce(C_RB_DATA_WIDTH-1);

  --REGBUS--  
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

  
  -- Handle Read Request:
  process(clk,rst)
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
          --rdata is registered until the next update or reset.
          rack <= '0';
        else
          scope := to_integer(unsigned(raddr(15 downto 12)));
          role  := to_integer(unsigned(raddr(11 downto 8)));
          reg   := to_integer(unsigned(raddr(7 downto 0)));          
          if ((scope=C_SCOPE) and (role=C_ROLE)) then
            if (reg=C_REG_TRIG) then
              rdata <= trig;
              rack  <= '1';
            elsif (reg=C_REG_DIVS) then
              rdata <= divs;
              rack  <= '1';
            elsif (reg=C_REG_ADC_EN) then
              rdata <= adce;
              rack  <= '1';
            elsif (reg=C_REG_LAST_W) then
              rdata <= lw32;
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
  process(clk,rst)
  variable scope   : integer;
  variable role    : integer;
  variable reg     : integer;
  begin  
    if (rst = '1') then
      trig <= x"00000000";
      divs <= x"00000000";
      adce <= x"00000000";
    else
      if (rising_edge(clk)) then
        if (wupdate='0') then
            wack  <= '0';          
        else
          scope := to_integer(unsigned(waddr(15 downto 12)));
          role  := to_integer(unsigned(waddr(11 downto 8)));
          reg   := to_integer(unsigned(waddr(7 downto 0)));          
          if ((scope=C_SCOPE) and (role=C_ROLE)) then
            if (reg=C_REG_TRIG) then
              trig   <= wdata;
              wack   <= '1';
            elsif (reg=C_REG_DIVS) then
              divs  <= wdata;
              wack  <= '1';
            elsif (reg=C_REG_ADC_EN) then
              adce  <= wdata;
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


