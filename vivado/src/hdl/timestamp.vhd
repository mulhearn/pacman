library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timestamp is
  generic (
    constant C_TIMESTAMP_WIDTH     : integer := 32
  );

  port (
    -- Clock Domain A: (Fast Clock)
    CLK_A_I	        : in  std_logic;
    RSTN_A_I	        : in  std_logic;
    TIMESTAMP_A_O       : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    
    -- Clock Domain B: (Slow Clock)
    CLK_B_I             : in  std_logic;
    RSTN_B_I            : in  std_logic;    
    TIMESTAMP_B_O       : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0)
    );
end;

architecture behavioral of timestamp is
  -- Clock Domain A signals:
  signal clk_a       : std_logic;
  signal rstn_a      : std_logic;
  signal timestamp_a : unsigned(C_TIMESTAMP_WIDTH-1 downto 0);
  signal timestamp_z : unsigned(C_TIMESTAMP_WIDTH-1 downto 0); 
  
  -- Clock Domain B signals:
  signal clk_b       : std_logic;
  signal rstn_b      : std_logic;
  signal counter_b   : unsigned(C_TIMESTAMP_WIDTH-1 downto 0) := (others => '0');

  -- double flopping at clock domain crossing:
  signal timestamp_meta : unsigned(C_TIMESTAMP_WIDTH-1 downto 0) := (others => '0'); -- metastable
  signal timestamp_sync : unsigned(C_TIMESTAMP_WIDTH-1 downto 0) := (others => '0'); 

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of timestamp_meta: signal is "TRUE";
  attribute ASYNC_REG of timestamp_sync: signal is "TRUE";

begin
  clk_a    <= CLK_A_I;
  rstn_a    <= RSTN_A_I;
  TIMESTAMP_A_O <= std_logic_vector(timestamp_a);

  clk_b <= CLK_B_I;
  rstn_b <= RSTN_B_I;
  TIMESTAMP_B_O <= std_logic_vector(counter_b);
  
  -- double flop synchronization of timestamp and sync signals (from B to A)
  process(clk_a, rstn_a)
  begin
    if (rstn_a = '0') then
      timestamp_z    <= (others => '0');
      timestamp_meta <= (others => '0');
      timestamp_sync <= (others => '0');
      timestamp_a    <= (others => '0');
    elsif (rising_edge(clk_a)) then
      timestamp_z    <= timestamp_a;
      timestamp_meta <= counter_b;
      timestamp_sync <= timestamp_meta;
      -- suppress single cycle clock domain crossing glitches by only accepting
      -- valid transitions (reset or increment):
      if (timestamp_sync = to_unsigned(0, timestamp_sync'length)) then
        timestamp_a <= (others => '0');
      elsif (timestamp_sync = timestamp_z+1) then
        timestamp_a <= timestamp_sync;
      end if;
    end if;
  end process;

  -- clock domain B process
  process(clk_b, rstn_a, rstn_b)
  begin
    if ((rstn_a = '0') or (rstn_b = '0')) then
      counter_b <= (others => '0');      
    elsif (rising_edge(clk_b)) then
      counter_b <= counter_b + 1;
    end if;
  end process;
end;
