library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.firmware_version.all;
use work.hardware_version.all;
use work.common.all;
use work.register_map.all;
use work.version_info_pkg.all;

--
-- global_registers:  this modules handles reading and writing the global
-- registers over the REGBUS interface.
--
-- see register_map.vhd for registers addresses
-- see PACMAN TRM for register descriptions
--

entity global_registers is
  port (
    -- clock and active-high reset
    CLK_I	        : in std_logic;
    RST_I	        : in std_logic;

    -- register bus (REGBUS) interface
    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RACK    : out std_logic;

    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out std_logic;

    -- power and tile enables, set via register:
    ANALOG_PWR_EN_O     : out std_logic;
    TILE_EN_O           : out std_logic_vector(C_NUM_TILE-1 downto 0);

    -- led configuration register:
    LED_CONFIG_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- global status input:
    GLOBAL_STATUS_I     : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
end;

architecture behavioral of global_registers is
  -- clock and active-high reset:
  signal clk      : std_logic;
  signal rst      : std_logic;

  -- REGBUS signals:
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
  signal led_config      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)   := (others => '0');

begin
  clk <= CLK_I;
  rst <= RST_I;

  rupdate  <= S_REGBUS_RB_RUPDATE;
  raddr    <= S_REGBUS_RB_RADDR;
  S_REGBUS_RB_RDATA <= rdata;
  S_REGBUS_RB_RACK  <= rack;
  wupdate  <= S_REGBUS_RB_WUPDATE;
  waddr    <= S_REGBUS_RB_WADDR;
  wdata    <= S_REGBUS_RB_WDATA;
  S_REGBUS_RB_WACK	 <= wack;

  -- set register controlled outputs:
  TILE_EN_O  <= enables(C_NUM_TILE-1 downto 0);
  ANALOG_PWR_EN_O <= enables(16);
  LED_CONFIG_O  <= led_config;

  -- Handle Read Request:
  -- 1) Read request are indicated via rupdate=1 with a valid address
  -- raddr
  -- 2) Check that MSB byte (scope) of rdaddr matches this modules
  -- scope
  -- 3) Check remaining three bytes for a match with a defined
  -- register
  -- 4) If a match is found, on next clock cycle, set corresponding
  -- data on rdata and rack=1

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
        if (scope=C_SCOPE_GLOBAL) then
          rdata <= x"EEEEEEEE";
          if (reg=C_ADDR_GLOBAL_STATUS) then
            rdata <= GLOBAL_STATUS_I;
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_ENABLES) then
            rdata <= enables;
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_LEDS) then
            rdata <= led_config;
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_SCRATCH_A) then
            rdata <= scratch_a;
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_SCRATCH_B) then
            rdata <= scratch_b;
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_FIRMWARE_MAJOR) then
            rdata <= std_logic_vector(to_unsigned(C_FIRMWARE_MAJOR,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_FIRMWARE_MINOR) then
            rdata <= std_logic_vector(to_unsigned(C_FIRMWARE_MINOR,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_FIRMWARE_PATCH) then
            rdata <= std_logic_vector(to_unsigned(C_FIRMWARE_PATCH,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_HARDWARE_MAJOR) then
            rdata <= std_logic_vector(to_unsigned(C_HARDWARE_MAJOR,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_HARDWARE_MINOR) then
            rdata <= std_logic_vector(to_unsigned(C_HARDWARE_MINOR,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_HARDWARE_PATCH) then
            rdata <= std_logic_vector(to_unsigned(C_HARDWARE_PATCH,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_SYNTHESIS_DATE) then
            rdata <= std_logic_vector(to_unsigned(C_SYNTHESIS_DATE,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_GIT_HASH_UPPER) then
            rdata <= std_logic_vector(to_unsigned(C_GIT_HASH_UPPER,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_GIT_HASH_LOWER) then
            rdata <= std_logic_vector(to_unsigned(C_GIT_HASH_LOWER,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_VIVADO_MAJOR) then
            rdata <= std_logic_vector(to_unsigned(C_VIVADO_MAJOR,rdata'length));
            rack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_VIVADO_MINOR) then
            rdata <= std_logic_vector(to_unsigned(C_VIVADO_MINOR,rdata'length));
            rack  <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Handle Write Request:
  -- 1) write request are indicated via wupdate=1 with a valid address
  -- waddr and data wdata
  -- 2) check that MSB byte (scope) of rdaddr matches this modules
  -- scope
  -- 3) check remaining three bytes for a match with a defined
  -- register
  -- 4) if match found, on next clock cycle, set corresponding data to
  -- wdata and set wack=1
  process(clk, rst)
    variable scope   : integer range 0 to 16#F#;
    variable reg     : integer range 0 to 16#FFF#;
  begin
    if (rst = '1') then
      wack  <= '0';
      enables   <= (others => '0');
      scratch_a <= (others => '0');
      scratch_b <= (others => '0');
      led_config      <= (others => '0');
    elsif (rising_edge(clk)) then
      wack <= '0';
      if (wupdate='1') then
        scope := to_integer(unsigned(waddr(15 downto 12)));
        reg   := to_integer(unsigned(waddr(11 downto 0)));
        if (scope=C_SCOPE_GLOBAL) then
          if (reg=C_ADDR_GLOBAL_ENABLES) then
            enables <= wdata;
            wack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_LEDS) then
            led_config <= wdata;
            wack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_SCRATCH_A) then
            scratch_a <= wdata;
            wack  <= '1';
          elsif (reg=C_ADDR_GLOBAL_SCRATCH_B) then
            scratch_b <= wdata;
            wack  <= '1';
          end if;
        end if;
      end if;
    end if;
  end process;
end;
