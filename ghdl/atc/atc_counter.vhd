library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

-- Command parsing:
-- NO OP    0000 XXXX
-- CLEAR    0001 XXXX
-- START    0010 XXXX
-- STOP     0011 XXXX
-- RESERVED 0100 XXXX
-- READ G   0101 CCCC
-- READ H   0110 CCCC
-- READ I   0111 CCCC
-- RESERVED 1XXX XXXX
--
--  C = read channel
--
entity atc_counter is

  port (
    --clk and active-high reset
    CLK_I     : in  std_logic;
    RST_I     : in  std_logic;

     --input signals which increment counters
    LEMO_A_I  : in  std_logic;
    LEMO_B_I  : in  std_logic;
    POKE_C_I  : in  std_logic;
    POKE_D_I  : in  std_logic;
    G_I       : in std_logic_vector(C_NUM_TILE -1  downto 0) ;
    H_I       : in std_logic_vector(C_NUM_TILE -1 downto 0) ;

    --counter control signals:
    UPDATE_I  : in  std_logic;
    COMMAND_I : in  std_logic_vector(7 downto 0);

    --selected counter output
    COUNT_O   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
end;

architecture behavioral of atc_counter is
  component counter is
    port (
      CLK_I	   : in  std_logic;
      RST_I 	   : in  std_logic;
      INCREMENT_I  : in  std_logic;
      RUN_I        : in  std_logic;
      CLEAR_I      : in  std_logic;
      COUNT_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal clk           : std_logic;
  signal rst           : std_logic;

  -- input stimuli counters:
  signal count_a       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0):= (others => '0');
  signal count_b       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0):= (others => '0');
  signal count_c       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0):= (others => '0');
  signal count_d       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0):= (others => '0');
  -- output counters:
  type count_arr_t is array (0 to C_NUM_TILE -1) of std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal g_out         : count_arr_t := (others => (others => '0'));
  signal h_out         : count_arr_t := (others => (others => '0'));

  -- registered control register, zero except for once clock cycle after update
  signal cmd_code      : std_logic_vector(3 downto 0);
  signal cmd_chan      : unsigned(3 downto 0);

  -- counter control signals, combinatorically derviced from cmd_upper:
  signal cmd_clear     : std_logic := '0';
  signal cmd_start     : std_logic := '0';
  signal cmd_stop      : std_logic := '0';
  signal cmd_read_g    : std_logic := '0';
  signal cmd_read_h    : std_logic := '0';
  signal cmd_read_i    : std_logic := '0';
  signal cmd_read_any  : std_logic := '0';

  -- run register:  sticky register controlled by cmd_start and cmd_stop:
  signal run_reg     : std_logic := '0';
  -- clear register: clear command registered for one clock cycle:
  signal clear_reg   : std_logic := '0';

  -- MUXed count to be registered as COUNT_O:
  signal count_next  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

begin
  clk  <= CLK_I;
  rst  <= RST_I;

  gen_gout:for i in 0 to C_NUM_TILE -1 generate
    out_g:counter
      port map (
        CLK_I        => clk,
        RST_I        => rst,
        INCREMENT_I  => G_I(i) ,
        RUN_I        => run_reg,
        CLEAR_I      => clear_reg,
        COUNT_O      => g_out(i)
      );
  end generate;

  gen_hout:for i in 0 to C_NUM_TILE -1 generate
    out_h:counter
      port map (
        CLK_I        => clk,
        RST_I        => rst,
        INCREMENT_I  => H_I(i) ,
        RUN_I        => run_reg,
        CLEAR_I      => clear_reg,
        COUNT_O      => h_out(i)
      );
  end generate;

  --output of lemo_a
  out_a:counter
    port map (
      CLK_I          => clk,
      RST_I          => rst,
      INCREMENT_I    => LEMO_A_I,
      RUN_I          => run_reg,
      CLEAR_I        => clear_reg,
      COUNT_O        => count_a
    );

  --Counter for lemo_b
  out_b:counter
    port map (
      CLK_I          => clk,
      RST_I          => rst,
      INCREMENT_I    => LEMO_B_I ,
      RUN_I          => run_reg,
      CLEAR_I        => clear_reg,
      COUNT_O        => count_b
    );

  --output of poke_c
  out_c:counter
    port map (
      CLK_I          => clk,
      RST_I          => rst,
      INCREMENT_I    => POKE_C_I ,
      RUN_I          => run_reg,
      CLEAR_I        => clear_reg,
      COUNT_O        => count_c
    );
  --output of poke_d
  out_d:counter
    port map (
      CLK_I          => clk,
      RST_I          => rst,
      INCREMENT_I    => POKE_D_I ,
      RUN_I          => run_reg,
      CLEAR_I        => clear_reg,
      COUNT_O        => count_d
      );

  -- register upper and lower nibbles of command byte as cmd_code and
  -- cmd_chan:
  proc_cmd : process(rst,clk)
    variable chan : unsigned(3 downto 0);
  begin
    if rst = '1' then
      cmd_code <= (others => '0');
      cmd_chan <= (others => '0');
    elsif rising_edge(clk) then
      if (UPDATE_I = '1') then
        cmd_code <= COMMAND_I(7 downto 4);
        chan := unsigned(COMMAND_I(3 downto 0));
        if (to_integer(chan) < C_NUM_TILE) then
          cmd_chan <= chan;
        else
          cmd_chan <= (others => '0');
        end if;
      else
        cmd_code <= (others => '0');
        cmd_chan <= (others => '0');
      end if;
    end if;
  end process;

  -- command decoding:
  cmd_clear  <= '1' when cmd_code = "0001" else '0';
  cmd_start  <= '1' when cmd_code = "0010" else '0';
  cmd_stop   <= '1' when cmd_code = "0011" else '0';
  cmd_read_g <= '1' when cmd_code = "0101" else '0';
  cmd_read_h <= '1' when cmd_code = "0110" else '0';
  cmd_read_i <= '1' when cmd_code = "0111" else '0';
  cmd_read_any <= cmd_read_g or cmd_read_h or cmd_read_i;
  -- register clear and run:
  proc_clear_and_run : process(rst,clk)
  begin
    if rst = '1' then
      clear_reg <= '0';
      run_reg <= '1';
    elsif rising_edge(clk) then
      clear_reg <= '0';
      run_reg <= run_reg;
      if (cmd_clear = '1') then
        clear_reg <= '1';
      end if;
      if (cmd_start = '1') then
        run_reg <= '1';
      elsif (cmd_stop = '1') then
        run_reg <= '0';
      end if;
    end if;
  end process;

  proc_count_mux : process(cmd_chan, cmd_read_g, cmd_read_h, cmd_read_i,
                           g_out, h_out, count_a, count_b, count_c, count_d)
  begin
    if cmd_read_g = '1' then
      count_next <= g_out(to_integer(cmd_chan));
    elsif cmd_read_h = '1' then
      count_next <= h_out(to_integer(cmd_chan));
    elsif cmd_read_i = '1' then
      case to_integer(cmd_chan) is
        when 0 => count_next <= count_a;
        when 1 => count_next <= count_b;
        when 2 => count_next <= count_c;
        when 3 => count_next <= count_d;
        when others => count_next <= (others => '0');
      end case;
    else
      count_next <= count_next;
    end if;
  end process;

  -- register the count:
  proc_count : process(rst,clk)
  begin
    if rst = '1' then
      COUNT_O <= (others => '0');
    elsif rising_edge(clk) then
      if (cmd_read_any='1') then
        COUNT_O <= count_next;
      end if;
    end if;
  end process;

end;
