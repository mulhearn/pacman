library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_write is
  generic (
    constant C_AXIS_WIDTH    : integer  := 32;
    constant C_DEBUG_WIDTH   : integer  := 8
  );

  port (
    M_AXIS_ACLK        : in std_logic;
    M_AXIS_ARESETN     : in std_logic;

    M_AXIS_TDATA       : out std_logic_vector(C_AXIS_WIDTH-1 downto 0);      
    M_AXIS_TVALID      : out std_logic;
    M_AXIS_TREADY      : in std_logic;

    M_AXIS_TKEEP       : out std_logic_vector(C_AXIS_WIDTH/8-1 downto 0);      
    M_AXIS_TLAST       : out std_logic;

    BUSY_O             : out std_logic;
    WEN_I              : in  std_logic;
    LAST_I             : in  std_logic;    
    DATA_I             : in  std_logic_vector(C_AXIS_WIDTH-1 downto 0);
    DEBUG_O            : out std_logic_vector(C_DEBUG_WIDTH-1 downto 0)
    );
end;

architecture behavioral of axis_write is
  signal clk       : std_logic;
  signal rst       : std_logic;

  signal odat     : std_logic_vector(C_AXIS_WIDTH-1 downto 0);      
  signal olast    : std_logic;    
  signal val      : std_logic := '0';
  signal rdy      : std_logic;
  
  signal busy     : std_logic := '0';
  signal wen      : std_logic;
  signal idat     : std_logic_vector(C_AXIS_WIDTH-1 downto 0);
  signal ilast    : std_logic;    
  signal debug    : std_logic_vector(C_DEBUG_WIDTH-1 downto 0) := (others => '0');

  
  signal mon_depth : std_logic_vector(1 downto 0) := (others => '0');
begin
  clk <= M_AXIS_ACLK;
  rst <= not M_AXIS_ARESETN;

  --constant output:
  M_AXIS_TKEEP <= (others => '1');

  -- stream I/O
  M_AXIS_TDATA  <= odat;
  M_AXIS_TLAST  <= olast;
  M_AXIS_TVALID <= val;
  rdy <= M_AXIS_TREADY;
  
  BUSY_O  <= busy;
  DEBUG_O <= debug;
  
  wen     <=  WEN_I;    
  idat    <=  DATA_I;
  ilast   <=  LAST_I;
  
  -- determine output data and valid state:
  process(clk, rst)
    variable depth : integer range 0 to 3 := 0;  
    type dbuf_t is array (0 to 2) of std_logic_vector (C_AXIS_WIDTH-1 downto 0);
    variable dbuf: dbuf_t := (others => (others => '0'));
    variable lbuf: std_logic_vector(2 downto 0) := (others => '0');
  begin
       
    if (rst='1') then
      depth := 0;
      dbuf   := (others => (others => '0'));
      lbuf   := (others => '0');
      odat  <= (others => '0');
      olast <= '0';
      val   <= '0';
      busy  <= '0';
      mon_depth <= (others => '0');
    elsif (rising_edge(clk)) then
      if (val='1' and rdy='1') then
        dbuf(0) := dbuf(1);
        dbuf(1) := dbuf(2);
        dbuf(2) := (others=>'0');
        lbuf(0) := lbuf(1);
        lbuf(1) := lbuf(2);
        lbuf(2) := '0';
        depth := depth - 1;
      end if;
      if ((wen='1') and (depth<3)) then
        dbuf(depth) := idat;
        lbuf(depth) := ilast;
        depth := depth+1;
      end if;
      odat      <= dbuf(0);
      olast     <= lbuf(0);
      if (depth>0) then
        val <= '1';
      else
        val <= '0';
      end if;
      -- valid data will not be presented the first cycle that busy is deasserted,
      -- leading to the hysteresis below (busy toggles at depth=2)
      if (busy = '0') and (depth > 1) then
        busy <= '1';
      end if;
      if (busy = '1') and (depth < 3) then
        busy <= '0';
      end if;
      mon_depth <= std_logic_vector(to_unsigned(depth, mon_depth'length));
      
    end if;
  end process;

  debug(1 downto 0) <= mon_depth;
  
end;  

