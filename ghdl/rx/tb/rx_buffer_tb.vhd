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
      LOOK_O             : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);
      DATA_I             : in  uart_rx_data_array_t;
      VALID_I            : in  std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      READY_O            : out std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
      DEBUG_STATUS_O     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      DEBUG_DATA_O       : out std_logic_vector(C_RX_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;

  signal tdata    : std_logic_vector(C_RX_AXIS_WIDTH-1 downto 0);
  signal tvalid   : std_logic;
  signal tready   : std_logic := '0';
  signal tlast    : std_logic;

  signal data    : uart_rx_data_array_t;
  signal valid   : std_logic_vector(C_RX_NUM_CHAN-1 downto 0);
  signal ready   : std_logic_vector(C_RX_NUM_CHAN-1 downto 0);

  signal status  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal look      : std_logic_vector(C_RX_DATA_WIDTH-1 downto 0);
  signal show_output : std_logic := '0';
begin
  uut: rx_buffer port map (
    M_AXIS_ACLK     => aclk,
    M_AXIS_ARESETN  => aresetn,
    M_AXIS_TDATA    => tdata,
    M_AXIS_TVALID   => tvalid,
    M_AXIS_TREADY   => tready,
    M_AXIS_TLAST    => tlast,
    CONFIG_I        => x"00000000",
    DATA_I          => data,
    VALID_I         => valid,
    READY_O         => ready,
    DEBUG_STATUS_O  => status, -- (non-delayed version for easy debugging)
    DEBUG_DATA_O    => look   -- (non-delayed version for easy debugging)
  );

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 10 ns;
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
    --tready <= '0';
    --wait for 40 ns;
    tready <= '1';
    --wait until (count=83);
    --tready <= '0';
    --wait for 500 ns;
    --tready <= '1';
    wait;
  end process;

  valid_process : process
    variable init : std_logic := '1';
  begin
    if (init='1') then
      --valid <= x"0000000FFFF";
      valid <= x"0FFFFFFFFFF";
      init := '0';
    end if;
    wait for 10 ns;
    valid <= valid and (not ready);
    if (valid = x"00000000000") then
      init := '1';
    end if;
  end process;

  data_process : process
  begin
    data <= (others => (others => '0'));
    data(0)(79 downto 64) <= x"AAAA";
    data(1)(79 downto 64) <= x"BBBB";
    data(2)(79 downto 64) <= x"CCCC";
    data(3)(79 downto 64) <= x"DDDD";
    data(4)(79 downto 64) <= x"EEEE";
    data(5)(79 downto 64) <= x"FFFF";
    data(6)(79 downto 64) <= x"0011";
    data(7)(79 downto 64) <= x"1100";
    data(8)(79 downto 64) <= x"2222";
    data(9)(79 downto 64) <= x"3333";
    data(10)(79 downto 64) <= x"4444";
    data(11)(79 downto 64) <= x"5555";
    data(12)(79 downto 64) <= x"6666";
    data(13)(79 downto 64) <= x"7777";
    data(14)(79 downto 64) <= x"8888";
    data(15)(79 downto 64) <= x"9999";
    data(16)(79 downto 64) <= x"AA11";
    data(17)(79 downto 64) <= x"AA22";
    data(18)(79 downto 64) <= x"AA33";
    data(19)(79 downto 64) <= x"AA44";
    wait;
  end process;

show_process : process
  variable l : line;
begin
  show_output <= '1';
  wait until (count = 50);
  wait for 10 ns;
  show_output <= '0';
  wait for 10 ns;
  write (l, String'("..."));
  writeline(output, l);
  wait until (count = 65);
  show_output <= '1';
  wait until (count = 250);
  wait for 10 ns;
  show_output <= '0';
  wait;
  end process;

  output_process : process
    variable l : line;
    variable turn : integer;
    variable beat : integer;

  begin
    wait for 10 ns;

    turn := to_integer(unsigned(status(13 downto 8)));
    --beat := to_integer(unsigned(status(20 downto 16)));

    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      write (l, String'("t: "));
      write (l, turn, left, 3);
      --write (l, String'("aclk: "));
      --write (l, aclk);
      if (status(1 downto 0) = "00") then
        write (l, String'(" IDLE "));
      elsif (status(1 downto 0) = "01") then
        write (l, String'(" STRM "));
      else
        write (l, String'(" LAST "));
      end if;
      write (l, String'("| tdata: 0x"));
      hwrite (l, tdata(79 downto 64));
      write (l, String'(".."));
      write (l, String'(" v: "));
      write (l, tvalid);
      write (l, status(2));
      write (l, String'(" r: "));
      write (l, tready);
      write (l, status(3));
      write (l, String'(" l: "));
      write (l, tlast);
      write (l, String'(" b: "));
      write (l, status(4));
      --write (l, beat, left, 3);
      write (l, String'(" look: 0x"));
      hwrite (l, look(79 downto 64));
      write (l, String'(" w: "));
      write (l, status(5));
      write (l, String'(" l: "));
      write (l, status(6));
      write (l, String'("| v: "));
      hwrite (l, valid);
      write (l, String'(" r: "));
      hwrite (l, ready);

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
