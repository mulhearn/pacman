library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08


--  Defines a testbench (without any ports)
entity counter_tb is
generic (
    constant C_RB_DATA_WIDTH     : integer := 32

  );
end counter_tb;

architecture behaviour of counter_tb is
  component counter is
    port (
      CLK_I	           : in  std_logic;
      RST_I 	           : in  std_logic;
      INCREMENT_I	   : in  std_logic;
      RUN_I                : in  std_logic;
      CLEAR_I              : in  std_logic;
      COUNT_O              : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
  );
  end component;

  signal clk              : std_logic;
  signal rst              : std_logic;

  signal update_in        : std_logic;
  signal count_running    : std_logic;
  signal count_clear      : std_logic;
  signal cnt              : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal count            : integer := 0;
  signal show_output      : std_logic := '0';

begin
  uut: counter port map (
    CLK_I	=> clk,
    RST_I 	=> rst,

    INCREMENT_I	=> update_in,
    RUN_I       => count_running,
    CLEAR_I     => count_clear,
    COUNT_O     => cnt
  );

  areset_process : process
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

  counter_process : process
  begin
    count_running <= '1';
    count_clear <= '0';
    wait for 100 ns   ;
    count_running <= '0';
    count_clear <= '0';
    wait for 80 ns;
    count_running <= '0';
    count_clear <= '1';
    wait for 10 ns ;
    count_running <= '1';
    count_clear <= '0';
    wait;
  end process;

  update_process : process
  begin
    wait for 0 ns;
    update_in <= '0';
    wait for 30 ns;
    wait for 1 ns;
    update_in <= '1';
    wait for 10 ns;
    update_in <= '0';
    wait for 30 ns;
    update_in <= '1';
    wait for 10 ns;
    update_in <= '0';
    wait for 30 ns;
    update_in <= '1';
    wait for 10 ns;
    update_in <= '0';
    wait for 30 ns;
    update_in <= '1';
    wait for 10 ns;
    update_in <= '0';
  end process;

  show_process : process
  begin
    show_output <= '1';
    wait until (count = 200);
    wait for 10 ns;
    show_output <= '0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    wait for 10 ns;

    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 5);
      write  (l, String'(" clk: "));
      write  (l, clk);


      write  (l, String'("| update: "));
      write  (l, update_in);
      write  (l, String'("| count_run: "));
      write  (l, count_running);


      write  (l, String'(" count_clear: "));
      write  (l, count_clear);

      write  (l, String'("| counter: "));
      write  (l, cnt);


      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;





end behaviour;
