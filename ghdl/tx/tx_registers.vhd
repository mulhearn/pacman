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
    -- clock and active-high reset
    CLK_I	        : in std_logic;
    RST_I	        : in std_logic;  -- ACTIVE LOW

    -- register bus (REGBUS) interface
    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RACK    : out std_logic;

    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out std_logic;

    -- status register from each UART TX channel
    UART_STATUS_I            : in uart_reg_array_t;
    -- configuration register for each UART TX channel
    UART_CONFIG_O            : out uart_reg_array_t;
    -- global status reported from the TX buffer
    BUFFER_STATUS_I    	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- look feature:
    LOOK_SELECT_O       : out std_logic_vector(C_SELECT_WIDTH-1 downto 0);
    LOOK_UART_DATA_I    : in std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
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
  signal look       : std_logic_vector(C_UART_DATA_WIDTH-1 downto 0);
  signal ustatus     : uart_reg_array_t;
  signal bstatus    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  -- registered controlled configuration per UART channel
  signal config   : uart_reg_array_t := (others => (others => '0'));
  -- zero all counters:
  signal zero_counters : std_logic := '0';

  -- UART status condition counts
  -- don't care about latency, so heavily registered:
  -- combintorial stage:
  signal starts_next  : uart_counter_array_t := (others => (others => '0'));
  signal beats_next   : uart_counter_array_t := (others => (others => '0'));
  -- first register stage:
  signal starts_rega  : uart_counter_array_t := (others => (others => '0'));
  signal beats_rega   : uart_counter_array_t := (others => (others => '0'));
  -- second register stage:
  signal starts_regb  : uart_counter_array_t := (others => (others => '0'));
  signal beats_regb   : uart_counter_array_t := (others => (others => '0'));

  signal look_select : std_logic_vector(C_SELECT_WIDTH-1 downto 0)  := (others => '0');


begin
  -- connect signals to inputs and outputs:
  clk <= CLK_I;
  rst <= RST_I;
  rupdate  <= S_REGBUS_RB_RUPDATE;
  raddr    <= S_REGBUS_RB_RADDR;
  S_REGBUS_RB_RDATA <= rdata;
  S_REGBUS_RB_RACK  <= rack;
  wupdate  <= S_REGBUS_RB_WUPDATE;
  waddr    <= S_REGBUS_RB_WADDR;
  wdata    <= S_REGBUS_RB_WDATA;
  S_REGBUS_RB_WACK	 <= wack;
  LOOK_SELECT_O           <= look_select;

  -- register input data:
  process(clk, rst)
  begin
    if (rst='1') then
      look       <= (others => '0');
      ustatus     <= (others => (others => '0'));
      bstatus    <= (others => '0');
    elsif (rising_edge(clk)) then
      look       <= LOOK_UART_DATA_I;
      ustatus     <= UART_STATUS_I;
      bstatus    <= BUFFER_STATUS_I;
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
                rdata <= ustatus(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_UART_CONFIG) then
                rdata <= config(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_UART_STARTS) then
                rdata <= (others => '0');
                rdata(C_COUNT_BITS-1 downto 0) <= std_logic_vector(starts_regb(chan));
                rack  <= '1';
              elsif (reg=C_ADDR_TX_UART_BEATS) then
                rdata <= (others => '0');
                rdata(C_COUNT_BITS-1 downto 0) <= std_logic_vector(beats_regb(chan));
                rack  <= '1';
              end if;
            -- global (to TX) registers:
            elsif (chan = 16#3F#) then
              if (reg=C_ADDR_TX_BUFFER_STATUS) then
                rdata <= bstatus;
                rack  <= '1';
              elsif (reg=C_ADDR_TX_LOOK_SELECT) then
                rdata <= (others => '0');
                rdata(C_SELECT_WIDTH-1 downto 0) <= look_select;
                rack  <= '1';
              elsif (reg=C_ADDR_TX_LOOK_UA) then
                rdata <= look(31 downto 0);
                rack  <= '1';
              elsif (reg=C_ADDR_TX_LOOK_UB) then
                rdata <= look(63 downto 32);
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
            elsif (reg=C_ADDR_TX_LOOK_SELECT) then
              look_select <= wdata(C_SELECT_WIDTH-1 downto 0);
              wack  <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  process(rst, ustatus, zero_counters, starts_rega, beats_rega)
    variable valid  : std_logic;
    variable ready  : std_logic;
    variable start  : std_logic;
  begin
    if (rst='1') or (zero_counters = '1') then
      starts_next   <= (others => (others => '0'));
      beats_next    <= (others => (others => '0'));
    else
      gen_next: for i in 0 to C_NUM_UART-1 loop
        -- extract status bits for clarity
        valid  := ustatus(i)(1);
        ready  := ustatus(i)(2);
        start  := ustatus(i)(3);

        -- starts count increments if starts=1
        if (start = '1') and (starts_rega(i) < C_COUNT_MAX) then
          starts_next(i) <= starts_rega(i) + 1;
        else
          starts_next(i) <= starts_rega(i);
        end if;

        -- beats count increments when valid=1 and ready=1:
        if (valid = '1') and (ready = '1') and (beats_rega(i) < C_COUNT_MAX) then
          beats_next(i) <= beats_rega(i) + 1;
        else
          beats_next(i) <= beats_rega(i);
        end if;
      end loop;
    end if;
  end process;

  -- registers for status counts:
  -- latency is not an issue, so there are two stages:
  process(clk, rst)
  begin
    if rst = '1' then
      starts_rega   <= (others => (others => '0'));
      beats_rega    <= (others => (others => '0'));

      starts_regb   <= (others => (others => '0'));
      beats_regb    <= (others => (others => '0'));
    elsif rising_edge(clk) then
      -- First register stage: next -> rega
      starts_rega   <= starts_next;
      beats_rega    <= beats_next;

      -- Second register stage: rega -> regb
      starts_regb   <= starts_rega;
      beats_regb    <= beats_rega;
    end if;
  end process;


end;
