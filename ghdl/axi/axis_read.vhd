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
    VALID_O            : out std_logic;
    READY_I            : in std_logic
  );
end;

architecture behavioral of axis_read is
  signal clk       : std_logic;
  signal rst       : std_logic;

  signal tdata      : std_logic_vector(C_AXIS_WIDTH-1 downto 0);      
  signal tvalid     : std_logic;
  signal tready     : std_logic;
  signal tlast      : std_logic;

  signal pdata      : std_logic_vector(C_AXIS_WIDTH*C_AXIS_BEATS-1 downto 0)  := (others => '0');
  signal pvalid     : std_logic := '0';
  signal pready     : std_logic;
begin
  clk <= S_AXIS_ACLK;
  rst <= not S_AXIS_ARESETN;

  -- we are ready once parallel data is not valid:
  tready <= not pvalid;
  
  -- stream I/O
  -- (ignore TKEEP)
  tdata   <= S_AXIS_TDATA;
  tvalid  <= S_AXIS_TVALID;
  tlast <= S_AXIS_TLAST;
  S_AXIS_TREADY <= tready;
  
  DATA_O   <= pdata;
  VALID_O  <= pvalid;
  pready   <= READY_I;
  
  -- determine pvalid:
  process(clk, rst)
  begin       
    if (rst='1') then
      pvalid <= '0';
    elsif (rising_edge(clk)) then
      if ((pvalid='1') and (pready='1')) then
        assert(tready='0');
        pvalid <= '0';
      end if;
      
      if ((tready='1') and (tvalid='1')) then
        assert(pvalid = '0');
        if (tlast='1') then
          pvalid <= '1';
        end if;
      end if;
    end if;
  end process;


  process(clk, rst)
    variable beat : integer range 0 to C_AXIS_BEATS-1 := 0;
  begin       
    if (rst='1') then
      pdata <= (others => '0');
    elsif (rising_edge(clk)) then
      if ((tvalid='1') and (tready='1')) then        
        pdata(C_AXIS_WIDTH*(beat+1)-1 downto C_AXIS_WIDTH*beat) <= tdata;        
        if (beat < C_AXIS_BEATS-1) then
          beat := beat + 1;
        end if;
        if (tlast='1') then          
          beat := 0;
        end if;
      end if;
    end if;
  end process;

end;  

