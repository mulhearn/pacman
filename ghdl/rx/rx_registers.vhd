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
    -- clock and active-high reset
    CLK_I	        : in std_logic;
    RST_I	        : in std_logic;

    -- register bus (REGBUS) interface
    S_REGBUS_RB_RUPDATE : in  std_logic;
    S_REGBUS_RB_RADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	: out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RACK    : out std_logic;

    S_REGBUS_RB_WUPDATE : in  std_logic;
    S_REGBUS_RB_WADDR	: in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	: in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK    : out std_logic;

    -- UART registers (inputs):
    -- status register from each UART TX channel
    UART_STATUS_I       : in  uart_reg_array_t;

    -- UART registers (outputs):
    -- configuration register for each UART TX channel
    UART_CONFIG_O       : out uart_reg_array_t;
    -- header register for each UART TX channel
    UART_CHAN_O         : out uart_small_array_t;

    -- Buffer registers (inputs):
    -- RX buffer status reported by RX buffer.
    BUFFER_STATUS_I     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- word count in the RX FIFO
    FIFO_COUNT_I        : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- Buffer registers (outputs):
    -- buffer  configuration
    BUFFER_CONFIG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    BUFFER_ENABLES_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- PACMAN ID
    PACMAN_O            : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- heartbeat config
    HEARTBEAT_CONFIG_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- sync config
    ROLLOVER_CONFIG_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    -- word type LUT mapping 2-bit packet descriptor to an 8-bit header field:
    WORD_TYPE_LUT_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- headers for additional non-UART words:
    HEARTBEAT_HEADER_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    ROLLOVER_HEADER_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    EOP_HEADER_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    -- look feature:
    LOOK_SELECT_O       : out std_logic_vector(C_SELECT_WIDTH-1 downto 0);
    LOOK_UART_DATA_I    : in std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
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
  signal uart_config      : uart_reg_array_t := (others => (others => '0'));
  signal uart_chan        : uart_small_array_t := (others => (others => '0'));
  -- Most singletons are all left as full 32-bit registers for now, so
  -- that adjusting configuration fields does not require changes
  -- here, but note that, as a result, unused bits appear in read.
  signal heartbeat_config : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal rollover_config  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal bconfig          : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal benables         : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal pacman           : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal wlut             : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal heartbeat_header : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal rollover_header  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal eop_header       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal look_select      : std_logic_vector(C_SELECT_WIDTH-1 downto 0)  := (others => '0');

  -- input data for registers:
  signal ustatus    : uart_reg_array_t  := (others => (others => '0'));
  signal bstatus    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal fifo_count : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  -- signal to set all counter / maximums to 0
  signal zero_counters : std_logic := '0';

  -- UART condition counts and FIFO high-water mark
  -- don't care about latency, so heavily registered:
  -- combintorial stage:
  signal starts_next  : uart_counter_array_t := (others => (others => '0'));
  signal beats_next   : uart_counter_array_t := (others => (others => '0'));
  signal updates_next : uart_counter_array_t := (others => (others => '0'));
  signal lost_next    : uart_counter_array_t := (others => (others => '0'));
  signal fifo_max_next : unsigned(C_RB_DATA_WIDTH-1 downto 0);
  -- first register stage:
  signal starts_rega  : uart_counter_array_t := (others => (others => '0'));
  signal beats_rega   : uart_counter_array_t := (others => (others => '0'));
  signal updates_rega : uart_counter_array_t := (others => (others => '0'));
  signal lost_rega    : uart_counter_array_t := (others => (others => '0'));
  signal fifo_max_rega : unsigned(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  -- second register stage:
  signal starts_regb  : uart_counter_array_t := (others => (others => '0'));
  signal beats_regb   : uart_counter_array_t := (others => (others => '0'));
  signal updates_regb : uart_counter_array_t := (others => (others => '0'));
  signal lost_regb    : uart_counter_array_t := (others => (others => '0'));
  signal fifo_max_regb : unsigned(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  function init_chan_array return uart_small_array_t is
    variable tmp : uart_small_array_t;
  begin
    for i in tmp'range loop
      tmp(i) := std_logic_vector(to_unsigned(i+1, 16));
    end loop;
    return tmp;
  end function;

  constant init_chan : uart_small_array_t := init_chan_array;

begin
  -- connect signals to inputs and outputs
  clk <= CLK_I;
  rst <= RST_I;
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
  UART_CHAN_O             <= uart_chan;
  BUFFER_CONFIG_O         <= bconfig;
  BUFFER_ENABLES_O        <= benables;
  PACMAN_O                <= pacman;
  HEARTBEAT_CONFIG_O      <= heartbeat_config;
  ROLLOVER_CONFIG_O       <= rollover_config;
  WORD_TYPE_LUT_O         <= wlut;
  LOOK_SELECT_O           <= look_select;

  -- splice PACMAN ID field into the headers:
  HEARTBEAT_HEADER_O(7 downto 0)   <= heartbeat_header(7 downto 0);
  HEARTBEAT_HEADER_O(15 downto 8)  <= pacman(7 downto 0);
  HEARTBEAT_HEADER_O(31 downto 16) <= heartbeat_header(31 downto 16);

  ROLLOVER_HEADER_O(7 downto 0)    <= rollover_header(7 downto 0);
  ROLLOVER_HEADER_O(15 downto 8)   <= pacman(7 downto 0);
  ROLLOVER_HEADER_O(31 downto 16)  <= rollover_header(31 downto 16);

  EOP_HEADER_O(7 downto 0)         <= eop_header(7 downto 0);
  EOP_HEADER_O(15 downto 8)        <= pacman(7 downto 0);
  EOP_HEADER_O(31 downto 16)       <= eop_header(31 downto 16);
  -- register input data:
  process(clk, rst)
  begin
    if (rst='1') then
      ustatus     <= (others => (others => '0'));
      bstatus    <= (others => '0');
      fifo_count <= (others => '0');
    elsif (rising_edge(clk)) then
      ustatus    <= UART_STATUS_I;
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
              elsif (reg=C_ADDR_RX_UART_CHAN) then
                rdata <= (others => '0');
                rdata(15 downto 0) <= uart_chan(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_STARTS) then
                rdata <= (others => '0');
                rdata(C_COUNT_BITS-1 downto 0) <= std_logic_vector(starts_regb(chan));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_BEATS) then
                rdata <= (others => '0');
                rdata(C_COUNT_BITS-1 downto 0) <= std_logic_vector(beats_regb(chan));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_UPDATES) then
                rdata <= (others => '0');
                rdata(C_COUNT_BITS-1 downto 0) <= std_logic_vector(updates_regb(chan));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UART_LOST) then
                rdata <= (others => '0');
                rdata(C_COUNT_BITS-1 downto 0) <= std_logic_vector(lost_regb(chan));
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
              elsif (reg=C_ADDR_RX_BUFFER_ENABLES) then
                rdata <= benables;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_PACMAN) then
                rdata <= pacman;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_WORD_TYPE_LUT) then
                rdata <= wlut;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_FIFO_CNT) then
                rdata <= fifo_count;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_FIFO_MAX) then
                rdata <= std_logic_vector(fifo_max_regb);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_HEARTBEAT_CONFIG) then
                rdata <= heartbeat_config;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_ROLLOVER_CONFIG) then
                rdata <= rollover_config;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_HEARTBEAT_HEADER) then
                rdata <= heartbeat_header;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_ROLLOVER_HEADER) then
                rdata <= rollover_header;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_EOP_HEADER) then
                rdata <= eop_header;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_LOOK_SELECT) then
                rdata <= (others => '0');
                rdata(C_SELECT_WIDTH-1 downto 0) <= look_select;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_LOOK_UA) then
                rdata <= LOOK_UART_DATA_I(31 downto 0);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_LOOK_UB) then
                rdata <= LOOK_UART_DATA_I(63 downto 32);
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
      uart_chan              <= init_chan;
      pacman                 <= (others => '0');
      bconfig                <= std_logic_vector(to_unsigned(C_DEFAULT_RX_BUFFER_CONFIG,    C_RB_DATA_WIDTH));
      benables               <= (others => '0');
      wlut                   <= std_logic_vector(to_unsigned(C_DEFAULT_RX_WORD_TYPE_LUT,    C_RB_DATA_WIDTH));
      heartbeat_config       <= std_logic_vector(to_unsigned(C_DEFAULT_RX_HEARTBEAT_CONFIG, C_RB_DATA_WIDTH));
      rollover_config        <= std_logic_vector(to_unsigned(C_DEFAULT_RX_ROLLOVER_CONFIG,  C_RB_DATA_WIDTH));
      heartbeat_header       <= std_logic_vector(to_unsigned(C_DEFAULT_RX_HEARTBEAT_HEADER,  C_RB_DATA_WIDTH));
      rollover_header        <= std_logic_vector(to_unsigned(C_DEFAULT_RX_ROLLOVER_HEADER,  C_RB_DATA_WIDTH));
      eop_header             <= std_logic_vector(to_unsigned(C_DEFAULT_RX_EOP_HEADER,       C_RB_DATA_WIDTH));
      zero_counters <= '0';
      look_select <= (others => '0');
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
            elsif (reg=C_ADDR_RX_UART_CHAN) then
              uart_chan(chan) <= wdata(15 downto 0);
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
            elsif (reg=C_ADDR_RX_BUFFER_ENABLES) then
              benables <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_PACMAN) then
              pacman <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_ZERO_CNTS) then
              zero_counters <= '1';
              wack  <= '1';
            elsif (reg=C_ADDR_RX_WORD_TYPE_LUT) then
              wlut  <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_HEARTBEAT_CONFIG) then
              heartbeat_config <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_ROLLOVER_CONFIG) then
              rollover_config <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_HEARTBEAT_HEADER) then
              heartbeat_header <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_ROLLOVER_HEADER) then
              rollover_header <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_EOP_HEADER) then
              eop_header <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_LOOK_SELECT) then
              look_select <= wdata(C_SELECT_WIDTH-1 downto 0);
              wack  <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Count RX conditions from status register, zero on reset or zero_counters signal.

  process(rst, ustatus, zero_counters, starts_rega, beats_rega, updates_rega, lost_rega)
    variable fifo_now : unsigned(31 downto 0);
    variable valid  : std_logic;
    variable ready  : std_logic;
    variable start  : std_logic;
    variable update : std_logic;
    variable lost   : std_logic;
  begin
    if (rst='1') or (zero_counters = '1') then
      starts_next   <= (others => (others => '0'));
      beats_next    <= (others => (others => '0'));
      updates_next  <= (others => (others => '0'));
      lost_next     <= (others => (others => '0'));
      fifo_max_next  <= (others => '0');
    else
      fifo_now := unsigned(fifo_count(31 downto 0));

      if (fifo_now > fifo_max_rega) then
        fifo_max_next <= fifo_now;
      else
        fifo_max_next <= fifo_max_rega;
      end if;

      gen_next: for i in 0 to C_NUM_UART-1 loop
        -- extract status bits for clarity
        valid  := ustatus(i)(1);
        ready  := ustatus(i)(2);
        start  := ustatus(i)(4);
        update := ustatus(i)(5);
        lost   := ustatus(i)(6);

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

        -- update count increments when update=1:
        if (update = '1') and (updates_rega(i) < C_COUNT_MAX) then
          updates_next(i) <= updates_rega(i) + 1;
        else
          updates_next(i) <= updates_rega(i);
        end if;

        -- lost count increments when lost=1:
        if (lost = '1') and (lost_rega(i) < C_COUNT_MAX) then
          lost_next(i) <= lost_rega(i) + 1;
        else
          lost_next(i) <= lost_rega(i);
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
      updates_rega  <= (others => (others => '0'));
      lost_rega     <= (others => (others => '0'));
      fifo_max_rega <= (others => '0');

      starts_regb   <= (others => (others => '0'));
      beats_regb    <= (others => (others => '0'));
      updates_regb  <= (others => (others => '0'));
      lost_regb     <= (others => (others => '0'));
      fifo_max_regb <= (others => '0');

    elsif rising_edge(clk) then
      -- First register stage: next -> rega
      starts_rega   <= starts_next;
      beats_rega    <= beats_next;
      updates_rega  <= updates_next;
      lost_rega     <= lost_next;
      fifo_max_rega <= fifo_max_next;

      -- Second register stage: rega -> regb
      starts_regb   <= starts_rega;
      beats_regb    <= beats_rega;
      updates_regb  <= updates_rega;
      lost_regb     <= lost_rega;
      fifo_max_regb <= fifo_max_rega;
    end if;
  end process;

end;
