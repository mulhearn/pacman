library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity tx_buffer is
  port (
    S_AXIS_ACLK        : in std_logic;
    S_AXIS_ARESETN     : in std_logic;

    S_AXIS_TDATA       : in std_logic_vector(C_TX_AXIS_WIDTH-1 downto 0);      
    S_AXIS_TVALID      : in std_logic;
    S_AXIS_TREADY      : out std_logic;
    S_AXIS_TKEEP       : in std_logic_vector(C_TX_AXIS_WIDTH/8-1 downto 0);      
    S_AXIS_TLAST       : in std_logic;

    STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    DATA_O             : out uart_tx_data_array_t;
    VALID_O            : out std_logic_vector(C_NUM_UART-1 downto 0);
    READY_I            : in std_logic_vector(C_NUM_UART-1 downto 0)
  );
end;

architecture behavioral of tx_buffer is
  component axis_read is
    generic (
      constant C_AXIS_WIDTH  : integer  := C_TX_AXIS_WIDTH;
      constant C_AXIS_BEATS   : integer  := C_TX_AXIS_BEATS
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
  end component;

  signal clk       : std_logic;
  signal rst       : std_logic;

  signal tvalid    : std_logic;
  signal tready    : std_logic;
  
  signal pdata     : std_logic_vector(C_TX_AXIS_WIDTH*C_TX_AXIS_BEATS-1 downto 0);
  signal pvalid    : std_logic;
  signal pready    : std_logic;

  signal status    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  
  signal mask      : std_logic_vector(C_NUM_UART-1 downto 0);
  signal ovalid    : std_logic_vector(C_NUM_UART-1 downto 0);
  
  type state_type is (WAIT_STREAM, WAIT_TX);
  signal state : state_type := WAIT_STREAM;


begin
  ar0: axis_read port map (
    S_AXIS_ACLK     => S_AXIS_ACLK,    
    S_AXIS_ARESETN  => S_AXIS_ARESETN, 
    S_AXIS_TDATA    => S_AXIS_TDATA,   
    S_AXIS_TVALID   => tvalid,
    S_AXIS_TREADY   => tready,
    S_AXIS_TKEEP    => S_AXIS_TKEEP,   
    S_AXIS_TLAST    => S_AXIS_TLAST,   
    DATA_O          => pdata,
    VALID_O         => pvalid,
    READY_I         => pready
  );
  
  tvalid <= S_AXIS_TVALID;
  S_AXIS_TREADY <= tready;

  -- register pdata
  process(clk,rst)
  begin
    if (rst='1') then
      mask   <= (others => '0');
      DATA_O <= (others => (others => '0'));
    elsif (rising_edge(clk)) then
      mask <= pdata(C_NUM_UART-1 downto 0);
      for i in 0 to C_NUM_UART-1 loop
        DATA_O(i) <= pdata(C_TX_DATA_WIDTH*(i+3)-1 downto C_TX_DATA_WIDTH*(i+2));
      end loop;
    end if;    
  end process;

  VALID_O <= ovalid;
  process(clk,rst)
    function reductive_or (a_vector : std_logic_vector) return std_logic is
      variable r : std_logic := '0';
    begin
      for i in a_vector'range loop
        r := r or a_vector(i);
      end loop;
      return r;
    end function;    
  begin
    if (rst='1') then
      state  <= WAIT_STREAM;
      pready <= '0';
      ovalid <= (others => '0');
    elsif (rising_edge(clk)) then
      if (state = WAIT_STREAM) then
        pready <= '0';
        ovalid <= (others => '0');
        if (pvalid='1' and pready='0') then
          ovalid <= mask;
          state <= WAIT_TX;
        end if;
      else
        pready <= '0';
        for i in 0 to C_NUM_UART-1 loop
          if (READY_I(i) = '1') then
            ovalid(i) <= '0';
          end if;
        end loop;
        if (reductive_or(ovalid)='0') then
          pready <= '1';
          state <= WAIT_STREAM;
        end if;        
      end if;
    end if;
  end process;
  
  clk <= S_AXIS_ACLK;
  rst <= not S_AXIS_ARESETN;

  status(0) <= tready;
  status(1) <= tvalid;
  status(4) <= pready;
  status(5) <= pvalid;

  process(clk,rst)
  begin
    if (rst='1') then
      STATUS_O <= (others => '0');
    elsif (rising_edge(clk)) then
      STATUS_O <= status;
    end if;
  end process;
end;  

