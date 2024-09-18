library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
use work.common.all;

entity axis_read_demo is
  generic (
    constant C_AXIS_WIDTH  : integer  := C_TX_AXIS_WIDTH;
    constant C_AXIS_BEATS  : integer  := C_TX_AXIS_BEATS;
    constant C_ADDR_WIDTH  : integer  := C_RB_ADDR_WIDTH;
    constant C_DATA_WIDTH  : integer  := C_RB_DATA_WIDTH
  );
  port (
    S_AXIS_ACLK        : in std_logic;
    S_AXIS_ARESETN     : in std_logic;
    S_AXIS_TDATA       : in std_logic_vector(511 downto 0);      
    S_AXIS_TVALID      : in std_logic;
    S_AXIS_TREADY      : out std_logic;
    S_AXIS_TKEEP       : in std_logic_vector(63 downto 0);      
    S_AXIS_TLAST       : in std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR   : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA   : out std_logic_vector(C_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK    : out  std_logic;
    
    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR   : in  std_logic_vector(C_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA   : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out  std_logic
  );  
end axis_read_demo;
     
architecture behaviour of axis_read_demo is
  component axis_read is
    generic (
      constant C_AXIS_WIDTH  : integer  := C_AXIS_WIDTH;
      constant C_AXIS_BEATS  : integer  := C_AXIS_BEATS
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
  
  signal odat     : std_logic_vector(C_AXIS_WIDTH*C_AXIS_BEATS-1 downto 0);
  signal oval     : std_logic; 

  signal stat     : std_logic_vector(C_DATA_WIDTH-1 downto 0) := (others => '0');
begin
  uut: axis_read port map (
    S_AXIS_ACLK     => S_AXIS_ACLK,
    S_AXIS_ARESETN  => S_AXIS_ARESETN,
    S_AXIS_TDATA    => S_AXIS_TDATA,
    S_AXIS_TVALID   => S_AXIS_TVALID,
    S_AXIS_TREADY   => S_AXIS_TREADY,
    S_AXIS_TKEEP    => S_AXIS_TKEEP,
    S_AXIS_TLAST    => S_AXIS_TLAST,
    DATA_O          => odat,
    VAL_O           => oval
  );
  
  clk <= S_AXIS_ACLK;
  rst <= not S_AXIS_ARESETN;

  rupdate <= S_REGBUS_RB_RUPDATE;
  raddr   <= S_REGBUS_RB_RADDR;
  S_REGBUS_RB_RDATA    <= rdata;
  S_REGBUS_RB_RACK     <= rack;

  wupdate <= S_REGBUS_RB_WUPDATE;
  waddr   <= S_REGBUS_RB_WADDR;
  wdata   <= S_REGBUS_RB_WDATA;
  S_REGBUS_RB_WACK <= wack;


  stat(0) <= oval;
  stat(C_DATA_WIDTH-1 downto 1) <= (others => '0');
  
  -- Handle Read Request:
  process(clk)
    variable reg  : integer;
    variable word : integer;
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
          reg := to_integer(unsigned(raddr(11 downto 0)));
          if (reg < 16#200#) then
            word := to_integer(unsigned(raddr(8 downto 2)));
            if (word < 80) then
              rdata <= odat((word+1)*C_DATA_WIDTH-1 downto word*C_DATA_WIDTH);
              rack  <= '1';
            else
              rdata <= x"EEEEEEEE";
              rack  <= '0';
            end if;
          elsif (reg = 16#200#) then
            rdata <= stat;
            rack  <= '1';
          else
            rdata <= x"EEEEEEEE";
            rack  <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- No Register Writes:
  wack <= '0';

  

  
end behaviour;
        
