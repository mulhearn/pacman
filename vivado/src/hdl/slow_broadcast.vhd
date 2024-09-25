library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Broadcast a command according to configuration in a slower clock domain

entity slow_broadcast is
  generic (
    constant C_BROADCAST_WIDTH : integer := 10;
    constant C_CONFIG_WIDTH : integer := 32
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
    BROADCAST_B_O       : out std_logic_vector(C_BROADCAST_WIDTH-1 downto 0);
    DEBUG_O             : out std_logic_vector(7 downto 0)
  );
end;

architecture behavioral of slow_broadcast is
  -- Clock Domain A signals:
  signal clk_a      : std_logic;
  signal rst_a      : std_logic;
  signal update_a   : std_logic;
  signal busy_a     : std_logic;

  signal clk_b      : std_logic;

  signal config     : std_logic_vector(C_CONFIG_WIDTH-1 downto 0);
  signal update     : std_logic;
  signal ack        : std_logic;

  -- double flopping at clock domain crossing:
  signal update_meta : std_logic; -- metastable
  signal update_sync : std_logic; -- likely stable
  signal ack_meta    : std_logic; -- metastable
  signal ack_sync    : std_logic; -- likely stable
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of update_meta: signal is "TRUE";
  attribute ASYNC_REG of update_sync: signal is "TRUE";
  attribute ASYNC_REG of ack_meta:    signal is "TRUE";
  attribute ASYNC_REG of ack_sync:    signal is "TRUE";

  --type state_t is (IDLE, RUN, FINAL);
  --signal state_a : state_t := IDLE;
  --signal state_b : state_t := IDLE;

begin
  clk_a    <= CLK_A_I;
  rst_a    <= RST_A_I;
  update_a <= UPDATE_A_I;
  BUSY_A_O <= busy_a;

  clk_b <= CLK_B_I;

  DEBUG_O(0) <= update;
  DEBUG_O(1) <= ack;
  DEBUG_O(7 downto 2) <= (others => '0');
  
  -- double flop synchronization of ack signal (B to A)
  process(clk_a, rst_a)
  begin
    if (rst_a = '1') then
      ack_meta <= '0';
      ack_sync <= '0';
    elsif (rising_edge(clk_a)) then
      ack_meta <= ack;
      ack_sync <= ack_meta;
    end if;
  end process;

  -- double flop synchronization of update signal (A to B)
  process(clk_b, rst_a)
  begin
    if (rst_a = '1') then
      update_meta <= '0';
      update_sync <= '0';
    elsif (rising_edge(clk_b)) then
      update_meta <= update; --metastable
      update_sync <= update_meta; --likely stable
    end if;
  end process;

  -- clock domain A process
  process(clk_a, rst_a)
  begin
    if (rst_a = '1') then
      update <= '0';
      busy_a <= '0';
      config <= (others => '0');
    elsif (rising_edge(clk_a)) then
      if (busy_a='0') then
        update <= '0';
        busy_a <= '0';
        config <= (others => '0');
        if (update_a='1') then
          update <= '1';
          busy_a <= '1';
          config <= CONFIG_A_I;
        end if;
      else
        if ((update='1') and (ack_sync='1')) then
          update <= '0';
        end if;
        if ((update='0') and (ack_sync='0')) then
          busy_a <= '0';
        end if;
      end if;
    end if;
  end process;

  -- clock domain B process
  process(clk_b, rst_a)
    variable counter : integer := 0;
  begin
    if (rst_a = '1') then
      BROADCAST_B_O <= (others => '0');      
      ack <= '0';
      counter := counter - 1;
    elsif (rising_edge(clk_b)) then
      if ((ack='0') and (update_sync='1')) then
        ack <= '1';
        counter := to_integer(unsigned(config(23 downto 16)));
      end if;
      if ((counter=0) and (update_sync='0')) then
        ack <= '0';
      end if;
      if (counter > 0) then
        BROADCAST_B_O <= config(C_BROADCAST_WIDTH-1 downto 0);
        counter := counter - 1;
      else
        BROADCAST_B_O <= (others => '0');
      end if;
    end if;
  end process;









end;
