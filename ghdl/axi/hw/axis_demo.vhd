library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
use work.common.all;

entity axis_demo is
  port (
    M_AXIS_ACLK         : in std_logic;
    M_AXIS_ARESETN      : in std_logic;      
    M_AXIS_TDATA        : out std_logic_vector(127 downto 0);      
    M_AXIS_TVALID       : out std_logic;
    M_AXIS_TREADY       : in std_logic;
    M_AXIS_TKEEP        : out std_logic_vector(3 downto 0);      
    M_AXIS_TLAST        : out std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK    : out  std_logic;
    
    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR   : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA   : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out  std_logic;

    REGA_I              : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    REGB_I              : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
end axis_demo;
     
architecture behaviour of axis_demo is
  component axis_write is
    port (
      M_AXIS_ACLK        : in std_logic;
      M_AXIS_ARESETN     : in std_logic;    
      M_AXIS_TDATA       : out std_logic_vector(127 downto 0);      
      M_AXIS_TVALID      : out std_logic;
      M_AXIS_TREADY      : in std_logic;
      M_AXIS_TKEEP       : out std_logic_vector(3 downto 0);      
      M_AXIS_TLAST       : out std_logic;      
      BUSY_O             : out std_logic;
      WEN_I              : in  std_logic;
      LAST_I             : in  std_logic;    
      DATA_I             : in  std_logic_vector(127 downto 0);
      DEBUG_O            : out std_logic_vector(7 downto 0)
    );  
  end component;

  signal clk      : std_logic;
  signal rst      : std_logic;  
  signal busy     : std_logic;
  signal wen      : std_logic := '0';
  signal last     : std_logic := '0';    
  signal idat     : std_logic_vector(127 downto 0) := (others => '0');


  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(15 downto 0) := (others => '0');
  signal rdata    : std_logic_vector(31 downto 0) := (others => '0');
  signal rack     : std_logic;

  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(15 downto 0) := (others => '0');
  signal wdata    : std_logic_vector(31 downto 0) := (others => '0');
  signal wack     : std_logic;

  signal config   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

begin
  uut: axis_write port map (
    M_AXIS_ACLK       => M_AXIS_ACLK,
    M_AXIS_ARESETN    => M_AXIS_ARESETN,
    M_AXIS_TDATA      => M_AXIS_TDATA,
    M_AXIS_TVALID     => M_AXIS_TVALID,
    M_AXIS_TREADY     => M_AXIS_TREADY,
    M_AXIS_TKEEP      => M_AXIS_TKEEP,
    M_AXIS_TLAST      => M_AXIS_TLAST,
    BUSY_O            => busy,
    WEN_I             => wen,
    LAST_I            => last,
    DATA_I            => idat    
  );  

  clk <= M_AXIS_ACLK;
  rst <= not M_AXIS_ARESETN;

  rupdate <= S_REGBUS_RB_RUPDATE;
  raddr   <= S_REGBUS_RB_RADDR;
  S_REGBUS_RB_RDATA    <= rdata;
  S_REGBUS_RB_RACK     <= rack;

  wupdate <= S_REGBUS_RB_WUPDATE;
  waddr   <= S_REGBUS_RB_WADDR;
  wdata   <= S_REGBUS_RB_WDATA;
  S_REGBUS_RB_WACK <= wack;

  process(clk)
    variable count : integer := 1;
  begin
    if (rst='1') then
      wen <= '0';
      idat <= (others => '0');
    elsif (rising_edge(clk)) then
      if ((busy = '1') or (config(0)='0')) then
        wen <= '0';
        idat <= (others => '0');
      else
        wen <= '1';
        idat <= std_logic_vector(to_unsigned(count, idat'length));
        if ((std_logic_vector(to_unsigned(count, 16)) and config(31 downto 16)) = x"0000") then
          last <= '1';
        else
          last <= '0';
        end if;
        count := count + 1;
      end if;
    end if;
  end process;

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
          if (reg=16#00#) then
            rdata <= REGA_I;
            rack  <= '1';
          elsif (reg=16#04#) then
            rdata <= REGB_I;
            rack  <= '1';
          elsif (reg=16#08#) then
            rdata <= config;
            rack  <= '1';
          elsif (reg=16#0C#) then
            rdata <= x"ABCD1234";
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
      wack <= '0';
    else
      if (rising_edge(clk)) then
        if (wupdate='0') then
          --rdata is registered until the next reset or update:
          wack <= '0';
        else
          reg   := to_integer(unsigned(waddr(7 downto 0)));          
          if (reg=16#08#) then
            config  <= wdata;
            wack    <= '1';
          else
            -- this is an error, invalid register
            wack  <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;


  
end behaviour;
        
