library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_reg is
  generic (
    C_SCOPE            : integer  := 16#D#;
    C_REG_ADC_STATUS   : integer  := 16#100#; -- RO
    C_REG_ADC_LOOK     : integer  := 16#104#; -- RO
    C_REG_ADC_LAST     : integer  := 16#108#; -- RO
    C_REG_ADC_STATE    : integer  := 16#10C#; -- RO
    C_REG_ADC_CONFIG   : integer  := 16#110#; -- RW
    C_REG_ADC_CLKPAR   : integer  := 16#114#; -- RW
    C_REG_ADC_COMMAND  : integer  := 16#118#; -- RW
    C_REG_ADC_SCRATCH  : integer  := 16#200#; -- RW
    C_REG_ADC_ROA      : integer  := 16#204#; -- RO
    C_VAL_ADC_ROA      : integer  := 16#1234ABCD#
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

    CONFIG_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    CLKPAR_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    COMMAND_O           : out std_logic_vector(7 downto 0);
    STATUS_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    STATE_I             : in  std_logic_vector(3 downto 0);
    LAST_I              : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    LOOK_I              : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
end entity adc_reg;

architecture behavioral of adc_reg is
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
  signal config   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal clkpar   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal scratch  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal command  : std_logic_vector(7 downto 0) := (others => '0');
  signal state    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

begin
  --inputs:
  clk       <= ACLK;
  rst       <= not ARESETN;

  --output registers
  CONFIG_O  <= config;
  CLKPAR_O  <= clkpar;
  COMMAND_O <= command;

  state(3 downto 0 ) <= STATE_I;

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
          reg   := to_integer(unsigned(raddr(11 downto 0)));
          if (scope=C_SCOPE) then
            if (reg=C_REG_ADC_STATUS) then
              rdata <= STATUS_I;
              rack  <= '1';
            elsif (reg=C_REG_ADC_LOOK) then
              rdata <= LOOK_I;
              rack  <= '1';
            elsif (reg=C_REG_ADC_LAST) then
              rdata <= LAST_I;
              rack  <= '1';
            elsif (reg=C_REG_ADC_CONFIG) then
              rdata <= config;
              rack  <= '1';
            elsif (reg=C_REG_ADC_CLKPAR) then
              rdata <= clkpar;
              rack  <= '1';
            elsif (reg=C_REG_ADC_STATE) then
              rdata <= state;
              rack  <= '1';
            elsif (reg=C_REG_ADC_SCRATCH) then
              rdata <= scratch;
              rack  <= '1';
            elsif (reg=C_REG_ADC_ROA) then
              rdata <= std_logic_vector(to_unsigned(C_VAL_ADC_ROA, rdata'length));
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
    variable reg     : integer;
  begin
    if (rst = '1') then
      config <= x"00000000";
      clkpar <= x"00000000";
      scratch <= x"00000000";
      command <= x"00";
    else
      if (rising_edge(clk)) then
        command <= x"00";
        if (wupdate='0') then
          wack  <= '0';
        else
          scope := to_integer(unsigned(waddr(15 downto 12)));
          reg   := to_integer(unsigned(waddr(11 downto 0)));
          if (scope=C_SCOPE) then
            if (reg=C_REG_ADC_CONFIG) then
              config  <= wdata;
              wack    <= '1';
            elsif (reg=C_REG_ADC_CLKPAR) then
              clkpar  <= wdata;
              wack    <= '1';
            elsif (reg=C_REG_ADC_COMMAND) then
              command <= wdata(7 downto 0);
              wack    <= '1';
            elsif (reg=C_REG_ADC_SCRATCH) then
              scratch <= wdata;
              wack    <= '1';
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
