library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;

--  Defines a testbench (without any ports)
entity nchan_inverter_tb is
end nchan_inverter_tb;

architecture behaviour of nchan_inverter_tb is
  component nchan_inverter is
    port (
      CLK_I      : in  std_logic;
      RST_I      : in  std_logic;
      SIG_I      : in  std_logic_vector(C_NUM_TILE-1 downto 0);
      POLARITY_I : in  std_logic_vector(C_NUM_TILE-1 downto 0);
      SIG_O      : out std_logic_vector(C_NUM_TILE-1 downto 0)
      );
  end component;

  signal clk              : std_logic;
  signal rst              : std_logic;

  signal sig_in           : std_logic_vector(C_NUM_TILE-1 downto 0);
  signal sig_out          : std_logic_vector(C_NUM_TILE-1 downto 0);
  signal polarity         : std_logic_vector(C_NUM_TILE-1 downto 0);

  signal count            : integer := 0;
  signal show_output      : std_logic := '0';
begin
  uut: nchan_inverter port map (
    CLK_I	=> clk,
    RST_I 	=> rst,
    SIG_I	=> sig_in,
    POLARITY_I  => polarity,
    SIG_O	=> sig_out
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
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
  end process;

  dut_input_process : process
  begin
    sig_in <= (others => '0');
    polarity <= (others => '0');
    wait for 30 ns;
    polarity <= (others => '1');
    wait for 10 ns;
    sig_in <= (others => '1');
    wait for 10 ns;
    sig_in <= "1010101010";
    wait for 10 ns;
    sig_in <= "0101010101";
    wait for 10 ns;
    polarity <= "1010101010";
    wait for 10 ns;
    polarity <= "0101010101";
    wait;
  end process;

  show_process : process
  begin
    show_output <= '1';
    wait until (count = 10);
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
      write  (l, String'("| sig_i: "));
      write  (l, sig_in);
      write  (l, String'("| polarity_i: "));
      write  (l, polarity);
      write  (l, String'("| sig_o: "));
      write  (l, sig_out);

      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;





end behaviour;
