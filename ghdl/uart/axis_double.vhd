-- axis_double
--
-- A module that combines to read cycles from an incoming stream into one cycle
-- of an outgoing stream with twice the data width.  

-- This version waits for the output to be valid and ready before the next read
-- cycle begins, introducing a one tick unecessary latency but simplifying the
-- logic.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_double is      
  port (
    -- Incoming AXI stream interface:
    ACLK            : in  std_logic;
    ARESETN         : in  std_logic;
    S_AXIS_VALID    : in  std_logic;
    S_AXIS_DATA     : in  std_logic_vector(63 downto 0);
    S_AXIS_READY    : out std_logic;
    -- Outgoing AXI stream interface:
    M_AXIS_VALID    : out std_logic;
    M_AXIS_DATA     : out std_logic_vector(127 downto 0);
    M_AXIS_READY    : in  std_logic;
    -- debugging:
    DEBUG           : out std_logic_vector(7 downto 0) := (others => '0')
    );
end;
  
architecture behavioral of axis_double is
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal ival     : std_logic;
  signal idata    : std_logic_vector(63 downto 0);
  signal irdy     : std_logic;
  
  signal oval     : std_logic;
  signal ordy     : std_logic;

  signal vup      : std_logic;

  
begin
  -- combinatoric signals:
  clk <= ACLK;
  S_AXIS_READY <= irdy;
  M_AXIS_VALID <= oval;  
  DEBUG(0) <= vup;
  
  -- latch asynchronous reset on falling (opposite) edge so
  -- it arrives consistently at same rising edge everywhere.
  process(clk)
  begin
    if (falling_edge(clk)) then
      rst <= not ARESETN;
    end if;
  end process;
  
  -- register the inputs
  process(clk)
  begin
    if (rising_edge(clk)) then
      ival  <= S_AXIS_VALID;
      idata <= S_AXIS_DATA; 
      ordy  <= M_AXIS_READY;
    end if;
  end process;
  
  -- determine vup, vdn
  process(clk)
  begin  
    if (rst = '1') then
      vup  <= '0';
      oval <= '0';
      irdy <= '1';
    else
      if (rising_edge(clk)) then
        if ((ival = '1') and (irdy = '1')) then
          if (vup='0') then 
            M_AXIS_DATA(127 downto 64) <= idata;
            vup  <= '1';
            oval <= '0';
            irdy <= '1';
          else
            M_AXIS_DATA(63 downto 0) <= idata;
            vup  <= '1';
            oval <= '1';
            -- latency inducing simplication:
            irdy <= '0';
          end if;
        end if;       
        if (oval='1' and ordy='1') then
          vup  <= '0';
          oval <= '0';
          irdy <= '1';
          -- unnecessary but makes logic clearer:
          M_AXIS_DATA <= (others => '0');
        end if;
      end if;
    end if;
  end process;
end;  
