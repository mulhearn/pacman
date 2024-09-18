library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
use work.common.all;

entity regbus_demo is
  generic (
    constant C_DATA_WIDTH  : integer := C_RB_DATA_WIDTH;
    constant C_ADDR_WIDTH  : integer := C_RB_ADDR_WIDTH;
    constant C_REG_SCRA    : integer  := 16#0#;
    constant C_REG_SCRB    : integer  := 16#4#;
    constant C_REG_ROA     : integer  := 16#8#;
    constant C_REG_ROB     : integer  := 16#C#;
    constant C_VAL_ROA     : unsigned(31 downto 0)  := x"AAAAAAAA";
    constant C_VAL_ROB     : unsigned(31 downto 0)  := x"BBBBBBBB"
  );      
  
  port (
    S_AXI_ACLK         : in std_logic;
    S_AXI_ARESETN      : in std_logic;
    S_AXI_ARADDR       : in std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_AXI_ARPROT       : in std_logic_vector(2 downto 0) := (others => '0');                 
    S_AXI_ARVALID      : in std_logic;
    S_AXI_ARREADY      : out std_logic;    
    S_AXI_RDATA        : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP        : out std_logic_vector(1 downto 0);
    S_AXI_RVALID       : out std_logic;
    S_AXI_RREADY       : in std_logic;
    S_AXI_AWADDR       : in std_logic_vector(C_ADDR_WIDTH-1 downto 0);      
    S_AXI_AWPROT       : in std_logic_vector(2 downto 0) := (others => '0');                 
    S_AXI_AWVALID      : in std_logic;                                    
    S_AXI_AWREADY      : out std_logic;
    S_AXI_WDATA        : in std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    S_AXI_WSTRB        : in std_logic_vector((C_DATA_WIDTH/8)-1 downto 0) := (others => '0');                 
    S_AXI_WVALID       : in std_logic;                                    
    S_AXI_WREADY       : out std_logic;                                           
    S_AXI_BRESP        : out std_logic_vector(1 downto 0);
    S_AXI_BVALID       : out std_logic;
    S_AXI_BREADY       : in std_logic
    );
begin
  assert(C_ADDR_WIDTH>=8) severity failure; --assumed by test
end regbus_demo;
     
architecture behaviour of regbus_demo is
  component axil_to_regbus is
    generic(
      constant C_DATA_WIDTH : integer := C_RB_DATA_WIDTH;
      constant C_ADDR_WIDTH : integer := C_RB_ADDR_WIDTH
    );
    port (
      S_AXI_ACLK           : in std_logic;
      S_AXI_ARESETN        : in std_logic;
      S_AXI_ARADDR         : in std_logic_vector(C_ADDR_WIDTH-1 downto 0);
      S_AXI_ARPROT         : in std_logic_vector(2 downto 0) := (others => '0');                 
      S_AXI_ARVALID        : in std_logic;
      S_AXI_ARREADY        : out std_logic;    
      S_AXI_RDATA          : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP          : out std_logic_vector(1 downto 0);
      S_AXI_RVALID         : out std_logic;
      S_AXI_RREADY         : in std_logic;
      S_AXI_AWADDR         : in std_logic_vector(C_ADDR_WIDTH-1 downto 0);      
      S_AXI_AWPROT         : in std_logic_vector(2 downto 0) := (others => '0');                 
      S_AXI_AWVALID        : in std_logic;                                    
      S_AXI_AWREADY        : out std_logic;
      S_AXI_WDATA          : in std_logic_vector(C_DATA_WIDTH-1 downto 0);      
      S_AXI_WSTRB          : in std_logic_vector((C_DATA_WIDTH/8)-1 downto 0) := (others => '0');                 
      S_AXI_WVALID         : in std_logic;                                    
      S_AXI_WREADY         : out std_logic;                                           
      S_AXI_BRESP          : out std_logic_vector(1 downto 0);
      S_AXI_BVALID         : out std_logic;
      S_AXI_BREADY         : in std_logic;
      P_REGBUS_RB_RUPDATE  : out std_logic;
      P_REGBUS_RB_RADDR	   : out std_logic_vector(15 downto 0);
      P_REGBUS_RB_RDATA	   : in  std_logic_vector(31 downto 0);
      P_REGBUS_RB_RACK     : in std_logic;
      P_REGBUS_RB_WUPDATE  : out std_logic;
      P_REGBUS_RB_WADDR	   : out std_logic_vector(15 downto 0);
      P_REGBUS_RB_WDATA	   : out  std_logic_vector(31 downto 0);
      P_REGBUS_RB_WACK     : in std_logic
    );
  end component;

  signal clk      : std_logic;
  signal rst      : std_logic;

  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(15 downto 0) := (others => '0');
  signal rdata    : std_logic_vector(31 downto 0) := (others => '0');
  signal rack     : std_logic;
  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(15 downto 0) := (others => '0');
  signal wdata    : std_logic_vector(31 downto 0) := (others => '0');
  signal wack     : std_logic;
  

  signal scra    : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
  signal scrb    : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');

begin
  uut: axil_to_regbus port map (
    S_AXI_ACLK           =>  S_AXI_ACLK,     
    S_AXI_ARESETN        =>  S_AXI_ARESETN, 
    S_AXI_ARADDR         =>  S_AXI_ARADDR,  
    S_AXI_ARVALID        =>  S_AXI_ARVALID, 
    S_AXI_ARREADY        =>  S_AXI_ARREADY,  
    S_AXI_RDATA          =>  S_AXI_RDATA,   
    S_AXI_RVALID         =>  S_AXI_RVALID,  
    S_AXI_RREADY         =>  S_AXI_RREADY,  
    S_AXI_AWADDR         =>  S_AXI_AWADDR,  
    S_AXI_AWVALID        =>  S_AXI_AWVALID, 
    S_AXI_AWREADY        =>  S_AXI_AWREADY,  
    S_AXI_WDATA          =>  S_AXI_WDATA,   
    S_AXI_WVALID         =>  S_AXI_WVALID,  
    S_AXI_WREADY         =>  S_AXI_WREADY,  
    S_AXI_BVALID         =>  S_AXI_BVALID,  
    S_AXI_BREADY         =>  S_AXI_BREADY,  
    P_REGBUS_RB_RUPDATE  => rupdate,
    P_REGBUS_RB_RADDR    => raddr,  
    P_REGBUS_RB_RDATA    => rdata,
    P_REGBUS_RB_RACK     => rack,
    P_REGBUS_RB_WUPDATE  => wupdate,
    P_REGBUS_RB_WADDR    => waddr,  
    P_REGBUS_RB_WDATA    => wdata,
    P_REGBUS_RB_WACK     => wack    
  );


  clk <= S_AXI_ACLK;
  rst <= not S_AXI_ARESETN;

  -- Handle Read Request:
  process(clk)
    variable reg     : integer;
  begin  
    if (rst = '1') then
      rdata <= x"00000000";
      rack <= '0';
    else
      if (rising_edge(clk)) then
        if (rupdate='0') then
          --rdata is registered until the next reset or update:
          rack <= '0';
        else
          reg   := to_integer(unsigned(raddr(7 downto 0)));          
          if (reg=C_REG_SCRA) then
            rdata <= scra;
            rack  <= '1';
          elsif (reg=C_REG_SCRB) then
            rdata <= scrb;
            rack  <= '1';
          elsif (reg=C_REG_ROA) then
            rdata <= std_logic_vector(C_VAL_ROA);
            rack  <= '1';
          elsif (reg=C_REG_ROB) then
            rdata <= std_logic_vector(C_VAL_ROB);
            rack  <= '1';
          else
            -- this is an error, invalid register
            rdata <= x"EEEEEEEE";
            rack  <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;


  -- Handle Write Request:
  process(clk)
  variable reg     : integer;
  begin  
    if (rst = '1') then
      scra <= x"11111111";
      scrb <= x"00000000";
    else
      if (rising_edge(clk)) then
        if (wupdate='0') then
            wack  <= '0';          
        else
          reg   := to_integer(unsigned(waddr(7 downto 0)));          
          if (reg=C_REG_SCRA) then
            scra<= wdata;
            wack  <= '1';
          elsif (reg=C_REG_SCRB) then
            scrb<= wdata;
            wack  <= '1';
          else
            -- this is an error, invalid register
            wack  <= '0';
          end if;
        end if;
      end if;   
    end if;
  end process;



end behaviour;
        
