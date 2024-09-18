library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_to_regbus is
  generic (
    constant C_ADDR_WIDTH : integer := 16;
    constant C_DATA_WIDTH : integer := 32
  );
  port (
    S_AXI_ACLK           : in  std_logic;
    S_AXI_ARESETN        : in  std_logic;
    S_AXI_ARADDR         : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT         : in  std_logic_vector(2 downto 0) := (others => '0');                 
    S_AXI_ARVALID        : in  std_logic;
    S_AXI_ARREADY        : out std_logic;    
    S_AXI_RDATA          : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP          : out std_logic_vector(1 downto 0);
    S_AXI_RVALID         : out std_logic;
    S_AXI_RREADY         : in  std_logic;
    S_AXI_AWADDR         : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);      
    S_AXI_AWPROT         : in  std_logic_vector(2 downto 0) := (others => '0');                 
    S_AXI_AWVALID        : in  std_logic;                                    
    S_AXI_AWREADY        : out std_logic;
    S_AXI_WDATA          : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    S_AXI_WSTRB          : in  std_logic_vector(C_DATA_WIDTH/8-1 downto 0) := (others => '0');                 
    S_AXI_WVALID         : in  std_logic;                                    
    S_AXI_WREADY         : out std_logic;                                           
    S_AXI_BRESP          : out std_logic_vector(1 downto 0);
    S_AXI_BVALID         : out std_logic;
    S_AXI_BREADY         : in  std_logic;
    
    P_REGBUS_RB_RUPDATE  : out std_logic;
    P_REGBUS_RB_RADDR    : out std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    P_REGBUS_RB_RDATA    : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    P_REGBUS_RB_RACK     : in  std_logic;
    
    P_REGBUS_RB_WUPDATE  : out std_logic;
    P_REGBUS_RB_WADDR    : out std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    P_REGBUS_RB_WDATA    : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
    P_REGBUS_RB_WACK     : in  std_logic
    );
end;

architecture behavioral of axil_to_regbus is
  signal clk       : std_logic;
  signal rst       : std_logic;

  signal araddr    : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
  signal arready   : std_logic;
  signal arvalid   : std_logic;

  signal rdata     : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal rready    : std_logic;
  signal rvalid    : std_logic := '0';

  signal awaddr    : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
  signal awready   : std_logic := '0';
  signal awvalid   : std_logic;

  signal wdata     : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal wready    : std_logic := '0';
  signal wvalid    : std_logic;
  
  signal bvalid    : std_logic := '0';
  signal bready    : std_logic;

  signal rupdate   : std_logic := '0';
  signal wupdate   : std_logic := '0';

  signal rupdate_z : std_logic := '0';

  
begin
  -- read signals:
  S_AXI_ARREADY  <= arready;
  S_AXI_RVALID   <= rvalid;
-- Fixed response:
  S_AXI_RRESP    <= (others => '0');

  -- write signals:
  S_AXI_AWREADY  <= awready;
  S_AXI_WREADY   <= wready;
  S_AXI_BVALID   <= bvalid;
-- Fixed response:
  S_AXI_BRESP <= (others => '0');  

  clk <= S_AXI_ACLK;
  rst <= not S_AXI_ARESETN;
  
  P_REGBUS_RB_RUPDATE <= rupdate;
  P_REGBUS_RB_WUPDATE <= wupdate;  
  P_REGBUS_RB_RADDR   <= araddr;
  P_REGBUS_RB_WADDR   <= awaddr;
  P_REGBUS_RB_WDATA   <= wdata;

  S_AXI_RDATA   <= rdata;
  process(rvalid, P_REGBUS_RB_RDATA)
  begin
    if (rvalid='1') then
      rdata <= P_REGBUS_RB_RDATA;
    else
      rdata <= (others => '0');
    end if;
  end process;
    
  process(clk)
  begin  
    if (rising_edge(clk)) then
      rupdate_z <= rupdate;
    end if;   
  end process;
  
  -- register our (not-ignored) inputs:
  process(clk)
  begin  
    if (rising_edge(clk)) then
      araddr  <= S_AXI_ARADDR;
      arvalid <= S_AXI_ARVALID;
      rready  <= S_AXI_RREADY;
      awaddr  <= S_AXI_AWADDR;
      awvalid <= S_AXI_AWVALID;
      wdata   <= S_AXI_WDATA;
      wvalid  <= S_AXI_WVALID;
      bready  <= S_AXI_BREADY;
    end if;
  end process;

  -- Simplistic Read: We will not assert ready until a previous read
  -- has completed.  This simplification limits throughput to 50% of
  -- maximum (two clock cycles per read), but it doesn't require any
  -- buffering.
  arready <= not rvalid;  
  rupdate <= arready and arvalid;
  -- Determine rvalid:
  process(clk)
  begin  
    if (rst = '1') then
      rvalid  <= '0';
    else
      if (rising_edge(clk)) then
        -- rvalid goes high for (arready and arvalid) and then stays high until rready:
        rvalid  <= rupdate or (rvalid and not rready) ;        
      end if;
    end if;
  end process;

  -- Simplistic Write:
  -- We assert awready and wready together, after awvalid and wvalid
  -- have been asserted.
  --
  -- AXI: "A (primary) is not permitted to wait until TREADY is
  -- asserted before asserting TVALID. Once TVALID is asserted it must
  -- remain asserted until the handshake occurs."
  --
  -- This simplification limits throughput to 33% of maximum (three
  -- clock cycles per read), but it doesn't require any buffering.
  --
  awready <= wready;
  -- three clock cycle version:
  wupdate <= awvalid and wvalid and (not wready) and (not bvalid);
  -- this seemingly valid version uses two clock cycles per read by
  -- treating (bvalid and bready) as equivalent to (not bvalid).  It
  -- works at the testbench but hangs the Vivado AXI-Lite driver:
  -- wupdate <= awvalid and wvalid and (not wready) and ((not bvalid)
  -- or (bvalid and bready));
  process(clk)
  variable lowaddr : std_logic_vector(7 downto 0);    
  begin  
    if (rst = '1') then
      wready  <= '0';
      bvalid  <= '0';
    else
      if (rising_edge(clk)) then
        wready  <= wupdate;
        bvalid <= wready or (bvalid and not bready);
      end if;
    end if;
  end process;
end;  

