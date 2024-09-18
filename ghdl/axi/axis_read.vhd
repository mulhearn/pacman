library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_read is
  generic (
    -- the stream data width
    constant C_AXIS_WIDTH  : integer  := 32;
    -- the number of beats (valid & ready) per packet
    constant C_AXIS_BEATS   : integer  := 4
  );

  port (
    S_AXIS_ACLK        : in std_logic;
    S_AXIS_ARESETN     : in std_logic;

    S_AXIS_TDATA       : in std_logic_vector(C_AXIS_WIDTH-1 downto 0);      
    S_AXIS_TVALID      : in std_logic;
    S_AXIS_TREADY      : out std_logic;

    S_AXIS_TKEEP       : in std_logic_vector(C_AXIS_WIDTH/8-1 downto 0);      
    S_AXIS_TLAST       : in std_logic;
    
    DATA_O             : out std_logic_vector(C_AXIS_WIDTH*C_AXIS_BEATS-1 downto 0);      
    VAL_O              : out std_logic
  );
end;

architecture behavioral of axis_read is
  signal clk       : std_logic;
  signal rst       : std_logic;

  signal idat      : std_logic_vector(C_AXIS_WIDTH-1 downto 0);      
  signal val       : std_logic;
  signal last      : std_logic;

  signal odat      : std_logic_vector(C_AXIS_WIDTH*C_AXIS_BEATS-1 downto 0)  := (others => '0');
  signal done      : std_logic := '0';

begin
  clk <= S_AXIS_ACLK;
  rst <= not S_AXIS_ARESETN;

  -- we are always ready, buffering is done elsewhere.
  S_AXIS_TREADY <= '1';
  
  -- stream I/O
  idat <= S_AXIS_TDATA;
  val  <= S_AXIS_TVALID;
  last <= S_AXIS_TLAST;
  DATA_O <= odat;
  VAL_O  <= done;
  
  -- determine done:
  process(clk, rst)
  begin       
    if (rst='1') then
      done <= '0';
    elsif (rising_edge(clk)) then
      if (val='1') then
        if (last='1') then
          done <= '1';
        else
          done <= '0';
        end if;
      end if;
    end if;
  end process;

    -- determine done:
  process(clk, rst)
    variable beat : integer range 0 to C_AXIS_BEATS-1 := 0;
  begin       
    if (rst='1') then
      odat <= (others => '0');
    elsif (rising_edge(clk)) then
      if (val='1') then        
        odat(C_AXIS_WIDTH*(beat+1)-1 downto C_AXIS_WIDTH*beat) <= idat;        
        if (beat < C_AXIS_BEATS-1) then
          beat := beat + 1;
        end if;
        if (last='1') then          
          beat := 0;
        end if;
      end if;
    end if;
  end process;

end;  

