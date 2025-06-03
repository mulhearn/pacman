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
    COMMAND_I      : in  std_logic_vector(7 downto 0);
    STATUS_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    LAST_O         : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    STATE_O        : out std_logic_vector(3 downto 0);

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
  signal mode  : std_logic_vector(3 downto 0);
  
  signal wen   : std_logic_vector(3 downto 0) := (others => '0');
  signal addr  : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal data  : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');

  signal stat  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal last  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  -- will break if C_RB_DATA_WIDTH not equal to BRAM_DATA_WIDTH
  signal trig  : std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
  signal step  : std_logic_vector(ADC_DATA_WIDTH-1 downto 0);
  signal state : std_logic_vector(3 downto 0) := x"4";
  -- command pulses
  signal t_rst : std_logic;
  signal run   : std_logic;
  signal halt  : std_logic;

  -- switch negative-edge inputs to positive-edge registers
  signal adc_data_ne : std_logic_vector(ADC_DATA_WIDTH-1 downto 0) := (others => '0');
  signal adc_dof_ne   : std_logic := '0';
  signal adc_data    : std_logic_vector(ADC_DATA_WIDTH-1 downto 0) := (others => '0');
  signal adc_dof      : std_logic := '0';
  
begin
  clk         <= ACLK;
  rst         <= not ARESETN;
  BRAM_EN_O   <= CONFIG_I(1);
  BRAM_RST_O  <= rst;
  BRAM_CLK_O  <= clk;
  upper       <= CONFIG_I(31 downto 16);
  mid         <= CONFIG_I(15 downto 8);
  mode        <= CONFIG_I(7 downto 4);
  ADC_EN_O    <= CONFIG_I(0);

  t_rst       <= COMMAND_I(0);
  run         <= COMMAND_I(1);
  halt        <= COMMAND_I(2);

  BRAM_ADDR_O <= addr;
  BRAM_DATA_O <= data;
  BRAM_WEN_O  <= wen;

  STATUS_O    <= stat;
  LAST_O      <= last;
  STATE_O     <= state;

  trig        <= x"800";
  step        <= x"000";

  process(clk,rst)
  begin
    if (rst = '1') then
      adc_data_ne <= (others => '0');
      adc_dof_ne   <= '0';
    elsif (falling_edge(clk)) then
      adc_data_ne <= ADC_DATA_I;
      adc_dof_ne  <= ADC_DOF_I;
    end if;
  end process;

  process(clk,rst)
  begin
    if (rst = '1') then
      adc_data <= (others => '0');
      adc_dof  <= '0';
    elsif (rising_edge(clk)) then
      adc_data <= adc_data_ne;
      adc_dof  <= adc_dof_ne;
    end if;
  end process;

  process(clk,rst)
    variable limit : integer := 128;
    variable count : integer;
    variable low   : unsigned(ADC_DATA_WIDTH-1 downto 0);
    variable high  : unsigned(ADC_DATA_WIDTH-1 downto 0);
  begin
    high  := unsigned(trig) + unsigned(step);
    low   := unsigned(trig) - unsigned(step);
    if (rst = '1') then
      wen      <= (others => '0');
      data     <= (others => '0');
      addr     <= (others => '0');
      count    := 0;
      state    <= x"4";
    elsif (rising_edge(clk)) then
      if (mode = x"0") then
        wen      <= (others => '0');
        data     <= (others => '0');
        addr     <= (others => '0');
      elsif (mode = x"1") then
        data(11 downto 0)  <= adc_data;
        data(12)           <= adc_dof;
        data(31 downto 13) <= (others => '0');
        wen                <= (others => '1');
        if (upper = x"0") then
          addr <= std_logic_vector(unsigned(addr) + 4);
        elsif (unsigned(addr) >= unsigned(upper)) then
          addr <= (others => '0');
        else
          addr <= std_logic_vector(unsigned(addr) + 4);
        end if;
      elsif (mode = x"2") then -- bit packing
        data(11 downto 0)  <= adc_data;
        data(12)           <= adc_dof;
        data(15 downto 13) <= (others => '0');
        data(27 downto 16) <= adc_data;
        data(28)           <= adc_dof;
        data(31 downto 29)  <= (others => '0');
        if (wen = x"3") then
          wen <= x"C";
        else
          wen <= x"3";
          if (upper = x"0") then
            addr <= std_logic_vector(unsigned(addr) + 4);
          elsif (unsigned(addr) >= unsigned(upper)) then
            addr <= (others => '0');
          else
            addr <= std_logic_vector(unsigned(addr) + 4);
          end if;
        end if;
      elsif (mode = x"A") then
        wen      <= (others => '1');
        data     <= x"ABCD1234";
        addr     <= (others => '0');
      elsif (mode = x"B") then
        wen      <= mid(3 downto 0);
        data     <= x"12345678";
        addr     <= upper(BRAM_ADDR_WIDTH-1 downto 0);
      elsif (mode = x"C") then
        wen                <= (others => '1');
        data(7 downto 0)   <= mid;
        data(15 downto 8)  <= mid;
        data(23 downto 16) <= mid;
        data(31 downto 24) <= mid;          
        addr               <= upper(BRAM_ADDR_WIDTH-1 downto 0);
      elsif (mode = x"D") then
        wen      <= (others => '1');
        if (unsigned(addr) >= unsigned(upper)) then
          addr   <= (others => '0');
          data   <= x"ABCD0000";
          wen    <= (others => '1');
        else
          data   <= std_logic_vector(x"ABCD0000" + unsigned(addr) + 4);
          addr   <= std_logic_vector(unsigned(addr) + 4);
          wen    <= (others => '1');
        end if;
      elsif (mode = x"3") then
        -- get output data
        data(11 downto 0)  <= adc_data;
        data(12)           <= adc_dof;
        data(31 downto 13) <= (others => '0');
        -- get address
        if (wen /= x"0") then
          if (upper = x"0") then
            addr <= std_logic_vector(unsigned(addr) + 4);
          elsif (unsigned(addr) >= unsigned(upper)) then
            addr <= (others => '0');
          else
            addr <= std_logic_vector(unsigned(addr) + 4);
          end if;
        end if;
        wen <= (others => '1'); --kinda not necessary here but makes it
                              --easier if we want to bit pack
        -- handles states
        if (state = x"0") then
          wen   <= (others => '0');
          data  <= (others => '0');
        elsif (state = x"1") then
          if (unsigned(adc_data) > high) then
            state <= x"3";
          elsif (unsigned(adc_data) > low) then
            state <= x"2";
          end if;
        elsif (state = x"2") then
          if (unsigned(adc_data) < low) then
            state <= x"1";
          end if;
        elsif (state = x"3") then
          if (count >= limit) then
            state <= x"0";
            wen   <= (others => '0');
            data  <= (others => '0');
            count := 0;
          else
            count := count + 1;
          end if;
        else
          if (unsigned(adc_data) < low) then
            state <= x"1";
          else 
            state <= x"2";
          end if;   
        end if;
        -- handles command 
        if (t_rst = '1') then
          state    <= x"0";
          addr     <= (others => '0');
          count    := 0;
        end if;
        if (halt = '1') then
          state    <= x"0";
        end if;
        if (run = '1') then
          state    <= x"4";
        end if;
      else
        wen      <= (others => '0');
        data     <= (others => '0');
        addr     <= (others => '0');
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
          stat(19 downto 16) <= wen;
          last <= data;
        end if;
      end if;
    end if;
  end process;

end behavioral;
  

  
