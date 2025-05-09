library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;

entity rx_registers is
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

    LOOK_I              : in  uart_rx_data_array_t;
    STATUS_I            : in  uart_reg_array_t;
    CONFIG_O            : out uart_reg_array_t := (others => (others => '0'));
    GFLAGS_O            : out std_logic_vector(C_RX_GFLAGS_WIDTH-1 downto 0) := (others => '0');
    HEARTBEAT_CYCLES_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    SYNC_CYCLES_O        : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    GSTATUS_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    FIFO_RCNT_I         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    FIFO_WCNT_I         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DMA_ITR_I           : in  std_logic
  );
end;

architecture behavioral of rx_registers is
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

  -- output registers:
  signal config           : uart_reg_array_t := (others => std_logic_vector(to_unsigned(C_DEFAULT_CONFIG_RX, C_RB_DATA_WIDTH)));
  signal gflags           : std_logic_vector(C_RX_GFLAGS_WIDTH-1 downto 0);
  signal heartbeat_cycles : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal sync_cycle       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  -- input registers:
  signal look       : uart_rx_data_array_t;
  signal status     : uart_reg_array_t;
  signal gstatus    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal fifo_rcnt  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal fifo_wcnt  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal dma_itr    : std_logic;

  signal zero_counters : std_logic := '0';
  signal istarts  : uart_counter_array_t := (others => 0);
  signal ibeats   : uart_counter_array_t := (others => 0);
  signal iupdates : uart_counter_array_t := (others => 0);
  signal ilost    : uart_counter_array_t := (others => 0);


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
  HEARTBEAT_CYCLES_O  <= heartbeat_cycles;
  SYNC_CYCLES_O        <= sync_cycle;

  process(clk, rst)
  begin
    if (rst='1') then
      look      <= (others => (others => '0'));
      status    <= (others => (others => '0'));
      gstatus   <= (others => '0');
      fifo_rcnt <= (others => '0');
      fifo_wcnt <= (others => '0');
      dma_itr   <= '1';
    elsif (rising_edge(clk)) then
      look      <= LOOK_I;
      status    <= STATUS_I;
      gstatus   <= GSTATUS_I;
      fifo_rcnt <= FIFO_RCNT_I;
      fifo_wcnt <= FIFO_WCNT_I;
      dma_itr   <= DMA_ITR_I;
    end if;
  end process;

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
          if (scope=1) then
            rdata <= x"EEEEEEEE";
            rack  <= '0';
            if (chan < 40) then
              if (reg=C_ADDR_RX_STATUS) then
                rdata <= status(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_CONFIG) then
                rdata <= config(chan);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_LOOK_A) then
                rdata <= look(chan)(31 downto 0);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_LOOK_B) then
                rdata <= look(chan)(63 downto 32);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_LOOK_C) then
                rdata <= look(chan)(95 downto 64);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_LOOK_D) then
                rdata <= look(chan)(127 downto 96);
                rack  <= '1';
              elsif (reg=C_ADDR_RX_NCHAN) then
                rdata <= std_logic_vector(to_unsigned(chan, rdata'length));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_STARTS) then
                rdata <= std_logic_vector(to_unsigned(istarts(chan),C_RB_DATA_WIDTH));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_BEATS) then
                rdata <= std_logic_vector(to_unsigned(ibeats(chan),C_RB_DATA_WIDTH));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_UPDATES) then
                rdata <= std_logic_vector(to_unsigned(iupdates(chan),C_RB_DATA_WIDTH));
                rack  <= '1';
              elsif (reg=C_ADDR_RX_LOST) then
                rdata <= std_logic_vector(to_unsigned(ilost(chan),C_RB_DATA_WIDTH));
                rack  <= '1';
              end if;
            elsif (chan = 16#3F#) then
              if (reg=C_ADDR_RX_GSTATUS) then
                rdata <= gstatus;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_GFLAGS) then
                rdata <= (others => '0');
                rdata(C_RX_GFLAGS_WIDTH-1 downto 0) <= gflags;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_FRCNT) then
                rdata <= fifo_rcnt;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_FWCNT) then
                rdata <= fifo_wcnt;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_DMAITR) then
                rdata <= (others => '0');
                rdata(0) <= dma_itr;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_HEARTBEAT_CYCLES) then
                rdata <= heartbeat_cycles;
                rack  <= '1';
              elsif (reg=C_ADDR_RX_SYNC_CYCLES) then
                rdata <= sync_cycle;
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
      config            <= (others => std_logic_vector(to_unsigned(C_DEFAULT_CONFIG_RX, C_RB_DATA_WIDTH)));
      gflags            <= (others => '0');
      heartbeat_cycles  <= std_logic_vector(to_unsigned(C_DEFAULT_HEARTBEAT_CYCLES, C_RB_DATA_WIDTH));
      sync_cycle        <= std_logic_vector(to_unsigned(C_DEFAULT_SYNC_CYCLES, C_RB_DATA_WIDTH));


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
          if ((scope=1) and (chan < 40)) then
            if (reg=C_ADDR_RX_CONFIG) then
              config(chan) <= wdata;
              wack  <= '1';
            end if;
          end if;
          if ((scope=1) and (chan = 16#3B#)) then
            if (reg=C_ADDR_RX_CONFIG) then
              for i in 0 to C_NUM_UART-1 loop
                config(i) <= wdata;
              end loop;
              wack  <= '1';
            end if;
          end if;
          if ((scope=1) and (chan = 16#3F#)) then
            if (reg=C_ADDR_RX_GFLAGS) then
              gflags <= wdata(C_RX_GFLAGS_WIDTH-1 downto 0);
              wack  <= '1';
            elsif (reg=C_ADDR_RX_ZERO_CNTS) then
              zero_counters <= '1';
              wack  <= '1';
            elsif (reg=C_ADDR_RX_HEARTBEAT_CYCLES) then
              heartbeat_cycles <= wdata;
              wack  <= '1';
            elsif (reg=C_ADDR_RX_SYNC_CYCLES) then
              sync_cycle <= wdata;
              wack  <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  process(clk, rst)
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
    else
      if (rising_edge(clk)) then
        for i in 0 to C_NUM_UART-1 loop
          -- map status bits as written in rx_chan.vhd:
          busy   := status(i)(0);
          valid  := status(i)(1);
          ready  := status(i)(2);
          start  := status(i)(4);
          update := status(i)(5);
          lost   := status(i)(6);
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
    end if;
  end process;


end;
