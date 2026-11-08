library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;

entity adc_registers is
  port (
    CLK_I	        : in std_logic;
    RST_I	        : in std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RACK    : out std_logic;

    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out std_logic;

    CONFIG_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    --STATUS_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    LOOK_I              : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
end entity adc_registers;

architecture behavioral of adc_registers is
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

begin
  --inputs:
  clk       <= CLK_I;
  rst       <= RST_I;

  --output registers
  CONFIG_O  <= config;

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
    elsif (rising_edge(clk)) then
      rack <= '0';
      if (rupdate='1') then
        scope := to_integer(unsigned(raddr(15 downto 12)));
        reg   := to_integer(unsigned(raddr(11 downto 0)));
        if (scope=C_SCOPE_ADC) then
          if (reg=C_ADDR_ADC_STATUS) then
            rdata <= x"00000ADC";
            rack  <= '1';
          elsif (reg=C_ADDR_ADC_LOOK) then
            rdata <= LOOK_I;
            rack  <= '1';
          elsif (reg=C_ADDR_ADC_CONFIG) then
            rdata <= config;
            rack  <= '1';
          else
            -- this is an error, invalid register
            rdata <= x"EEEEEEEE";
            rack  <= '0';
          end if;
        else
          -- this is not an error, just a request outside our scope/role
          rdata <= x"00000000";
          rdata(15 downto 0) <= raddr;
          rack  <= '0';
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
    elsif (rising_edge(clk)) then
      if (wupdate='0') then
        wack  <= '0';
      else
        scope := to_integer(unsigned(waddr(15 downto 12)));
        reg   := to_integer(unsigned(waddr(11 downto 0)));
        if (scope=C_SCOPE_ADC) then
          if (reg=C_ADDR_ADC_CONFIG) then
            config  <= wdata;
            wack    <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
end;
