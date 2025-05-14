library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity adc_daq is
  port (
    ACLK           : in  std_logic;
    ARESETN        : in  std_logic;

    -- ADC
    ADC_DATA_I     : in  std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
    ADC_DOF_I      : in  std_logic;
    ADC_EN_O       : out std_logic;

    -- REGISTER
    CONFIG_I       : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    STATUS_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    LAST_O         : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- BRAM
    BRAM_EN_O      : out std_logic; 
    BRAM_DATA_O    : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    BRAM_WEN_O     : out std_logic_vector(3 downto 0);
    BRAM_ADDR_O    : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    BRAM_CLK_O     : out std_logic;
    BRAM_RST_O     : out std_logic
    );
end entity adc_daq;

architecture behavioral of adc_daq is
  signal clk   : std_logic;
  signal rst   : std_logic;
  signal upper : std_logic_vector(15 downto 0);
  signal mid   : std_logic_vector(7 downto 0);
  signal trig  : std_logic_vector(3 downto 0);
  
  signal wen  : std_logic_vector(3 downto 0) := (others => '0');
  signal addr : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal data : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');

  signal stat : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal last : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  -- will break if C_RB_DATA_WIDTH not equal to BRAM_DATA_WIDTH


begin
  clk         <= ACLK;
  rst         <= not ARESETN;
  BRAM_EN_O   <= CONFIG_I(1);
  BRAM_RST_O  <= rst;
  BRAM_CLK_O  <= clk;
  upper       <= CONFIG_I(31 downto 16);
  mid         <= CONFIG_I(15 downto 8);
  trig        <= CONFIG_I(7 downto 4);
  ADC_EN_O    <= CONFIG_I(0);

  BRAM_ADDR_O <= addr;
  BRAM_DATA_O <= data;
  BRAM_WEN_O  <= wen;

  STATUS_O    <= stat;
  LAST_O      <= last;

  process(clk,rst) --gets data and Write EN and addr
  begin
    if (rst = '1') then
      wen      <= (others => '0');
      data     <= (others => '0');
      addr     <= (others => '0');
    else
      if (rising_edge(clk)) then
        if (trig = x"0") then
          wen      <= (others => '0');
          data     <= (others => '0');
          addr     <= (others => '0');
        --elsif (trig = x"1") then
        --  data <= DATA_IN;
        --  d_of <= DOF_IN;
        --  w        <= '1';
        elsif (trig = x"A") then
          wen      <= (others => '1');
          data     <= x"ABCD1234";
          addr     <= (others => '0');
        elsif (trig = x"B") then
          wen      <= mid(3 downto 0);
          data     <= x"12345678";
          addr     <= upper(BRAM_ADDR_WIDTH-1 downto 0);
        elsif (trig = x"C") then
          wen                <= (others => '1');
          data(7 downto 0)   <= mid;
          data(15 downto 8)  <= mid;
          data(23 downto 16) <= mid;
          data(31 downto 24) <= mid;          
          addr               <= upper(BRAM_ADDR_WIDTH-1 downto 0);
        --elsif (trig = x"A") then
        --  wen      <= (others => '1');
        --  data     <= x"ABCD1234";
        --  addr     <= (others => '0');
        else
          wen      <= (others => '0');
          data     <= (others => '0');
          addr     <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  process(clk,rst) -- gets status and last
  begin
    if (rst = '1') then
      last <= (others => '0');
      stat <= (others => '0');
    else
      if (rising_edge(clk)) then
        if (wen /= x"0") then
          stat(BRAM_ADDR_WIDTH-1 downto 0) <= addr;
          last <= data;
        end if;
      end if;
    end if;
  end process;
end behavioral;
  

  
