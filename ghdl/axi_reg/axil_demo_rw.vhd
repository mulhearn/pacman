library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axil_demo_rw is
  generic (
    C_DATA_WIDTH  : integer  := 32;
    C_ADDR_WIDTH  : integer  := 8
    );
      
  port (
    S_AXI_ACLK	        : in std_logic;
    S_AXI_ARESETN	: in std_logic;
    S_AXI_ARADDR	: in std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
    S_AXI_ARVALID	: in std_logic;
    S_AXI_ARREADY	: out std_logic;    
    S_AXI_RDATA	        : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP	        : out std_logic_vector(1 downto 0);
    S_AXI_RVALID	: out std_logic;
    S_AXI_RREADY	: in std_logic;
    S_AXI_AWADDR	: in std_logic_vector(C_ADDR_WIDTH-1 downto 0);      
    S_AXI_AWPROT	: in std_logic_vector(2 downto 0);                 
    S_AXI_AWVALID	: in std_logic;                                    
    S_AXI_AWREADY	: out std_logic;
    S_AXI_WDATA	        : in std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    S_AXI_WSTRB	        : in std_logic_vector((C_DATA_WIDTH/8)-1 downto 0);   
    S_AXI_WVALID	: in std_logic;                                    
    S_AXI_WREADY	: out std_logic;                                           
    S_AXI_BRESP	        : out std_logic_vector(1 downto 0);
    S_AXI_BVALID	: out std_logic;
    S_AXI_BREADY	: in std_logic
      );
begin
  assert C_ADDR_WIDTH>=8;
end;

architecture behavioral of axil_demo_rw is
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal araddr   : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
  signal arready  : std_logic;
  signal arvalid  : std_logic;

  signal rdata    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal rready   : std_logic;
  signal rvalid	  : std_logic := '0';

  signal awaddr   : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
  signal awready  : std_logic := '0';
  signal awvalid  : std_logic;

  signal wdata    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal wready   : std_logic := '0';
  signal wvalid	  : std_logic;
  
  signal bvalid   : std_logic := '0';
  signal bready   : std_logic;

  signal rupdate  : std_logic := '0';
  signal wupdate  : std_logic := '0';

  -- register bank:
  signal rw0      : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
  signal rw1      : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
   
begin
  -- read signals:
  S_AXI_ARREADY <= arready;
  S_AXI_RDATA   <= rdata;
  S_AXI_RVALID  <= rvalid;
-- Fixed response:
  S_AXI_RRESP   <= (others => '0');

  -- write signals:
  S_AXI_AWREADY	<= awready;
  S_AXI_WREADY  <= wready;
  S_AXI_BVALID	<= bvalid;
-- Fixed response:
  S_AXI_BRESP	<= (others => '0');  

  clk <= S_AXI_ACLK;

  -- latch asynchronous reset on falling (opposite) edge so
  -- it arrives consistently at same rising edge everywhere.
  process(clk)
  begin
    if (falling_edge(clk)) then
      rst <= not S_AXI_ARESETN;
    end if;
  end process;
  
  -- latch our (not-ignored) inputs:
  process(clk)
  begin  
    if (rising_edge(clk)) then
      araddr  <= S_AXI_ARADDR;
      arvalid <= S_AXI_ARVALID;
      rready  <= S_AXI_RREADY;
      awaddr  <= S_AXI_AWADDR;
      awvalid <= S_AXI_ARVALID;
      wdata   <= S_AXI_WDATA;
      wvalid  <= S_AXI_RREADY;
      awaddr  <= S_AXI_AWADDR;
      awvalid <= S_AXI_AWVALID;
      wdata   <= S_AXI_WDATA;
      wvalid  <= S_AXI_WVALID;
      bready  <= S_AXI_BREADY;
    end if;
  end process;

  -- Simplistic Read: We will not assert ready until a previous read
  -- has completed.  This simplification limits throughput to 50% of
  -- maximum, but it doesn't require any fancy buffering.  
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

  -- Send data
  process(clk)
  variable lowaddr : std_logic_vector(7 downto 0);
  begin  
    if (rst = '1') then
      rdata <= (others => '0');
    else
      -- we update the read data on the request only (arready and arvalid)
      -- and latch it until the next request
      if (rising_edge(clk) and rupdate='1') then
        -- ignoring upper but could check they are zero
        lowaddr := araddr(7 downto 0);
        case lowaddr is 
          when x"00" =>
            rdata <= rw0;
          when x"04" =>
            rdata <= rw1;
          when x"08" =>
            rdata <= x"11111111";
          when x"0C" =>
            rdata <= x"22222222";   
          when x"10" =>
            rdata <= x"33333333";            
          when others =>
            rdata <= x"FFFFFFFF";
        end case;           
      end if;
    end if;
  end process;

  -- Simplistic Write:
  awready <= wready;
  wupdate <= awvalid and wvalid and (not wready) and (not bvalid);

  -- Determine wready:
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

  -- Receive data:
  process(clk)
  variable lowaddr : std_logic_vector(7 downto 0);    
  begin  
    if (rst = '1') then
      rw0 <= (others => '0');
      rw1 <= (others => '0');
    else
      if (rising_edge(clk) and wupdate='1') then
        lowaddr := awaddr(7 downto 0);
        case lowaddr is 
          when x"00" =>
            rw0 <= wdata;
          when x"04" =>
            rw1 <= wdata;
          when others =>
            --
        end case;           
      end if;
    end if;
  end process;


  

end;  

