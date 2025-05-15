library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity slow_pulse is
  generic (
    constant C_CONFIG_WIDTH     : integer := 32
  );

  port (
    -- Fast Clock Domain :
    CLK_F_I	                : in  std_logic;
    RSTN_F_I	              : in  std_logic;
    UPDATE_I	              : in  std_logic;
   
    BUSY_F_O	              : out std_logic;

    CONFIG_POL              : in  std_logic :='0';


    -- Slow Clock Domain : 
    CLK_S_I                 : in  std_logic;
    PULSE_O                 : out std_logic;
    DEBUG_O                 : out std_logic_vector(7 downto 0);

    --Count Output
    COUNT_O                 : out std_logic_vector(31 downto 0);
    COUNT_START             : in std_logic := '0';
    COUNT_RESET             : in std_logic := '0'
  );
end;

architecture behavioral of slow_pulse is
  -- Clock Domain A signals:
  signal clk_f           : std_logic;
  signal rst_f           : std_logic;
  signal update_in       : std_logic;
 
  signal busy_f          : std_logic;

  signal clk_s           : std_logic;

  signal request         : std_logic;
  signal ack             : std_logic;
  -- double flopping at clock domain crossing:
  signal request_meta : std_logic; -- metastable
  signal request_sync : std_logic; -- likely stable
  signal ack_meta     : std_logic; -- metastable
  signal ack_sync     : std_logic; -- likely stable

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of request_meta: signal is "TRUE";
  attribute ASYNC_REG of request_sync: signal is "TRUE";
  attribute ASYNC_REG of ack_meta: signal is "TRUE";
  attribute ASYNC_REG of ack_sync: signal is "TRUE";

  signal count_out            : integer :=0;
  signal counter              : integer ;

begin
  clk_f    <= CLK_F_I;
  rst_f    <= not RSTN_F_I;
  update_in <= UPDATE_I;
 


  BUSY_F_O <= busy_f;
  clk_s    <= CLK_S_I;
  
  
  DEBUG_O(0) <= request;
  DEBUG_O(1) <= request_sync;
  DEBUG_O(2) <= ack;
  DEBUG_O(3) <= ack_sync;
  
  -- double flop synchronization of ack signal (s to f)
  process(clk_f, rst_f)
  begin
    if (rst_f = '1') then
      ack_meta <= '0';
      ack_sync <= '0';
    elsif (rising_edge(clk_f)) then
      ack_meta <= ack;
      ack_sync <= ack_meta;
    end if;
  end process;

  -- double flop synchronization of update signal (f to s)
  process(clk_s, rst_f)
  begin
    if (rst_f = '1') then
      request_meta <= '0';
      request_sync <= '0';
    elsif (rising_edge(clk_s)) then
      request_meta <= request; --metastable
      request_sync <= request_meta; --likely stable
    end if;
  end process;
  

  -- fast clock domain  process
  process(clk_f, rst_f)
  begin
    if (rst_f = '1') then
      request <= '0';
      busy_f <= '0';
    elsif (rising_edge(clk_f)) then
      if (busy_f='0') then
        request <= '0';
        if ( update_in = '1') then
          request <= '1';
          busy_f <= '1';
        end if; 
      else
        if ((request='1') and (ack_sync='1')) then
          request <= '0';
        end if;
        if ((request='0') and (ack_sync='0')) then
          busy_f <= '0';
        end if;
      end if;
    end if;
  end process;







  -- Slow clock domain process
  process(clk_s, rst_f)
  begin
    if (rst_f = '1') then
      PULSE_O <= CONFIG_POL;
      ack <= '0'; 
      counter <=0;
    elsif (rising_edge(clk_s)) then
      if ((ack='0') and (request_sync='1')) then
        ack <= '1';
        counter <=1;
      end if;
      if(request_sync = '0') then
        ack <= '0';
      end if; 
      if (ack = '1' and counter = 1) then
        PULSE_O <= not CONFIG_POL; 
        counter <= counter - 1;             
      else
        PULSE_O <= CONFIG_POL;
      end if;
    end if;
  end process;

-- counter of output
process(clk_s, rst_f)
  begin
    if (rst_f = '1') then
      count_out <= 0 ; 
    elsif (rising_edge(clk_s)) then
      if COUNT_RESET = '1' then
        count_out <= 0;
      else
        if (COUNT_START = '1') then
          if (ack = '1' and counter = 1 ) then  
	    if (count_out = 10000000 -1 ) then
              count_out <=0;
            else
              count_out <= count_out + 1;
            end if;
          end if; 
        end if;  
      end if; 
    end if;
  end process;
  COUNT_O <= std_logic_vector(to_signed(count_out , 32));







end;
