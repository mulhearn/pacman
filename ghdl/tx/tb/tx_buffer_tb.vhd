library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity tx_buffer_tb is
end tx_buffer_tb;

architecture behaviour of tx_buffer_tb is
  component tx_buffer is
    port (
      S_AXIS_ACLK        : in std_logic;
      S_AXIS_ARESETN     : in std_logic;

      S_AXIS_TDATA       : in std_logic_vector(C_TX_AXIS_WIDTH-1 downto 0);
      S_AXIS_TVALID      : in std_logic;
      S_AXIS_TREADY      : out std_logic;
      S_AXIS_TKEEP       : in std_logic_vector(C_TX_AXIS_WIDTH/8-1 downto 0);
      S_AXIS_TLAST       : in std_logic;

      STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      DATA_O             : out uart_tx_data_array_t;
      VALID_O            : out std_logic_vector(C_NUM_UART-1 downto 0);
      READY_I            : in std_logic_vector(C_NUM_UART-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;

  signal tdata    : std_logic_vector(C_TX_AXIS_WIDTH-1 downto 0) := (others => '0');
  signal tvalid   : std_logic := '0';
  signal tready   : std_logic;
  signal tlast    : std_logic := '0';

  signal odata    : uart_tx_data_array_t;
  signal ovalid   : std_logic_vector(C_NUM_UART-1 downto 0);
  signal oready   : std_logic_vector(C_NUM_UART-1 downto 0);
begin
  uut: tx_buffer port map (
    S_AXIS_ACLK     => aclk,
    S_AXIS_ARESETN  => aresetn,
    S_AXIS_TDATA    => tdata,
    S_AXIS_TVALID   => tvalid,
    S_AXIS_TREADY   => tready,
    S_AXIS_TKEEP    => (others=>'1'),
    S_AXIS_TLAST    => tlast,
    DATA_O          => odata,
    VALID_O         => ovalid,
    READY_I         => oready
  );

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 20 ns;
    aresetn <= '1';
    wait;
  end process;

  ready_process : process
  begin
    oready <= (others => '0');
    wait for 1 ns;
    wait for 250 ns;
    oready <= x"00000000FF";
    wait for 10 ns;
    oready <= x"000000FF00";
    wait for 10 ns;
    oready <= x"0000FF0000";
    wait for 10 ns;
    oready <= x"00FF000000";
    wait for 10 ns;
    oready <= x"FF00000000";
    wait for 10 ns;
    oready <= x"0000000000";
    wait;
  end process;

  stream_process : process
  begin
    wait for 1 ns;
    wait for 20 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"000000FFFFFFFFFF";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD00CCCCCC00";
    tdata(127 downto 64)  <= x"DDDDDD01CCCCCC01";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD02CCCCCC02";
    tdata(127 downto 64)  <= x"DDDDDD03CCCCCC03";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD04CCCCCC04";
    tdata(127 downto 64)  <= x"DDDDDD05CCCCCC05";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD06CCCCCC06";
    tdata(127 downto 64)  <= x"DDDDDD07CCCCCC07";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD08CCCCCC08";
    tdata(127 downto 64)  <= x"DDDDDD09CCCCCC09";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD0ACCCCCC0A";
    tdata(127 downto 64)  <= x"DDDDDD0BCCCCCC0B";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD0CCCCCCC0C";
    tdata(127 downto 64)  <= x"DDDDDD0DCCCCCC0D";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD0ECCCCCC0E";
    tdata(127 downto 64)  <= x"DDDDDD0FCCCCCC0F";
    tlast                 <= '0';
    wait for 10 ns;
    --
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD10CCCCCC10";
    tdata(127 downto 64)  <= x"DDDDDD11CCCCCC11";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD12CCCCCC12";
    tdata(127 downto 64)  <= x"DDDDDD13CCCCCC13";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD14CCCCCC14";
    tdata(127 downto 64)  <= x"DDDDDD15CCCCCC15";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD16CCCCCC16";
    tdata(127 downto 64)  <= x"DDDDDD17CCCCCC17";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD18CCCCCC18";
    tdata(127 downto 64)  <= x"DDDDDD19CCCCCC19";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD1ACCCCCC1A";
    tdata(127 downto 64)  <= x"DDDDDD1BCCCCCC1B";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD1CCCCCCC1C";
    tdata(127 downto 64)  <= x"DDDDDD1DCCCCCC1D";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD1ECCCCCC1E";
    tdata(127 downto 64)  <= x"DDDDDD1FCCCCCC1F";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD20CCCCCC20";
    tdata(127 downto 64)  <= x"DDDDDD21CCCCCC21";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD22CCCCCC22";
    tdata(127 downto 64)  <= x"DDDDDD23CCCCCC23";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD24CCCCCC24";
    tdata(127 downto 64)  <= x"DDDDDD25CCCCCC25";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"DDDDDD26CCCCCC26";
    tdata(127 downto 64)  <= x"DDDDDD27CCCCCC27";
    tlast                 <= '1';
    wait for 10 ns;
    tvalid                <= '0';
    tdata                 <= (others => '0');
    tlast                 <= '0';
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

  output_process : process
    variable l : line;
  begin
    if (count < 35) then
      wait for 10 ns;
    else
      wait;
    end if;

    write (l, String'("c: "));
    write (l, count, left, 4);
    --write (l, String'("aclk: "));
    --write (l, aclk);
    write (l, String'("|| tdata: 0x..."));
    hwrite (l, tdata(111 downto 96));
    --hwrite (l, tdata(79 downto 64));
    write (l, String'("..."));
    hwrite (l, tdata(15 downto 0));
    write (l, String'(" tval: "));
    write (l, tvalid);
    write (l, String'(" trdy: "));
    write (l, tready);
    write (l, String'(" ltast: "));
    write (l, tlast);
    write (l, String'("|| ov 0x"));
    hwrite (l, ovalid);
    write (l, String'("|| odata 0x 0:"));
    hwrite (l, odata(0)(11 downto 0));
    write (l, String'(" 1:"));
    hwrite (l, odata(1)(11 downto 0));
    write (l, String'(" 2:"));
    hwrite (l, odata(2)(11 downto 0));
    write (l, String'(" 3:"));
    hwrite (l, odata(3)(11 downto 0));
    write (l, String'(" 38:"));
    hwrite (l, odata(38)(11 downto 0));
    write (l, String'(" 39:"));
    hwrite (l, odata(39)(11 downto 0));

    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;

  comment_process : process
    variable l : line;
  begin
    write(l, String'("INFO:  Resetting:"));
    writeline(output, l);
    wait until (count=3);
    write(l, String'("INFO:  AXI stream is valid for 21 beats of 128 bits:  1 128-bit header and 40 64-bit payloads:"));
    writeline(output, l);
    wait until (count=6);
    write(l, String'("INFO:  output buffer fills two uarts per beat: (only LSBs of several uart channels shown):"));
    writeline(output, l);
    wait until (count=25);
    write(l, String'("INFO:  output buffer is full, buffer output marked valid:"));
    writeline(output, l);
    wait until (count=27);
    write(l, String'("INFO:  uarts reply ready eight channels at a time (test pattern), corresponding data marked invalid:"));
    writeline(output, l);
    wait until (count=33);
    write(l, String'("INFO:  buffer becomes ready for new stream data (tready goes high):"));
    writeline(output, l);
    wait;
  end process;



end behaviour;

