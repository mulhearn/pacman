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
      CLK_I              : in std_logic;
      RST_I              : in std_logic;

      S_AXIS_TDATA       : in std_logic_vector(C_TX_AXIS_WIDTH-1 downto 0);
      S_AXIS_TVALID      : in std_logic;
      S_AXIS_TREADY      : out std_logic;
      S_AXIS_TKEEP       : in std_logic_vector(C_TX_AXIS_WIDTH/8-1 downto 0);
      S_AXIS_TLAST       : in std_logic;

      STATUS_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

      DATA_O             : out uart_data_array_t;
      VALID_O            : out std_logic_vector(C_NUM_UART-1 downto 0);
      READY_I            : in std_logic_vector(C_NUM_UART-1 downto 0);

      DEBUG_O           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal tdata    : std_logic_vector(C_TX_AXIS_WIDTH-1 downto 0) := (others => '0');
  signal tvalid   : std_logic := '0';
  signal tready   : std_logic;
  signal tlast    : std_logic := '0';

  signal status   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  signal udata    : uart_data_array_t;
  signal uvalid   : std_logic_vector(C_NUM_UART-1 downto 0);
  signal uready   : std_logic_vector(C_NUM_UART-1 downto 0);


  -- pick off single bits for timing diagrams

  signal uvalid_a : std_logic;
  signal uvalid_b : std_logic;
  signal uvalid_c : std_logic;
  signal uready_a : std_logic;
  signal uready_b : std_logic;
  signal uready_c : std_logic;


begin
  uvalid_a <= uvalid(0);
  uvalid_b <= uvalid(8);
  uvalid_c <= uvalid(16);
  uready_a <= uready(0);
  uready_b <= uready(8);
  uready_c <= uready(16);

  uut: tx_buffer port map (
    CLK_I           => clk,
    RST_I           => rst,
    S_AXIS_TDATA    => tdata,
    S_AXIS_TVALID   => tvalid,
    S_AXIS_TREADY   => tready,
    S_AXIS_TKEEP    => (others=>'1'),
    S_AXIS_TLAST    => tlast,
    DATA_O          => udata,
    VALID_O         => uvalid,
    READY_I         => uready,
    DEBUG_O        => status
  );

  rst_process : process
  begin
    rst <= '1';
    wait for 20 ns;
    rst <= '0';
    wait;
  end process;

  ready_process : process
  begin
    uready <= (others => '0');
    wait for 1 ns;
    wait for 460 ns;
    uready <= x"00000000FF";
    wait for 10 ns;
    uready <= x"0000000000";
    wait for 20 ns;
    uready <= x"000000FF00";
    wait for 10 ns;
    uready <= x"0000000000";
    wait for 20 ns;
    uready <= x"FFFFFF0000";
    wait for 10 ns;
    uready <= x"0000000000";
    wait;
  end process;

  stream_process : process
  begin
    tvalid                <= '0';
    tlast                 <= '0';
    wait for 1 ns;
    wait for 20 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"000000FFFFFFFFFF";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD00CCCCCC00";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD01CCCCCC01";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD02CCCCCC02";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD03CCCCCC03";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD04CCCCCC04";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD05CCCCCC05";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD06CCCCCC06";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD07CCCCCC07";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD08CCCCCC08";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD09CCCCCC09";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD0ACCCCCC0A";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD0BCCCCCC0B";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD0CCCCCCC0C";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD0DCCCCCC0D";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD0ECCCCCC0E";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD0FCCCCCC0F";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD10CCCCCC10";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD11CCCCCC11";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD12CCCCCC12";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD13CCCCCC13";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD14CCCCCC14";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD15CCCCCC15";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD16CCCCCC16";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD17CCCCCC17";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD18CCCCCC18";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD19CCCCCC19";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD1ACCCCCC1A";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD1BCCCCCC1B";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD1CCCCCCC1C";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD1DCCCCCC1D";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD1ECCCCCC1E";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD1FCCCCCC1F";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD20CCCCCC20";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD21CCCCCC21";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD22CCCCCC22";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD23CCCCCC23";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD24CCCCCC24";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD25CCCCCC25";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD26CCCCCC26";
    wait for 10 ns;
    tdata(63 downto 0)    <= x"DDDDDD27CCCCCC27";
    tlast                 <= '1';
    wait for 10 ns;
    tvalid                <= '0';
    tdata                 <= (others => '0');
    tlast                 <= '0';
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

  output_process : process
    variable l : line;
  begin
    if (count < 60) then
      wait for 10 ns;
    else
      wait;
    end if;

    if (status(9 downto 8) = "00") then
      write (l, String'(" IDL "));
    elsif (status(9 downto 8) = "01") then
      write (l, String'(" STR "));
    elsif (status(9 downto 8) = "10") then
      write (l, String'(" TX  "));
    else
      write (l, String'(" UNKN "));
    end if;

    write (l, String'("c: "));
    write (l, count, left, 4);
    --write (l, String'("aclk: "));
    --write (l, aclk);
    write (l, String'("|| tdata: 0x..."));
    hwrite (l, tdata(15 downto 0));
    write (l, String'(" tval: "));
    write (l, tvalid);
    write (l, String'(" trdy: "));
    write (l, tready);
    write (l, String'(" ltast: "));
    write (l, tlast);
    write (l, String'("|| ov 0x"));
    hwrite (l, uvalid);
    write (l, String'("|| udata 0x 0:"));
    hwrite (l, udata(0)(11 downto 0));
    write (l, String'(" 1:"));
    hwrite (l, udata(1)(11 downto 0));
    write (l, String'(" 38:"));
    hwrite (l, udata(38)(11 downto 0));
    write (l, String'(" 39:"));
    hwrite (l, udata(39)(11 downto 0));

    if (rst = '1') then
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
    write(l, String'("INFO:  AXI stream is valid for 41 beats of 64 bits:  1 64-bit header and 40 64-bit payloads:"));
    writeline(output, l);
    wait until (count=45);
    write(l, String'("INFO:  going to START_TX state, then TX:"));
    writeline(output, l);
    wait;
  end process;



end behaviour;

