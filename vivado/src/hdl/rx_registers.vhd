library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;

--
-- rx_registers:
--
-- This modules handles reading and writing the RX unit registers over
-- the REGBUS interface.  It counts uart channel conditions
-- (starts, beats, updates, and lost) from the UART status register
-- bits.  It also tracks the maximum number of words in the RX FIFO.
--
-- See register_map.vhd for registers addresses.
--
-- See PACMAN TRM for register descriptions.
--

entity rx_registers is
  port (
    -- clock and reset
    ACLK	        : in std_logic;
    ARESETN	        : in std_logic;

    -- register bus (REGBUS) interface
    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RACK    : out std_logic;

    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out std_logic;

    -- look buffer contains the most recent RX for each UART
    UART_LOOK_I         : in  uart_rx_data_array_t;
    -- status register from each UART TX channel
    UART_STATUS_I       : in  uart_reg_array_t;
    -- configuration register for each UART TX channel
    UART_CONFIG_O       : out uart_reg_array_t;
    -- heartbeat cycles
    HEARTBEAT_CONFIG_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- sync cycles
    ROLLOVER_CONFIG_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- global (to RX) status reported by RX buffer.
    BUFFER_STATUS_I     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- global (to RX) configuration
    BUFFER_CONFIG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- word count in the RX FIFO
    FIFO_COUNT_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
end;

architecture behavioral of rx_registers is
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

  -- output registers:
  signal uart_config           : uart_reg_array_t := (others => (others => '0'));
  signal heartbeat_config : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal rollover_config       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bconfig          : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  -- input data for registers:
  signal ulook       : uart_rx_data_array_t := (others => (others => '0'));
  signal ustatus     : uart_reg_array_t;
  signal bstatus    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal fifo_count : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  -- signal to set all counter / maximums to 0
  signal zero_counters : std_logic := '0';

  -- UART condition counts and FIFO high-water mark
  signal istarts  : uart_counter_array_t := (others => 0);
  signal ibeats   : uart_counter_array_t := (others => 0);
  signal iupdates : uart_counter_array_t := (others => 0);
  signal ilost    : uart_counter_array_t := (others => 0);
  signal fifo_max : unsigned(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

begin
  -- connect signals to inputs and outputs
  clk <= ACLK;
  rst <= not ARESETN;
  rupdate  <= S_REGBUS_RB_RUPDATE;
  raddr    <= S_REGBUS_RB_RADDR;
  S_REGBUS_RB_RDATA <= rdata;
  S_REGBUS_RB_RACK  <= rack;
  wupdate  <= S_REGBUS_RB_WUPDATE;
  waddr    <= S_REGBUS_RB_WADDR;
  wdata    <= S_REGBUS_RB_WDATA;
  S_REGBUS_RB_WACK <= wack;

  -- set output registers
  UART_CONFIG_O           <= uart_config;
  BUFFER_CONFIG_O    <= bconfig;
  HEARTBEAT_CONFIG_O <= heartbeat_config;
  ROLLOVER_CONFIG_O      <= rollover_config;

  -- register input data:
  -- disabling look register for now to free up registers
  process(clk, rst)
  begin
    if (rst='1') then
      --ulook       <= (others => (others => '0'));
      ustatus     <= (others => (others => '0'));
      bstatus    <= (others => '0');
      fifo_count <= (others => '0');
    elsif (rising_edge(clk)) then
      --ulook       <= UART_LOOK_I;
      ustatus     <= UART_STATUS_I;
      bstatus    <= BUFFER_STATUS_I;
      fifo_count <= FIFO_COUNT_I;
    end if;
  end process;

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
          if (scope=C_SCOPE_UPPER_RX) then
            rdata <= x"EEEEEEEE";
            rack  <= '0';
            -- UART channel registers
            if (chan < C_NUM_UART) then
              if (reg=C_ADDR_RX_UART_STATUS) then
                rdata <= ustatus(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_CONFIG) then
                rdata <= uart_config(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_LOOK_A) then
                rdata <= ulook(chan)(31 downto 0);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_LOOK_B) then
                rdata <= ulook(chan)(63 downto 32);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_LOOK_C) then
                rdata <= ulook(chan)(95 downto 64);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_LOOK_D) then
                rdata <= ulook(chan)(127 downto 96);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_CHAN) then
                rdata <= std_logic_vector(to_unsigned(chan, rdata'length));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_STARTS) then
                rdata <= std_logic_vector(to_unsigned(istarts(chan),C_RB_DATA_WIDTH));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_BEATS) then
                rdata <= std_logic_vector(to_unsigned(ibeats(chan),C_RB_DATA_WIDTH));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_UPDATES) then
                rdata <= std_logic_vector(to_unsigned(iupdates(chan),C_RB_DATA_WIDTH));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_LOST) then
                rdata <= std_logic_vector(to_unsigned(ilost(chan),C_RB_DATA_WIDTH));
                rack  <= '1';
              end if;
            -- global (to RX) registers)
            elsif (chan = 16#3F#) then
              if (reg=C_ADDR_RX_BUFFER_STATUS) then
                rdata <= bstatus;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_BUFFER_CONFIG) then
                rdata <= bconfig;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_FIFO_CNT) then
                rdata <= fifo_count;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_FIFO_MAX) then
                rdata <= std_logic_vector(fifo_max);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_HEARTBEAT_CONFIG) then
                rdata <= heartbeat_config;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_ROLLOVER_CONFIG) then
                rdata <= rollover_config;
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
      uart_config            <= (others => std_logic_vector(to_unsigned(C_DEFAULT_RX_UART_CONFIG, C_RB_DATA_WIDTH)));
      bconfig           <= std_logic_vector(to_unsigned(C_DEFAULT_RX_BUFFER_CONFIG, C_RB_DATA_WIDTH));
      heartbeat_config  <= std_logic_vector(to_unsigned(C_DEFAULT_HEARTBEAT_CONFIG, C_RB_DATA_WIDTH));
      rollover_config        <= std_logic_vector(to_unsigned(C_DEFAULT_ROLLOVER_CONFIG, C_RB_DATA_WIDTH));
      zero_counters <= '0';
    else
      if (rising_edge(clk)) then
        wack <= '0';
        zero_counters <= '0';
        if (wupdate='1') then
          scope := to_integer(unsigned(waddr(15 downto 14)));
          chan  := to_integer(unsigned(waddr(13 downto 8)));
          reg   := to_integer(unsigned(waddr(7 downto 0)));
          -- UART channel registers
          if ((scope=C_SCOPE_UPPER_RX) and (chan < C_NUM_UART)) then
            if (reg=C_ADDR_RX_UART_CONFIG) then
              uart_config(chan) <= wdata;
              wack  <= '1';
            end if;
          end if;
          -- broadcast (write to all UART channels)
          if ((scope=C_SCOPE_UPPER_RX) and (chan = 16#3B#)) then
            if (reg=C_ADDR_RX_UART_CONFIG) then
              for i in 0 to C_NUM_UART-1 loop
                uart_config(i) <= wdata;
              end loop;
              wack  <= '1';
            end if;
          end if;
          -- global (to RX) registers:
          if ((scope=C_SCOPE_UPPER_RX) and (chan = 16#3F#)) then
            if (reg=C_ADDR_RX_BUFFER_CONFIG) then
              bconfig <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_ZERO_CNTS) then
              zero_counters <= '1';
              wack  <= '1';
            elsif (reg=C_ADDR_RX_HEARTBEAT_CONFIG) then
              heartbeat_config <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_ROLLOVER_CONFIG) then
              rollover_config <= wdata;
              wack  <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Count RX conditions from status register, zero on reset or zero_counters signal.
  process(clk, rst)
    variable fifo_now : unsigned(31 downto 0) := x"00000000";
    variable busy   : std_logic := '0';
    variable valid  : std_logic := '0';
    variable ready  : std_logic := '0';
    variable start  : std_logic := '0';
    variable update : std_logic := '0';
    variable lost   : std_logic := '0';
  begin

    if (rst = '1') then
      istarts  <= (others => 0);
      ibeats   <= (others => 0);
      iupdates <= (others => 0);
      ilost    <= (others => 0);
      fifo_max <= (others => '0');
    elsif (rising_edge(clk)) then
      if (zero_counters = '1') then
        fifo_max <= (others => '0');
      else
        fifo_now := unsigned(fifo_count(31 downto 0));
        if (fifo_max < fifo_now) then
          fifo_max <= fifo_now;
        end if;
      end if;
      for i in 0 to C_NUM_UART-1 loop
        -- map status bits as written in rx_chan.vhd:
        busy   := ustatus(i)(0);
        valid  := ustatus(i)(1);
        ready  := ustatus(i)(2);
        start  := ustatus(i)(4);
        update := ustatus(i)(5);
        lost   := ustatus(i)(6);
        if (zero_counters = '1') then
          istarts  <= (others => 0);
          ibeats   <= (others => 0);
          iupdates <= (others => 0);
          ilost    <= (others => 0);
        else
          if (start = '1') then
            istarts(i) <= (istarts(i) + 1) mod C_COUNT_MAX;
          end if;
          if ((valid = '1') and (ready = '1')) then
            ibeats(i) <= (ibeats(i) + 1) mod C_COUNT_MAX;
          end if;
          if (update = '1') then
            iupdates(i) <= (iupdates(i) + 1) mod C_COUNT_MAX;
          end if;
          if (lost = '1') then
            ilost(i) <= (ilost(i) + 1) mod C_COUNT_MAX;
          end if;
        end if;
      end loop;
    end if;
  end process;


end;
