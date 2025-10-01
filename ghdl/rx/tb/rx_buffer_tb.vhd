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
      M_AXIS_ACLK        : in std_logic;
      M_AXIS_ARESETN     : in std_logic;
      M_AXIS_TDATA       : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      M_AXIS_TVALID      : out std_logic;
      M_AXIS_TREADY      : in  std_logic;
      M_AXIS_TKEEP       : out std_logic_vector(C_RX_AXIS_WIDTH/8-1 downto 0);
      M_AXIS_TLAST       : out std_logic;
      STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CONFIG_I           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      LOOK_O             : out std_logic_vector(C_RX_WORDS_PER_TURN*C_RX_AXIS_WIDTH-1 downto 0);
      -- the received data from the UART receivers and extra channels
      HEADER_I           : in  rx_header_array_t;
      DATA_I             : in  rx_data_array_t;
      TIMESTAMP_I        : in  rx_timestamp_array_t;
      VALID_I            : in  std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      READY_O            : out std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      EOP_HEADER_I       : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DEBUG_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;

  signal tdata    : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
  signal tvalid   : std_logic;
  signal tready   : std_logic := '0';
  signal tlast    : std_logic;

  signal look     : std_logic_vector(C_RX_WORDS_PER_TURN*C_RX_AXIS_WIDTH-1 downto 0);

  signal header    : rx_header_array_t;
  signal data      : rx_data_array_t;
  signal timestamp : rx_timestamp_array_t;

  signal uvalid   : std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
  signal uready   : std_logic_vector(C_RX_NUM_CHAN-1 downto 0);

  -- single out single bits/bytes for illustration:
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

  uva <= uvalid(0);
  uvb <= uvalid(1);
  uvc <= uvalid(2);
  ura <= uready(0);
  urb <= uready(1);
  urc <= uready(2);
  ulast <= status(7);

  uut: rx_buffer port map (
    M_AXIS_ACLK     => aclk,
    M_AXIS_ARESETN  => aresetn,
    M_AXIS_TDATA    => tdata,
    M_AXIS_TVALID   => tvalid,
    M_AXIS_TREADY   => tready,
    M_AXIS_TLAST    => tlast,
    CONFIG_I        => x"00000001",
    LOOK_O          => look,
    HEADER_I        => header,
    DATA_I          => data,
    TIMESTAMP_I     => timestamp,
    VALID_I         => uvalid,
    READY_O         => uready,
    EOP_HEADER_I    => x"1100004C",
    DEBUG_STATUS_O  => status -- (non-delayed version for easy debugging)
  );

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 20 ns;
    aresetn <= '1';
    wait;
  end process;

  aclk_process : process
  begin
    count <= count + 1;
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
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
      wait for 580 ns;
      delay := '0';
    end if;
    if (init='1') then
      -- 44 RX channels (40 UARTS plus 4 extra for e.g. SYNC words)
      uvalid <= x"00000000700";
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
    data <= (others => (others => '0'));
    header(8)  <= x"00000144";
    header(9)  <= x"00000244";
    header(10)  <= x"00000344";
    data(8)(15 downto 0) <= x"AAAA";
    data(9)(15 downto 0) <= x"BBBB";
    data(10)(15 downto 0) <= x"CCCC";
    timestamp(8)(15 downto 0) <= x"123A";
    timestamp(9)(15 downto 0) <= x"123B";
    timestamp(10)(15 downto 0) <= x"123C";
    wait;
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
    variable turn  : integer;
    variable word  : integer;
    variable wtype : integer := 0;
  begin
    wait for 10 ns;

    turn := to_integer(unsigned(status(13 downto 8)));
    word := to_integer(unsigned(status(15 downto 14)));

    if (word=2) and ((status(2 downto 0) = "011") or (status(2 downto 0) = "101")) then
      wtype := to_integer(unsigned(tdata(7 downto 0)));
    else
      wtype := 0;
    end if;

    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      write (l, String'("t: "));
      write (l, turn, left, 3);
      write (l, String'("w: "));
      write (l, word, left, 3);
      if (status(2 downto 0) = "000") then
        write (l, String'(" IDL "));
      elsif (status(2 downto 0) = "001") then
        write (l, String'(" SYN "));
      elsif (status(2 downto 0) = "010") then
        write (l, String'(" CYC "));
      elsif (status(2 downto 0) = "011") then
        write (l, String'(" STR "));
      elsif (status(2 downto 0) = "100") then
        write (l, String'(" PAU "));
      elsif (status(2 downto 0) = "101") then
        write (l, String'(" TRA "));
      else
        write (l, String'(" UNK  "));
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

      if (aresetn = '0') then
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
