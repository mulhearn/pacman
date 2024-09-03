library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regbus_mux is
  generic (
    C_DATA_WIDTH  : integer  := 32;
    C_ADDR_WIDTH  : integer  := 16;
    N_PRIMARY     : integer  := 3
  );      
  port (
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;

    -- Secondary REGBUS:
    S_REGBUS_RB_RUPDATE  : in   std_logic;
    S_REGBUS_RB_RADDR	 : in   std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	 : out  std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK     : out  std_logic;
    
    S_REGBUS_RB_WUPDATE  : in   std_logic;
    S_REGBUS_RB_WADDR	 : in   std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	 : in   std_logic_vector(C_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK     : out  std_logic;

    -- Primary A REGBUS
    PA_REGBUS_RB_RUPDATE : out  std_logic;
    PA_REGBUS_RB_RADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    PA_REGBUS_RB_RDATA	 : in   std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    PA_REGBUS_RB_RACK    : in   std_logic;
    
    PA_REGBUS_RB_WUPDATE : out  std_logic;
    PA_REGBUS_RB_WADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    PA_REGBUS_RB_WDATA	 : out  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    PA_REGBUS_RB_WACK    : in   std_logic;

    -- Primary B REGBUS
    PB_REGBUS_RB_RUPDATE : out  std_logic;
    PB_REGBUS_RB_RADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    PB_REGBUS_RB_RDATA	 : in   std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    PB_REGBUS_RB_RACK    : in   std_logic;
    
    PB_REGBUS_RB_WUPDATE : out  std_logic;
    PB_REGBUS_RB_WADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    PB_REGBUS_RB_WDATA	 : out  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    PB_REGBUS_RB_WACK    : in   std_logic;

    -- Primary C REGBUS
    PC_REGBUS_RB_RUPDATE : out  std_logic;
    PC_REGBUS_RB_RADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    PC_REGBUS_RB_RDATA	 : in   std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    PC_REGBUS_RB_RACK    : in   std_logic;
    
    PC_REGBUS_RB_WUPDATE : out  std_logic;
    PC_REGBUS_RB_WADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    PC_REGBUS_RB_WDATA	 : out  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    PC_REGBUS_RB_WACK    : in   std_logic;

    -- Primary D REGBUS
    --PD_REGBUS_RB_RUPDATE : out  std_logic;
    --PD_REGBUS_RB_RADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    --PD_REGBUS_RB_RDATA	 : in   std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    --PD_REGBUS_RB_RACK    : in   std_logic;
    
    --PD_REGBUS_RB_WUPDATE : out  std_logic;
    --PD_REGBUS_RB_WADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    --PD_REGBUS_RB_WDATA	 : out  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    --PD_REGBUS_RB_WACK    : in   std_logic;

    -- Primary E REGBUS
    --PE_REGBUS_RB_RUPDATE : out  std_logic;
    --PE_REGBUS_RB_RADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    --PE_REGBUS_RB_RDATA	 : in   std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    --PE_REGBUS_RB_RACK    : in   std_logic;
    
    --PE_REGBUS_RB_WUPDATE : out  std_logic;
    --PE_REGBUS_RB_WADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    --PE_REGBUS_RB_WDATA	 : out  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    --PE_REGBUS_RB_WACK    : in   std_logic;

    -- Primary F REGBUS
    --PF_REGBUS_RB_RUPDATE : out  std_logic;
    --PF_REGBUS_RB_RADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    --PF_REGBUS_RB_RDATA	 : in   std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    --PF_REGBUS_RB_RACK    : in   std_logic;
    
    --PF_REGBUS_RB_WUPDATE : out  std_logic;
    --PF_REGBUS_RB_WADDR	 : out  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    --PF_REGBUS_RB_WDATA	 : out  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    --PF_REGBUS_RB_WACK    : in   std_logic;
    --
    DEBUG               : out  std_logic_vector(C_DATA_WIDTH-1 downto 0)
    );
begin
  assert C_ADDR_WIDTH>=8;
end;

architecture behavioral of regbus_mux is
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
  signal rdata    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal rack     : std_logic := '0';
  
  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(C_ADDR_WIDTH-1 downto 0);
  signal wdata    : std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal wack     : std_logic := '0';

  signal wacks    : std_logic_vector(N_PRIMARY-1 downto 0);
  signal racks    : std_logic_vector(N_PRIMARY-1 downto 0);

  type t_data_array is array (0 to N_PRIMARY-1) of std_logic_vector(C_DATA_WIDTH-1 downto 0);
  signal rdata_array : t_data_array;
  
  function reductive_or (a_vector : std_logic_vector) return std_logic is
    variable r : std_logic := '0';
  begin
    for i in a_vector'range loop
      r := r or a_vector(i);
    end loop;
    return r;
  end function;

  function mux (update : std_logic_vector; data_array : t_data_array) return std_logic_vector is
    variable data : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
  begin
    for i in update'range loop
      if (update(i) = '1') then
        data := data or data_array(i);
      end if;    
    end loop;
    return data;
  end function;
    
begin
  -- fan out inputs from secondary to the primaries:
  rupdate <= S_REGBUS_RB_RUPDATE;
  raddr   <= S_REGBUS_RB_RADDR;
  wupdate <= S_REGBUS_RB_WUPDATE;
  waddr   <= S_REGBUS_RB_WADDR;
  wdata   <= S_REGBUS_RB_WDATA;
  
  PA_REGBUS_RB_RUPDATE   <= rupdate;
  PA_REGBUS_RB_RADDR	 <= raddr;
  PA_REGBUS_RB_WUPDATE   <= wupdate;
  PA_REGBUS_RB_WADDR	 <= waddr;
  PA_REGBUS_RB_WDATA	 <= wdata;

  PB_REGBUS_RB_RUPDATE   <= rupdate;
  PB_REGBUS_RB_RADDR	 <= raddr;
  PB_REGBUS_RB_WUPDATE   <= wupdate;
  PB_REGBUS_RB_WADDR	 <= waddr;
  PB_REGBUS_RB_WDATA	 <= wdata;

  PC_REGBUS_RB_RUPDATE   <= rupdate;
  PC_REGBUS_RB_RADDR	 <= raddr;
  PC_REGBUS_RB_WUPDATE   <= wupdate;
  PC_REGBUS_RB_WADDR	 <= waddr;
  PC_REGBUS_RB_WDATA	 <= wdata;

  --PD_REGBUS_RB_RUPDATE   <= rupdate;
  --PD_REGBUS_RB_RADDR	 <= raddr;
  --PD_REGBUS_RB_WUPDATE   <= wupdate;
  --PD_REGBUS_RB_WADDR	 <= waddr;
  --PD_REGBUS_RB_WDATA	 <= wdata;

  --PE_REGBUS_RB_RUPDATE   <= rupdate;
  --PE_REGBUS_RB_RADDR	 <= raddr;
  --PE_REGBUS_RB_WUPDATE   <= wupdate;
  --PE_REGBUS_RB_WADDR	 <= waddr;
  --PE_REGBUS_RB_WDATA	 <= wdata;

  --PF_REGBUS_RB_RUPDATE   <= rupdate;
  --PF_REGBUS_RB_RADDR	 <= raddr;
  --PF_REGBUS_RB_WUPDATE   <= wupdate;
  --PF_REGBUS_RB_WADDR	 <= waddr;
  --PF_REGBUS_RB_WDATA	 <= wdata;

  -- MUX output from secondary to :
  S_REGBUS_RB_RDATA <= rdata;
  S_REGBUS_RB_RACK  <= rack;
  S_REGBUS_RB_WACK  <= wack;
  
  racks(0) <= PA_REGBUS_RB_RACK;
  racks(1) <= PB_REGBUS_RB_RACK;
  racks(2) <= PC_REGBUS_RB_RACK;
  --racks(3) <= PD_REGBUS_RB_RACK;
  --racks(4) <= PE_REGBUS_RB_RACK;
  --racks(5) <= PF_REGBUS_RB_RACK;

  wacks(0) <= PA_REGBUS_RB_WACK;
  wacks(1) <= PB_REGBUS_RB_WACK;
  wacks(2) <= PC_REGBUS_RB_WACK;
  --wacks(3) <= PD_REGBUS_RB_WACK;
  --wacks(4) <= PE_REGBUS_RB_WACK;
  --wacks(5) <= PF_REGBUS_RB_WACK;

  rdata_array(0) <= PA_REGBUS_RB_RDATA;
  rdata_array(1) <= PB_REGBUS_RB_RDATA;
  rdata_array(2) <= PC_REGBUS_RB_RDATA;
  --rdata_array(3) <= PD_REGBUS_RB_RDATA;
  --rdata_array(4) <= PE_REGBUS_RB_RDATA;
  --rdata_array(5) <= PF_REGBUS_RB_RDATA;

  rack  <= reductive_or(racks);
  wack  <= reductive_or(wacks);
  rdata <= mux(racks, rdata_array);

  clk <= ACLK;
    
  process(clk)
  begin
    if (falling_edge(clk)) then
      rst <= not ARESETN;
    end if;
  end process;

  --process(clk)
  --variable scope   : integer;
  --variable role    : integer;
  --variable reg     : integer;
  --begin  
  --if (rst = '1') then
       --
    --elsif (rising_edge(clk)) then
      --scope := to_integer(unsigned(waddr(15 downto 12)));
      --role  := to_integer(unsigned(waddr(11 downto 8)));
      --reg   := to_integer(unsigned(waddr(7 downto 0)));          
    --end if;
  --end process;
end;  

