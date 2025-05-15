library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity external_update is

  port (
    -- External Source: 

    UPDATE_E_I	        : in  std_logic;
    
    -- Clock Domain Board: (Fast Clock)
    CLK_F_I               : in  std_logic;
    RSTN                  : in  std_logic;
    PULSE_OUT             : out std_logic; -- 1 cycle pulse
    COUNT_P               : out std_logic_vector(31 downto 0); -- pulse counter
    COUNT_START           : in std_logic := '0';
    COUNT_RESET           : in std_logic := '0';
    DEBUG                 : out std_logic_vector(7 downto 0) -- update_sync and update old
  );
end;

architecture behavioral of external_update is

  signal update_e   : std_logic; -- input signal

  signal clk_f      : std_logic; -- clk of board frequency
  signal rst        : std_logic; 
  signal count      : integer :=0; -- count of pulse


  -- double flopping at clock domain crossing:
  signal update_meta : std_logic; -- metastable
  signal update_sync : std_logic; -- likely stable
 
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of update_meta: signal is "TRUE";
  attribute ASYNC_REG of update_sync: signal is "TRUE";
  
  signal update_z : std_logic ;
  signal pulse      : std_logic :='0'; 
  
begin

  update_e <= UPDATE_E_I;
  
  clk_f <= CLK_F_I;
  rst    <= not RSTN;

  
  

  -- double flop synchronization of update signal 
  -- synchronize request into board domain
  update_process : process(clk_f, rst)
  begin
    if (rst = '1') then
      update_meta <= '1';
      update_sync <= '1';
      update_z  <= '1';
    elsif (rising_edge(clk_f)) then
      update_meta <= update_e; --metastable
      update_sync <= update_meta; --likely stable
      update_z  <= update_sync; -- old signal
    end if;

  
  end process;


  --output occurs when rising edge

  pulse_process : process(clk_f, rst)
  begin
    if (rst = '1') then
      pulse <= '0';
    elsif (rising_edge(clk_f)) then
      if (update_sync = '1' and update_z = '0') then
        pulse <= '1';
      else
        pulse <= '0';
      end if;
         
    end if;

  
  end process;



  --count the pulse
  count_process : process(clk_f, rst)
  begin
    if (rst = '1') then
      count <= 0;
    elsif (rising_edge(clk_f)) then 
      if COUNT_RESET = '1' then
        count <= 0;
      elsif pulse = '1' and COUNT_START = '1' then
        if count = 100000000 - 1 then
          count <= 0;
        else
          count <= count + 1;
        end if;
      end if;
    end if;
  end process;





 

  --outputs
  PULSE_OUT <= pulse;
  COUNT_P <= std_logic_vector(to_signed(count ,32));
  DEBUG(0) <= update_sync;
  DEBUG(1) <= update_z;
  DEBUG(7 downto 2) <= (others => '0');






end;
