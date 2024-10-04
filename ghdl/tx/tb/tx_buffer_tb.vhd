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
    wait for 10 ns;
    aresetn <= '1';    
    wait;
  end process;

  ready_process : process
  begin
    oready <= (others => '0');
    wait for 1 ns;
    wait for 260 ns;
    oready <= x"FFFFFF00FF";
    wait for 10 ns;
    oready <= x"000000FF00";
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
    tdata(63 downto 0)    <= x"00000000000000A0";
    tdata(127 downto 64)  <= x"00000000000000B0";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000A1";
    tdata(127 downto 64)  <= x"00000000000000B1";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000A2";
    tdata(127 downto 64)  <= x"00000000000000B2";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000A3";
    tdata(127 downto 64)  <= x"00000000000000B3";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000A4";
    tdata(127 downto 64)  <= x"00000000000000B4";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000A5";
    tdata(127 downto 64)  <= x"00000000000000B5";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000A6";
    tdata(127 downto 64)  <= x"00000000000000B6";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000A7";
    tdata(127 downto 64)  <= x"00000000000000B7";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000A8";
    tdata(127 downto 64)  <= x"00000000000000B8";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000A9";
    tdata(127 downto 64)  <= x"00000000000000B9";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000C0";
    tdata(127 downto 64)  <= x"00000000000000D0";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000C1";
    tdata(127 downto 64)  <= x"00000000000000D1";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000C2";
    tdata(127 downto 64)  <= x"00000000000000D2";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000C3";
    tdata(127 downto 64)  <= x"00000000000000D3";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000C4";
    tdata(127 downto 64)  <= x"00000000000000D4";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000C5";
    tdata(127 downto 64)  <= x"00000000000000D5";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000C6";
    tdata(127 downto 64)  <= x"00000000000000D6";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000C7";
    tdata(127 downto 64)  <= x"00000000000000D7";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000C8";
    tdata(127 downto 64)  <= x"00000000000000D8";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(63 downto 0)    <= x"00000000000000C9";
    tdata(127 downto 64)  <= x"00000000000000D9";
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
    write (l, String'("|| tdata: 0x"));
    hwrite (l, tdata(15 downto 0));
    write (l, String'("..."));
    write (l, String'(" tval: "));
    write (l, tvalid);
    write (l, String'(" trdy: "));
    write (l, tready);
    write (l, String'(" ltast: "));
    write (l, tlast);
    write (l, String'("|| ov 0x"));
    hwrite (l, ovalid);
    write (l, String'("|| odata 0x 0:"));
    hwrite (l, odata(0)(7 downto 0));
    write (l, String'(" 1:"));
    hwrite (l, odata(1)(7 downto 0));
    write (l, String'(" 2:"));
    hwrite (l, odata(2)(7 downto 0));
    write (l, String'(" 3:"));
    hwrite (l, odata(3)(7 downto 0));
    write (l, String'(" 38:"));
    hwrite (l, odata(38)(7 downto 0));
    write (l, String'(" 39:"));
    hwrite (l, odata(39)(7 downto 0));

    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
