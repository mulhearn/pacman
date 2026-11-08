library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity rx_buffer_tb is
end rx_buffer_tb;

architecture behaviour of rx_buffer_tb is
  component rx_buffer is
    port (
      CLK_I              : in std_logic;
      RST_I              : in std_logic;
      M_AXIS_TDATA       : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      M_AXIS_TVALID      : out std_logic;
      M_AXIS_TREADY      : in  std_logic;
      M_AXIS_TKEEP       : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
      M_AXIS_TLAST       : out std_logic;
      STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CONFIG_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CHAN_SELECT_O      : out std_logic_vector(C_SELECT_WIDTH-1 downto 0);
      HEADER_I           : in  std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      FRAG_A_I           : in  std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      FRAG_B_I           : in  std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      VALID_I            : in  std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      READY_O            : out std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      EOP_HEADER_I       : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DEBUG_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal tdata    : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
  signal tvalid   : std_logic;
  signal tready   : std_logic := '0';
  signal tlast    : std_logic;

  signal look     : std_logic_vector(C_RX_FRAGS_PER_TURN*C_RX_AXIS_WIDTH-1 downto 0);

  signal chan_select     : std_logic_vector(C_SELECT_WIDTH-1 downto 0);
  signal header   : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0) := (others => '0');
  signal frag_a   : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0) := (others => '0');
  signal frag_b   : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0) := (others => '0');

  signal uvalid   : std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
  signal uready   : std_logic_vector(C_RX_NUM_CHAN-1 downto 0);

  -- single out single bits/bytes for illustration:
  signal tlk      : std_logic_vector(7 downto 0);
  signal uva      : std_logic := '0';
  signal uvb      : std_logic := '0';
  signal uvc      : std_logic := '0';
  signal ura      : std_logic := '0';
  signal urb      : std_logic := '0';
  signal urc      : std_logic := '0';
  signal ulast    : std_logic := '0';
  signal status      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal show_output : std_logic := '0';
begin

  tlk <= tdata(7 downto 0);
  uva <= uvalid(2);
  uvb <= uvalid(5);
  uvc <= uvalid(8);
  ura <= uready(2);
  urb <= uready(5);
  urc <= uready(8);
  ulast <= status(7);




  uut: rx_buffer port map (
    CLK_I           => clk,
    RST_I           => rst,
    M_AXIS_TDATA    => tdata,
    M_AXIS_TVALID   => tvalid,
    M_AXIS_TREADY   => tready,
    M_AXIS_TLAST    => tlast,
    STATUS_O        => status,
    CONFIG_I        => x"00030000",
    CHAN_SELECT_O   => chan_select,
    HEADER_I        => header,
    FRAG_A_I        => frag_a,
    FRAG_B_I        => frag_b,
    VALID_I         => uvalid,
    READY_O         => uready,
    EOP_HEADER_I    => x"1100004C"
  );

  rst_process : process
  begin
    rst <= '1';
    wait for 20 ns;
    rst <= '0';
    wait;
  end process;

  clk_process : process
  begin
    count <= count + 1;
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
  end process;

  tready_process : process
  begin
    tready <= '1';
    wait;
  end process;

  uvalid_process : process
    variable delay : std_logic := '1';
    variable init  : std_logic := '1';
  begin
    if (delay='1') then
      uvalid <= x"00000000000";
      wait for 500 ns;
      delay := '0';
    end if;
    if (init='1') then
      -- 44 RX channels (40 UARTS plus 4 extra for e.g. SYNC words)
      --uvalid <= x"00000000001";
      uvalid <= x"00000000124";
      --uvalid <= x"0FFFFFFFFFF";
      init := '0';
    end if;
    wait for 10 ns;
    uvalid <= uvalid and (not uready);
    if (uvalid = x"00000000000") then
      delay := '1';
      init := '1';
    end if;
  end process;

  data_process : process
  begin
    wait for 10 ns;
    if (to_integer(unsigned(chan_select)) = 0) then
      header <= x"0000000000000144";
      frag_a <= x"0000000001598762";
      frag_b <= x"000000002244BBBB";
    elsif (to_integer(unsigned(chan_select)) = 2) then
      header <= x"0000000000000244";
      frag_a <= x"0000000001598762";
      frag_b <= x"000000002244BBBB";
    elsif (to_integer(unsigned(chan_select)) = 5) then
      header <= x"0000000000000943";
      frag_a <= x"0000000001598762";
      frag_b <= x"000000002244BBBB";
    elsif (to_integer(unsigned(chan_select)) = 8) then
      header <= x"0000000000000A44";
      frag_a <= x"0000000001598762";
      frag_b <= x"000000002244BBBB";
    elsif (to_integer(unsigned(chan_select)) = 10) then
      header <= x"0000000000000B44";
      frag_a <= x"0000000001598762";
      frag_b <= x"000000002244BBBB";
    elsif (to_integer(unsigned(chan_select)) = 11) then
      header <= x"0000000000000C44";
      frag_a <= x"0000000001598762";
      frag_b <= x"000000002244BBBB";
    elsif (to_integer(unsigned(chan_select)) = 42) then
      header <= x"0000000000002B44";
      frag_a <= x"0000000001598762";
      frag_b <= x"000000002244BBBB";
    elsif (to_integer(unsigned(chan_select)) = 43) then
      header <= x"0000000000002C44";
      frag_a <= x"0000000001598762";
      frag_b <= x"000000002244BBBB";
    else
      header <= x"000000000000EE44";
      frag_a <= x"00000000EEEEEEEE";
      frag_b <= x"00000000EEEEEEEE";
    end if;

  end process;

show_process : process
  variable l : line;
begin
  show_output <= '0';
  wait for 550 ns;
  show_output <= '1';
  wait;
end process;

output_process : process
    variable l : line;
    variable iturn  : integer;
    variable iword  : integer;
    variable wtype : integer := 0;
  begin
    wait for 10 ns;

    iturn := to_integer(unsigned(status(13 downto 8)));
    iword := to_integer(unsigned(status(15 downto 14)));

    if (iword=1) and ((status(2 downto 0) = "010") or (status(2 downto 0) = "011")) then
      wtype := to_integer(unsigned(tdata(7 downto 0)));
    else
      wtype := 0;
    end if;

    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      write (l, String'("t: "));
      write (l, iturn, left, 3);
      write (l, String'("w: "));
      write (l, iword, left, 3);
      if (status(2 downto 0) = "000") then
        write (l, String'(" IDLE "));
      elsif (status(2 downto 0) = "001") then
        write (l, String'(" WAIT "));
      elsif (status(2 downto 0) = "010") then
        write (l, String'(" STRM "));
      elsif (status(2 downto 0) = "011") then
        write (l, String'(" TAIL "));
      else
        write (l, String'(" UNKN "));
      end if;

      write (l, String'(" av:"));
      write (l, uva);
      write (l, String'(" r:"));
      write (l, ura);

      write (l, String'(" bv:"));
      write (l, uvb);
      write (l, String'(" r:"));
      write (l, urb);

      write (l, String'(" cv:"));
      write (l, uvc);
      write (l, String'(" r:"));
      write (l, urc);

      write (l, String'(" ul: "));
      write (l, ulast);
      write (l, String'(" | tv: "));
      write (l, tvalid);
      write (l, String'(" tr: "));
      write (l, tready);
      write (l, String'(" tl: "));
      write (l, tlast);
      write (l, String'(" td: 0x"));
      hwrite (l, tdata);
      --write (l, String'(" l: 0x"));
      --hwrite (l, look);
      write (l, String'(" ("));
      write(L, character'val(wtype));
      write (l, String'(")"));

      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      if ((tvalid = '1') and (tready='1')) then
        write (l, String'(" - "));
      end if;
      if (tlast = '1') then
        write (l, String'(" *** "));
      end if;

      writeline(output, l);
    end if;
  end process;

end behaviour;
