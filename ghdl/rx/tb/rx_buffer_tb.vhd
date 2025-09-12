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
      LOOK_O             : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
      -- the received data from the UART receivers and extra channels
      HEADER_I           : in  rx_header_array_t;
      DATA_I             : in  rx_data_array_t;
      TIMESTAMP_I        : in  rx_timestamp_array_t;
      VALID_I            : in  std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      READY_O            : out std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      DEBUG_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DEBUG_DATA_O       : out std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;

  signal tdata    : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
  signal tvalid   : std_logic;
  signal tready   : std_logic := '0';
  signal tlast    : std_logic;

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
  signal ulk      : std_logic_vector(7 downto 0) := (others => '0');
  signal ulast    : std_logic := '0';
  signal tlk      : std_logic_vector(7 downto 0) := (others => '0');
  signal twt      : std_logic_vector(7 downto 0) := (others => '0');

  signal status      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal look        : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
  signal show_output : std_logic := '0';
begin

  uva <= uvalid(0);
  uvb <= uvalid(1);
  uvc <= uvalid(2);
  ura <= uready(0);
  urb <= uready(1);
  urc <= uready(2);
  ulast <= status(6);
  ulk <= look(71 downto 64);
  tlk <= tdata(71 downto 64);
  twt <= tdata(7  downto 0);

  uut: rx_buffer port map (
    M_AXIS_ACLK     => aclk,
    M_AXIS_ARESETN  => aresetn,
    M_AXIS_TDATA    => tdata,
    M_AXIS_TVALID   => tvalid,
    M_AXIS_TREADY   => tready,
    M_AXIS_TLAST    => tlast,
    CONFIG_I        => x"00000000",
    HEADER_I        => header,
    DATA_I          => data,
    TIMESTAMP_I     => timestamp,
    VALID_I         => uvalid,
    READY_O         => uready,
    DEBUG_STATUS_O  => status, -- (non-delayed version for easy debugging)
    DEBUG_DATA_O    => look   -- (non-delayed version for easy debugging)
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
      uvalid <= x"00000000007";
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
    header(0)  <= x"0144";
    header(1)  <= x"0244";
    header(2)  <= x"0344";
    data(0)(15 downto 0) <= x"AAAA";
    data(1)(15 downto 0) <= x"BBBB";
    data(2)(15 downto 0) <= x"CCCC";
    timestamp(0)(15 downto 0) <= x"123A";
    timestamp(1)(15 downto 0) <= x"123B";
    timestamp(2)(15 downto 0) <= x"123C";
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
    variable turn : integer;

  begin
    wait for 10 ns;

    turn := to_integer(unsigned(status(13 downto 8)));

    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      write (l, String'("t: "));
      write (l, turn, left, 3);

      if (status(1 downto 0) = "00") then
        write (l, String'(" IDLE "));
      elsif (status(1 downto 0) = "01") then
        write (l, String'(" STRM "));
      else
        write (l, String'(" LAST "));
      end if;

      write (l, String'(" uva: "));
      write (l, uva);
      write (l, String'(" ura: "));
      write (l, ura);

      write (l, String'(" uvb: "));
      write (l, uvb);
      write (l, String'(" urb: "));
      write (l, urb);

      write (l, String'(" uvc: "));
      write (l, uvc);
      write (l, String'(" urc: "));
      write (l, urc);

      write (l, String'(" ul: "));
      write (l, ulast);

      write (l, String'(" ulk: "));
      hwrite (l, ulk);



      write (l, String'(" | tv: "));
      write (l, tvalid);
      write (l, String'(" tr: "));
      write (l, tready);
      write (l, String'(" tl: "));
      write (l, tlast);
      write (l, String'(" tlk: "));
      hwrite (l, tlk);
      write (l, String'(" twt: "));
      hwrite (l, twt);
      write (l, String'(" ("));
      write(L, character'val(to_integer(unsigned(twt))));
      write (l, String'(")"));









      --write (l, String'("| uv: 0x"));
      --hwrite (l, uvalid);
      --write (l, String'(" ur: 0x"));
      --hwrite (l, uready);
      --write (l, String'(" look: 0x"));
      --hwrite (l, look(79 downto 64));

      --write (l, String'("| tdata: 0x"));
      --hwrite (l, tdata(79 downto 64));
      --write (l, String'(".."));
      --write (l, String'(" v: "));
      --write (l, tvalid);
      --write (l, status(2));
      --write (l, String'(" r: "));
      --write (l, tready);
      --write (l, status(3));
      --write (l, String'(" l: "));
      --write (l, tlast);
      --write (l, String'(" busy: "));
      --write (l, status(4));
      --write (l, beat, left, 3);
      --write (l, String'(" w: "));
      --write (l, status(5));
      --write (l, String'(" l: "));
      --write (l, status(6));

      --write (l, String'("| data 0x 0:"));
      --hwrite (l, data(0)(7 downto 0));
      --write (l, String'(" 1:"));
      --hwrite (l, data(1)(7 downto 0));
      --write (l, String'(" 2:"));
      --hwrite (l, data(2)(7 downto 0));
      --write (l, String'(" 3:"));
      --hwrite (l, data(3)(7 downto 0));

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
