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

    STATUS_I            : in uart_reg_array_t;
    LOOK_I              : in uart_tx_data_array_t;

    CONFIG_O            : out uart_reg_array_t;
    SEND_O              : out uart_tx_data_array_t;
    COMMAND_O           : out uart_command_array_t
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
  signal cmd      : uart_command_array_t := (others => (others => '0'));
  signal send     : uart_tx_data_array_t := (others => x"1111AAAA2222BBBB");
  
begin
  -- Clock and reset inputs:
  clk <= ACLK;
  rst <= not ARESETN;
  
  --REGBUS
  -- outputs:
  S_REGBUS_RB_RDATA	 <= rdata;
  S_REGBUS_RB_RACK	 <= rack;
  S_REGBUS_RB_WACK	 <= wack;
  -- inputs: (already registered at preceding stage)
  rupdate  <= S_REGBUS_RB_RUPDATE;
  raddr    <= S_REGBUS_RB_RADDR;
  wupdate  <= S_REGBUS_RB_WUPDATE;
  waddr    <= S_REGBUS_RB_WADDR;
  wdata    <= S_REGBUS_RB_WDATA;

  --Others Ports
  -- outputs
  CONFIG_O  <= config;
  SEND_O    <= send;
  COMMAND_O <= cmd;

  -- Handle Read Request:
  process(clk)
  variable chan    : integer;
  variable rx      : std_logic;
  variable uartn   : std_logic;
  variable reg     : integer;
  begin  
    if (rst = '1') then
      rdata <= x"00000000";
      rack <= '0';
    else
      if (rising_edge(clk)) then
        if (rupdate='0') then
          rdata <= x"00000000";
          rack <= '0';
        else
          -- alternative interpretation of scope and role as uart channels:
          chan  := to_integer(unsigned(raddr(15 downto 10)));
          rx    := raddr(9);
          uartn := raddr(8);
          reg   := to_integer(unsigned(raddr(7 downto 0)));          
          if ((chan < 40) and (rx='0') and (uartn='0')) then
            if (reg=C_ADDR_TX_STATUS) then
              rdata <= STATUS_I(chan);
              rack  <= '1';
            elsif (reg=C_ADDR_TX_CONFIG) then
              rdata <= config(chan);
              rack  <= '1';
            elsif (reg=C_ADDR_TX_SEND_C) then
              rdata <= send(chan)(31 downto 0);
              rack  <= '1';
            elsif (reg=C_ADDR_TX_SEND_D) then
              rdata <= send(chan)(63 downto 32);
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
            else
              -- this is an error, invalid register
              rdata <= x"EEEEEEEE";
              rack  <= '0';
            end if;
          else
            -- this is not an error, just a request outside our scope/role
            rdata <= x"00000000";
            rack  <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Handle Write Request:
  process(clk)
  variable chan       : integer;
  variable rx         : std_logic;
  variable uartn      : std_logic;
  variable reg        : integer;
  
  variable cmd_flag  : std_logic_vector(C_NUM_UART-1 downto 0);
  variable cmd_mask  : std_logic_vector(C_BYTE-1 downto 0);
  begin
    cmd_flag := (others => '0');
    cmd_mask := (others => '0');    

    if (rst = '1') then
      wack <= '0';
    else
      if (rising_edge(clk)) then
        if (wupdate='0') then
          wack <= '0';
        else
          -- alternative interpretation of scope and role as uart channels:
          chan  := to_integer(unsigned(waddr(15 downto 10)));
          rx    := waddr(9);
          uartn := waddr(8);
          reg   := to_integer(unsigned(waddr(7 downto 0)));          
          if ((chan < 40) and (rx='0') and (uartn='0')) then
            if (reg=C_ADDR_TX_CONFIG) then
              config(chan) <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_TX_SEND_C) then
              send(chan)(31 downto 0) <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_TX_SEND_D  ) then
              send(chan)(63 downto 32) <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_TX_COMMAND) then
              cmd_flag(chan) := '1';
              cmd_mask       := wdata(7 downto 0);
              wack <= '1';
            else
              -- this is an error, invalid register
              wack  <= '0';
            end if;
          else
            -- this is not an error, just a request outside our scope/role
            wack  <= '0';
          end if;
        end if;

        -- handle start and stop requests and clearing:
        for i in 0 to C_NUM_UART-1 loop
          if (cmd_flag(i)='1') then
            cmd(i) <= cmd_mask;
          else
            cmd(i) <= (others => '0');
          end if;
        end loop;
      end if;
    end if;
  end process;

end;  

