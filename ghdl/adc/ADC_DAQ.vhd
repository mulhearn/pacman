library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity ADC_DAQ is
  port (
    ACLK      : in std_logic;
    ARESETN   : in std_logic;

    DATA_IN   : in std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
    DOF_IN    : in std_logic;

    TRIG_MODE : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    DATA_OUT  : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');

    ADDR      : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    WEN       : out std_logic;
    
    LAST_W    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
    );
end entity ADC_DAQ;

architecture behavioral of ADC_DAQ is
  signal clk  : std_logic;
  signal rst  : std_logic;
  signal trig : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal cnt  : unsigned(BRAM_ADDR_WIDTH-1 downto 0);
  signal data : std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
  signal d_of : std_logic;
  signal w    : std_logic;
  signal a    : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);

begin
  clk      <= ACLK;
  rst      <= not ARESETN;
  trig     <= TRIG_MODE;
  WEN      <= w;
  ADDR     <= a;
  DATA_OUT(BRAM_DATA_WIDTH-1) <= d_of;
  DATA_OUT(BRAM_DATA_WIDTH-2 downto BRAM_DATA_WIDTH-ADC_DATA_WIDTH-1) <= data;

  process(clk,rst) --gets data and Write EN
  begin
    if (rst = '1') then
      w        <= '0';
      data     <= x"000";
      d_of     <= '0';
    else
      if (rising_edge(clk)) then
        if (trig = x"00000000") then
          w    <= '0';
          data <= (others => '0');
          d_of <= '0';
        elsif (trig = x"00000001") then
          data <= DATA_IN;
          d_of <= DOF_IN;
          w        <= '1';
        elsif (trig = x"000000FF") then
          data <= x"AAA";
          d_of <= '0';
          w    <= '1';
        else
          w    <= '0';
          data <= (others => '0');
          d_of <= '0';
        end if;
      end if;
    end if;
  end process;

  process(clk,rst) -- gets address and last address
  begin
    if (rst = '1') then
      LAST_W <= (others => '0');
      a      <= (others => '0');
      cnt    <= x"00";
    else
      if (rising_edge(clk)) then
        if (w = '1') then
          LAST_W <= a;
          cnt <= cnt + 1;
          a <= std_logic_vector(cnt + 1);
        end if;
      end if;
    end if;
  end process;
end behavioral;
  

  
