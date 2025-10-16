library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;

--  Defines a testbench (without any ports)
entity payload_sync_tb is
end payload_sync_tb;

architecture behaviour of payload_sync_tb is

  signal count       : integer := 0;
  signal clk         : std_logic;
  signal rst         : std_logic;
  signal uclk        : std_logic;

  signal busy        : std_logic;
  signal payload_src : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal payload_dst : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  signal show_output : std_logic := '0';

  component payload_sync is
    generic ( PAYLOAD_WIDTH : integer := C_RB_DATA_WIDTH );
    port (
      CLK_I       : in  std_logic;
      RST_I	  : in  std_logic;
      BUSY_I	  : in  std_logic;
      PAYLOAD_O   : out std_logic_vector(PAYLOAD_WIDTH-1 downto 0);
      PAYLOAD_A   : in  std_logic_vector(PAYLOAD_WIDTH-1 downto 0)
    );
  end component;

begin
  dut0: payload_sync port map (
    CLK_I      => clk,
    RST_I      => rst,
    BUSY_I     => busy,
    PAYLOAD_O  => payload_dst,
    PAYLOAD_A  => payload_src
  );

  update_process : process
  begin
    busy <= '0';
    wait for 20 ns;
    busy <= '1';
    wait for 80 ns;
    payload_src <= x"1234ABCD";
    wait for 120 ns;
    busy <= '0';
    wait for 20 ns;
    busy <= '1';
    wait for 60 ns;
    payload_src <= x"AAAABBBB";
    wait for 120 ns;
    busy <= '0';
    wait;
  end process;



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

  uclk_process : process
  begin
    uclk <= '1';
    wait for 50 ns;
    uclk <= '0';
    wait for 50 ns;
  end process;

  show_output_process : process
  begin
    show_output<='1';
    wait until (count=60);
    wait for 10 ns;
    show_output<='0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    wait for 10 ns;
    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 4);
      write (l, String'(" "));
      write (l, uclk);
      write (l, String'(" busy: "));
      write (l, busy);
      write (l, String'(" payload src: "));
      hwrite (l, payload_src);
      write (l, String'(" payload dst: "));
      hwrite (l, payload_dst);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
