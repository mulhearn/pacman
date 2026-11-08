library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;
use work.atc_pkg.all;

entity atc_registers is
  port (
    CLK_I : in std_logic;
    RST_I : in std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RACK    : out std_logic;
    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out std_logic;

    -- request update of configuration: (from CLK to UCLK)
    CONFIG_REQ_O        : out std_logic;  -- CDC

    -- request update of counts: (from UCLK to CLK)
    COUNT_REQ_O         : out std_logic;  -- CDC
    COUNT_CMD_O         : out std_logic_vector(C_BYTE_WIDTH-1 downto 0); -- CDC
    COUNT_I             : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- poke stimuli, each with associated mask, handled expiditiously:
    POKE_C_O            : out std_logic;  -- CDC
    MASK_C_O            : out std_logic_vector(C_NUM_TILE-1 downto 0); -- CDC
    POKE_D_O            : out std_logic;  -- CDC
    MASK_D_O            : out std_logic_vector(C_NUM_TILE-1 downto 0); -- CDC

    -- The following configuration registers may be written at any time,
    CONFIG_O            : out atc_config_t;

    STATUS_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    TIMESTAMP_I         : in  std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0)
  );
end;

architecture behavioral of atc_registers is
  signal clk : std_logic;
  signal rst : std_logic;

  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal rdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal rack     : std_logic := '0';
  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal wdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal wack     : std_logic := '0';

  signal polarity    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal logic       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_lemo_a  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_lemo_b  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_poke_c  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_poke_d  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_logic_e : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal dst_logic_f : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

begin
  -- Clock and reset inputs:
  clk <= CLK_I;
  rst <= RST_I;

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

  -- output registers:
  CONFIG_O.polarity     <= polarity;
  CONFIG_O.logic        <= logic;
  CONFIG_O.dst_lemo_a   <= dst_lemo_a;
  CONFIG_O.dst_lemo_b   <= dst_lemo_b;
  CONFIG_O.dst_poke_c   <= dst_poke_c;
  CONFIG_O.dst_poke_d   <= dst_poke_d;
  CONFIG_O.dst_logic_e  <= dst_logic_e;
  CONFIG_O.dst_logic_f  <= dst_logic_f;

  -- Handle Read Request:
  process(clk, rst)
    variable scope   : integer range 0 to 16#F#;
    variable reg     : integer range 0 to 16#FFF#;
  begin
    if (rst = '1') then
      rack <= '0';
      rdata <= x"00000000";
    elsif (rising_edge(clk)) then
      rack <= '0';
      if (rupdate='1') then
        scope := to_integer(unsigned(raddr(15 downto 12)));
        reg   := to_integer(unsigned(raddr(11 downto 0)));
        rdata <= x"00000000";
        if (scope = C_SCOPE_ATC) then
          rdata <= x"EEEEEEEE";
          if(reg= C_ADDR_ATC_POLARITY) then
            rdata <= polarity;
            rack  <= '1';
          elsif(reg= C_ADDR_ATC_LOGIC) then
            rdata <= logic;
            rack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_LEMO_A) then
            rdata <= dst_lemo_a;
            rack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_LEMO_B) then
            rdata <= dst_lemo_b;
            rack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_POKE_C) then
            rdata <= dst_poke_c;
            rack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_POKE_D) then
            rdata <= dst_poke_d;
            rack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_LOGIC_E) then
            rdata <= dst_logic_e;
            rack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_LOGIC_F) then
            rdata <= dst_logic_f;
            rack  <= '1';
          elsif(reg= C_ADDR_ATC_COUNT) then
            rdata <= COUNT_I;
            rack  <= '1';
          elsif (reg= C_ADDR_ATC_STATUS) then
            rdata <= STATUS_I;
            rack  <= '1';
          elsif (reg= C_ADDR_ATC_TIMESTAMP) then
            rdata <= TIMESTAMP_I(31 downto 0);
            rack  <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Handle Write Request:
  process(clk, rst)
    variable scope   : integer range 0 to 16#F#;
    variable reg     : integer range 0 to 16#FFF#;
  begin
    if (rst = '1') then
      wack  <= '0';

      CONFIG_REQ_O <= '0';
      COUNT_REQ_O  <= '0';
      COUNT_CMD_O  <= (others => '0');
      POKE_C_O <= '0';
      POKE_D_O <= '0';
      MASK_C_O <= (others => '0');
      MASK_D_O <= (others => '0');

      polarity     <= (others => '0');
      logic        <= (others => '0');
      dst_lemo_a   <= (others => '0');
      dst_lemo_b   <= (others => '0');
      dst_poke_c   <= (others => '0');
      dst_poke_d   <= (others => '0');
      dst_logic_e  <= (others => '0');
      dst_logic_f  <= (others => '0');

    elsif (rising_edge(clk)) then
      wack <= '0';
      CONFIG_REQ_O <= '0';
      COUNT_REQ_O  <= '0';
      -- TODO:  make these registers to avoid CE
      --COUNT_CMD_O <= (others => '0');
      POKE_C_O <= '0';
      --MASK_C_O <= (others => '0');
      POKE_D_O <= '0';
      --MASK_D_O <= (others => '0');

      if (wupdate='1') then
        scope := to_integer(unsigned(waddr(15 downto 12)));
        reg   := to_integer(unsigned(waddr(11 downto 0)));
        if (scope=C_SCOPE_ATC) then
          if(reg= C_ADDR_ATC_CONFIG_REQ) then
            CONFIG_REQ_O <= '1';
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_COUNT_REQ) then
            COUNT_REQ_O <= '1';
            COUNT_CMD_O <= wdata(C_BYTE_WIDTH-1 downto 0);
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_POKE_C) then
            POKE_C_O <= '1';
            MASK_C_O <= wdata(C_NUM_TILE-1 downto 0);
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_POKE_D) then
            POKE_D_O <= '1';
            MASK_D_O <= wdata(C_NUM_TILE-1 downto 0);
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_POLARITY) then
            polarity <= wdata;
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_LOGIC) then
            logic <= wdata;
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_LEMO_A) then
            dst_lemo_a <= wdata;
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_LEMO_B) then
            dst_lemo_b <= wdata;
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_POKE_C) then
            dst_poke_c <= wdata;
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_POKE_D) then
            dst_poke_d <= wdata;
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_LOGIC_E) then
            dst_logic_e <= wdata;
            wack  <= '1';
          elsif(reg= C_ADDR_ATC_DST_LOGIC_F) then
            dst_logic_f <= wdata;
            wack  <= '1';
          end if;

        end if;
      end if;
    end if;
  end process;

end;

