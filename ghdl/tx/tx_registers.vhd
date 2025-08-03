library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;

--
-- tx_registers:
--
-- This modules handles reading and writing the TX unit registers over
-- the REGBUS interface.  It also counts uart channel starts using the
-- status register bits.
--
-- See register_map.vhd for registers addresses.
--
-- See PACMAN TRM for register descriptions.
--

entity tx_registers is
  port (
    -- clock and reset
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;  -- ACTIVE LOW

    -- register bus (REGBUS) interface
    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RACK    : out std_logic;

    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out std_logic;

    -- look buffer contains the most recent TX for each UART
    UART_LOOK_I              : in uart_tx_data_array_t;
    -- status register from each UART TX channel
    UART_STATUS_I            : in uart_reg_array_t;
    -- configuration register for each UART TX channel
    UART_CONFIG_O            : out uart_reg_array_t;
    -- global status reported from the TX buffer
    BUFFER_STATUS_I    	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
end;

architecture behavioral of tx_registers is
  -- clock and reset:
  signal clk      : std_logic;
  signal rst      : std_logic;

  -- REGBUS signals:
  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal rdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal rack     : std_logic := '0';

  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal wdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal wack     : std_logic := '0';

  -- input data for registers:
  signal look       : uart_tx_data_array_t;
  signal status     : uart_reg_array_t;
  signal gstatus    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  -- registered controlled configuration per UART channel
  signal config   : uart_reg_array_t := (others => (others => '0'));
  -- zero all counters:
  signal zero_counters : std_logic := '0';
  -- count of TX starts:
  signal starts   : uart_reg_array_t := (others => (others => '0'));
  -- count of TX starts:
  signal beats    : uart_reg_array_t := (others => (others => '0'));


begin
  -- connect signals to inputs and outputs:
  clk <= ACLK;
  rst <= not ARESETN;
  rupdate  <= S_REGBUS_RB_RUPDATE;
  raddr    <= S_REGBUS_RB_RADDR;
  S_REGBUS_RB_RDATA <= rdata;
  S_REGBUS_RB_RACK  <= rack;
  wupdate  <= S_REGBUS_RB_WUPDATE;
  waddr    <= S_REGBUS_RB_WADDR;
  wdata    <= S_REGBUS_RB_WDATA;
  S_REGBUS_RB_WACK	 <= wack;


  -- register input data:
  process(clk, rst)
  begin
    if (rst='1') then
      look       <= (others => (others => '0'));
      status     <= (others => (others => '0'));
      gstatus    <= (others => '0');
    elsif (rising_edge(clk)) then
      look       <= UART_LOOK_I;
      status     <= UART_STATUS_I;
      gstatus    <= BUFFER_STATUS_I;
    end if;
  end process;

  -- set output registers:
  UART_CONFIG_O  <= config;

  -- Handle Read Request:
  -- 1) Read request are indicated via rupdate=1 with a valid address
  -- raddr
  -- 2) Check that the first two bits of MSB byte (scope) of wraddr
  -- matches this modules scope.
  -- 3) The next six bits form the UART channel.  Their are special channels for
  -- broadcast (write all UARTs) and global (not specific to a UART channel).
  -- 4) Check remaining two bytes for a match with a defined
  -- register
  -- 5) If a match is found, on next clock cycle, set corresponding
  -- data on rdata and rack=1
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
          if (scope=C_SCOPE_UPPER_TX) then
            rdata <= x"EEEEEEEE";
            rack  <= '0';
            -- UART channel registers:
            if (chan < C_NUM_UART) then
              if (reg=C_ADDR_TX_UART_STATUS) then
                rdata <= status(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_UART_CONFIG) then
                rdata <= config(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_UART_LOOK_C) then
                rdata <= look(chan)(31 downto 0);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_UART_LOOK_D) then
                rdata <= look(chan)(63 downto 32);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_UART_CHAN) then
                rdata <= std_logic_vector(to_unsigned(chan, rdata'length));
                rack  <= '1';
              elsif (reg=C_ADDR_TX_UART_STARTS) then
                rdata <= starts(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_UART_BEATS) then
                rdata <= beats(chan);
                rack  <= '1';
              end if;
            -- global (to TX) registers:
            elsif (chan = 16#3F#) then
              if (reg=C_ADDR_TX_BUFFER_STATUS) then
                rdata <= gstatus;
                rack  <= '1';
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Handle Write Request:
  -- 1) Write request are indicated via wupdate=1 with a valid address
  -- waddr
  -- 2) Check that the first two bits of MSB byte (scope) of wraddr
  -- matches this modules scope.
  -- 3) The next six bits form the UART channel.  Their are special channels for
  -- broadcast (write all UARTs) and global (not specific to a UART channel).
  -- 4) Check remaining two bytes for a match with a defined
  -- register
  -- 5) If a match is found, on next clock cycle, set corresponding
  -- data to the value of wdata and set wack=1

  process(clk, rst)
    variable scope   : integer range 0 to 3;
    variable chan    : integer range 0 to 16#3F#;
    variable reg     : integer range 0 to 16#FF#;
  begin
    if (rst = '1') then
      wack  <= '0';
      config            <= (others => std_logic_vector(to_unsigned(C_DEFAULT_TX_UART_CONFIG, C_RB_DATA_WIDTH)));
      zero_counters <= '0';
    else
      if (rising_edge(clk)) then
        wack <= '0';
        zero_counters <= '0';
        if (wupdate='1') then
          scope := to_integer(unsigned(waddr(15 downto 14)));
          chan  := to_integer(unsigned(waddr(13 downto 8)));
          reg   := to_integer(unsigned(waddr(7 downto 0)));
          -- UART channel registers:
          if ((scope=C_SCOPE_UPPER_TX) and (chan < C_NUM_UART)) then
            if (reg=C_ADDR_TX_UART_CONFIG) then
              config(chan) <= wdata;
              wack  <= '1';
            end if;
          end if;
          -- broadcast: write to all uart channels:
          if ((scope=0) and (chan = 16#3B#)) then
            if (reg=C_ADDR_TX_UART_CONFIG) then
              for i in 0 to C_NUM_UART-1 loop
                config(i) <= wdata;
              end loop;
              wack  <= '1';
            end if;
          end if;
          -- global (to TX) registers:
          if ((scope=0) and (chan = 16#3F#)) then
            if (reg=C_ADDR_TX_ZERO_CNTS) then
              zero_counters <= '1';
              wack  <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Count TX starts from status register, zero on reset or zero_counters signal.
  process(clk, rst)
    type uart_int_array_t is array (0 to C_NUM_UART-1) of integer range 0 to 16#FFFFFF#;
    variable istarts : uart_int_array_t := (others => 0);
    variable ibeats  : uart_int_array_t := (others => 0);
  begin
    if (rst = '1') then
      istarts := (others => 0);
      ibeats := (others => 0);
    else
      if (rising_edge(clk)) then
        for i in 0 to C_NUM_UART-1 loop
          if (zero_counters = '1') then
            istarts(i) := 0;
            ibeats(i) := 0;
          else
            if (status(i)(3) = '1') then
              istarts(i) := (istarts(i) + 1) mod 16#FFFFFF#;
            end if;
            if ((status(i)(1) = '1') and (status(i)(2) = '1')) then
              ibeats(i) := (ibeats(i) + 1) mod 16#FFFFFF#;
            end if;
          end if;
          starts(i) <= std_logic_vector(to_unsigned(istarts(i),starts(i)'length));
          beats(i) <= std_logic_vector(to_unsigned(ibeats(i),beats(i)'length));
        end loop;
      end if;
    end if;
  end process;
end;

