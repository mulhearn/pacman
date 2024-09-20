library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;

entity tx_registers is
  port (
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;

    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK    : out std_logic;
    
    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out std_logic;

    LOOK_I              : in uart_tx_data_array_t;
    STATUS_I            : in uart_reg_array_t;
    BSTATUS_I    	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    CONFIG_O            : out uart_reg_array_t := (others => (others => '0'));
    GFLAGS_O            : out std_logic_vector(C_TX_GFLAGS_WIDTH-1 downto 0) := (others => '0')
  );
end;

architecture behavioral of tx_registers is
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal rdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal rack     : std_logic := '0';
  
  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal wdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal wack     : std_logic := '0';

  -- registers
  signal config   : uart_reg_array_t := (others => std_logic_vector(to_unsigned(C_DEFAULT_CONFIG_TX, C_RB_DATA_WIDTH)));  
  signal gflags     : std_logic_vector(C_TX_GFLAGS_WIDTH-1 downto 0);

  signal zero_counters : std_logic := '0';
  signal starts   : uart_reg_array_t := (others => (others => '0'));  
  
begin
  -- Clock and reset inputs:
  clk <= ACLK;
  rst <= not ARESETN;
  
  --REGBUS read signals
  rupdate  <= S_REGBUS_RB_RUPDATE;
  raddr    <= S_REGBUS_RB_RADDR;
  S_REGBUS_RB_RDATA <= rdata;
  S_REGBUS_RB_RACK  <= rack;
  --REGBUS write signals
  wupdate  <= S_REGBUS_RB_WUPDATE;
  waddr    <= S_REGBUS_RB_WADDR;
  wdata    <= S_REGBUS_RB_WDATA;
  S_REGBUS_RB_WACK	 <= wack;
  
  -- registers
  CONFIG_O  <= config;
  GFLAGS_O  <= gflags;

  -- Handle Read Request:
  process(clk, rst)
    variable scope   : integer range 0 to 3;
    variable chan    : integer range 0 to 16#3F#;
    variable reg     : integer range 0 to 16#FF#;
  begin  
    if (rst = '1') then
      rack <= '0';
      rdata <= x"00000000";
    else
      if (rising_edge(clk)) then
        rack <= '0';
        if (rupdate='1') then
          scope := to_integer(unsigned(raddr(15 downto 14)));
          chan  := to_integer(unsigned(raddr(13 downto 8)));
          reg   := to_integer(unsigned(raddr(7 downto 0)));
          rdata <= x"00000000";
          if (scope=0) then
            rdata <= x"EEEEEEEE";
            rack  <= '0';
            if (chan < 40) then
              if (reg=C_ADDR_TX_STATUS) then
                rdata <= STATUS_I(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_CONFIG) then
                rdata <= config(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_LOOK_C) then
                rdata <= LOOK_I(chan)(31 downto 0);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_LOOK_D) then
                rdata <= LOOK_I(chan)(63 downto 32);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_NCHAN) then
                rdata <= std_logic_vector(to_unsigned(chan, rdata'length));
                rack  <= '1';
              elsif (reg=C_ADDR_TX_STARTS) then
                rdata <= starts(chan);
                rack  <= '1';
              end if;
            elsif (chan = 16#3F#) then
              if (reg=C_ADDR_TX_STATUS) then
                rdata <= BSTATUS_I;
                rack  <= '1';
              elsif (reg=C_ADDR_TX_GFLAGS) then
                rdata <= (others => '0');
                rdata(C_TX_GFLAGS_WIDTH-1 downto 0) <= gflags;
                rack  <= '1';
              end if;
            end if;
          end if;          
        end if;
      end if;
    end if;
  end process;

  -- Handle Write Request:
  process(clk, rst)
  variable scope   : integer range 0 to 3;
  variable chan    : integer range 0 to 16#3F#;
  variable reg     : integer range 0 to 16#FF#;
  begin  
    if (rst = '1') then
      wack  <= '0';
      zero_counters <= '0';
    else
      if (rising_edge(clk)) then
        wack <= '0';
        zero_counters <= '0';
        if (wupdate='1') then
          scope := to_integer(unsigned(waddr(15 downto 14)));
          chan  := to_integer(unsigned(waddr(13 downto 8)));
          reg   := to_integer(unsigned(waddr(7 downto 0)));
          if ((scope=0) and (chan < 40)) then
            if (reg=C_ADDR_TX_CONFIG) then
              config(chan) <= wdata;
              wack  <= '1';
            end if;
          end if;
          if ((scope=0) and (chan = 16#3B#)) then
            if (reg=C_ADDR_TX_CONFIG) then
              for i in 0 to C_NUM_UART-1 loop
                config(i) <= wdata;
              end loop;
              wack  <= '1';              
            end if;
          end if;
          if ((scope=0) and (chan = 16#3F#)) then
            if (reg=C_ADDR_TX_GFLAGS) then
              gflags <= wdata(C_TX_GFLAGS_WIDTH-1 downto 0);    
              wack  <= '1';
            elsif (reg=C_ADDR_TX_STARTS) then
              zero_counters <= '1';
              wack  <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  process(clk, rst)    
    type uart_int_array_t is array (0 to C_NUM_UART-1) of integer range 0 to 16#FFFFFF#;
    variable istarts : uart_int_array_t := (others => 0);
  begin
    if (rst = '1') then
       istarts := (others => 0);
    else
      if (rising_edge(clk)) then
        for i in 0 to C_NUM_UART-1 loop
          if (zero_counters = '1') then
            istarts(i) := 0;
          elsif (STATUS_I(i)(3) = '1') then
            istarts(i) := (istarts(i) + 1) mod 16#FFFFFF#;
          end if;          
          starts(i) <= std_logic_vector(to_unsigned(istarts(i),starts(i)'length));          
        end loop;
      end if;
    end if;
  end process;

  
end;  

