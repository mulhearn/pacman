library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity atc_counter_tb is
end atc_counter_tb;

architecture behaviour of atc_counter_tb is
  component atc_counter is
    port (
      CLK_I	               : in  std_logic;
      RST_I	               : in  std_logic;


     --input signal
      LEMO_A_I	            : in  std_logic;
      LEMO_B_I	            : in  std_logic;
      POKE_C_I	            : in  std_logic;
      POKE_D_I	            : in  std_logic;
      G_I                   : in std_logic_vector(C_NUM_TILE -1  downto 0) ;
      H_I                   : in std_logic_vector(C_NUM_TILE -1 downto 0) ;

      UPDATE_I              : in  std_logic;
      COMMAND_I             : in  std_logic_vector(7 downto 0);

    --output
      COUNT_O               : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)


  );
  end component;

  signal clk              : std_logic;
  signal rst              : std_logic;

  signal incr_a         : std_logic;
  signal incr_b         : std_logic;
  signal incr_c         : std_logic;
  signal incr_d         : std_logic;
  signal incr_g         : std_logic_vector(C_NUM_TILE-1 downto 0);
  signal incr_h         : std_logic_vector(C_NUM_TILE-1 downto 0);
  signal update         : std_logic;
  signal command        : std_logic_vector(7 downto 0);
  signal count_o        : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal poke_in        : std_logic;
  signal count          : integer := 0;
  signal show_output    : std_logic := '0';

begin
  uut: atc_counter port map (
    CLK_I	     => clk,
    RST_I 	     => rst,
    LEMO_A_I	     => incr_a,
    LEMO_B_I	     => incr_b,
    POKE_C_I	     => incr_c,
    POKE_D_I	     => incr_d,
    G_I              => incr_g,
    H_I              => incr_h,
    UPDATE_I         => update,
    COMMAND_I        => command,
    COUNT_O          => count_o
  );

  areset_process : process
  begin
    rst <= '1';
    wait for 200 ns;
    rst <= '0';
    wait;
  end process;

  clk_process : process
  begin
    count <= count + 1;
    clk <= '0';
    wait for 50 ns;
    clk <= '1';
    wait for 50 ns;
  end process;

  proc_command : process
  begin
    update <= '0';
    command <= "00000000";
    wait for 500 ns    ;
    update <= '1';
    command <= "01010001";
    wait for 100 ns    ;
    update <= '0';
    command <= "00000000";
    wait for 500 ns    ;
    update <= '1';
    command <= "01010001";
    wait for 100 ns;
    update <= '1';
    command <= "00110000";
    wait for 100 ns;
    update <= '1';
    command <= "00010000";
    wait for 100 ns;
    update <= '1';
    command <= "01010001";
    wait for 100 ns;
    update <= '0';
    command <= "00000000";
    wait for 100 ns;
    update <= '1';
    command <= "00100000";
    wait for 100 ns;
    update <= '1';
    command <= "01010001";
    wait for 100 ns;
    update <= '0';
    command <= "00000000";
    wait for 500 ns;
    update <= '1';
    command <= "01010001";
    wait for 100 ns;
    update <= '1';
    command <= "01110000";
    wait for 100 ns;
    update <= '0';
    command <= "00000000";
    wait;
  end process;

  incr_in_a : process
  begin
    wait for 10 ns;
    incr_a <= '0';
    wait for 300 ns;
    incr_a <= '1';
    wait for 100 ns;
    incr_a <= '0';
    wait for 300 ns;
    incr_a <= '1';
  end process;

  incr_in_g : process
  begin
    incr_g <= (others => '0');
    wait for 10 ns;
    incr_g(1) <= '0';
    wait for 200 ns;
    incr_g(1) <= '1';
    wait for 100 ns;
    incr_g(1) <= '0';
    wait for 200 ns;
    incr_g(1) <= '1';
    wait for 100 ns;
    incr_g(1) <= '0';
  end process;
  show_process : process
  begin
    show_output <= '1';
    wait until (count = 200);
    wait for 100 ns;
    show_output <= '0';
    wait;
  end process;

  output_process : process
    variable l : line;
  begin
    wait for 100 ns;

    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 5);
      write  (l, String'(" clk: "));
      write  (l, clk);


      write  (l, String'("| incr_a: "));
      write  (l, incr_a);
      write  (l, String'("| incr_g: "));
      write  (l, incr_g);
      write  (l, String'("| up: "));
      write  (l, update);
      write  (l, String'(" cmd: "));
      write  (l, command);
     -- write  (l, String'(" count_stop: "));
     -- write  (l, not start);

      --write  (l, String'(" count_reset: "));
      --write  (l, count_reset);

      write  (l, String'("| counter: 0x"));
      hwrite  (l, COUNT_O);


      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;





end behaviour;
