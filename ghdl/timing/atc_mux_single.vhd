library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;


entity atc_mux_single is
  generic (
    constant C_CONFIG_WIDTH     : integer := 32
  );

  port (
    UCLK	               : in  std_logic;
    RSTN	               : in  std_logic;


    --input signal
    UPDATE_LEMO_A_I	        : in  std_logic;
    UPDATE_LEMO_B_I	        : in  std_logic;
    UPDATE_POKE_C_I	        : in  std_logic;
    UPDATE_POKE_D_I	        : in  std_logic;

    CONFIG_ATC             : in std_logic_vector(C_CONFIG_WIDTH-1 downto 0);

    --output
    ATC_OUT                : out std_logic;
    ATC_COUNT              : out std_logic_vector(C_CONFIG_WIDTH-1 downto 0);
    
    COUNT_START           : in std_logic := '0';
    COUNT_RESET            : in std_logic := '0'
  );
end;

architecture behavioral of atc_mux_single is

  signal clk             : std_logic;
  signal rst             : std_logic;
  signal update_lemo_a   : std_logic;
  signal update_lemo_b   : std_logic;
  signal update_poke_c   : std_logic;
  signal update_poke_d   : std_logic;
  signal counter         : integer := 0 ; -- length extend of output
  signal update          : std_logic;

  signal config          :  std_logic_vector(C_CONFIG_WIDTH-1 downto 0);
  signal event_counter   :  integer;
begin
  clk            <= UCLK;
  rst           <= not RSTN;
  update_lemo_a <= UPDATE_LEMO_A_I;
  update_lemo_b <= UPDATE_LEMO_B_I;
  update_poke_c <= UPDATE_POKE_C_I;
  update_poke_d <= UPDATE_POKE_D_I;  
  config        <= CONFIG_ATC;


  
  
  update <= (config(0) and update_lemo_a) or (config(1) and update_lemo_b) or (config(2) and update_poke_c) or (config(3) and update_poke_d); 
  process(clk, rst)    
  begin
    if (rst = '1') then
      ATC_OUT<= config(4);
      counter <= 0;
    elsif (rising_edge(clk)) then
      if (update = '1') then
        counter <= to_integer(unsigned(config(31 downto 8)));  
      end if;  
      if (counter > 0) then
        ATC_OUT <= not config(4); 
        counter <= counter -1 ;
      else
        ATC_OUT <= config(4);
      end if;
    end if;
  end process;
  
  
  
  
 --process of counter
   process(clk, rst)
    variable act_count     : std_logic := '0'; 
  begin
    if (rst = '1') then
      act_count := '0';
      event_counter <= 0 ;
    elsif (rising_edge(clk)) then
 
      if COUNT_RESET = '1' then
        event_counter <= 0;
      else
        if (COUNT_START = '1') then
          if (counter > 0) then
            if (act_count = '0') then
              if (event_counter = 10000000 -1 ) then
                event_counter <=0;
              else
                event_counter  <= event_counter  + 1;
                act_count := '1';  -- Prevent further counts this activation
              end if;
            end if;  
          else
      	    act_count := '0'; 
          end if;     
        end if;
      end if;
    end if;   
  end process;

  ATC_COUNT <= std_logic_vector(to_signed(event_counter , 32));



end;
