library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08

entity external_update_tb is
end external_update_tb;

architecture behaviour of external_update_tb is
  component external_update is
    port (
     
      UPDATE_E_I	        : in  std_logic;
      CLK_F_I             : in  std_logic;
      RSTN                : in  std_logic;
      PULSE_OUT           : out std_logic;
      COUNT_P             : out std_logic_vector(31 downto 0);
      DEBUG               : out std_logic_vector(7 downto 0)
    );
  end component;
  
  signal update_e    : std_logic; -- input signal

  signal clk_b         : std_logic; -- clk of board frequency
  signal rst           : std_logic;
  signal aresetn       :std_logic;
  signal pulse         : std_logic; 
  signal pulse_count       : std_logic_vector(31 downto 0);
  signal debug       : std_logic_vector(7 downto 0);
  signal show_output   : std_logic := '0';
  signal count         : integer := 0;

  begin
  uut: external_update port map (
    CLK_F_I  => clk_b,
    RSTN     => aresetn,
    UPDATE_E_I => update_e,
    --CONFIG_A_I => x"0008007A",
  
    PULSE_OUT => pulse,
    COUNT_P => pulse_count,
    DEBUG =>debug
  );

  rst <= not aresetn;

  clk_process : process
  begin
    count <= count + 1;
    clk_b <= '1';
    wait for 5 ns;
    clk_b <= '0';
    wait for 5 ns;
  end process;



  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 10 ns;
    aresetn <= '1';
    wait for 120 ns;
    aresetn <= '0';
    wait for 10 ns;
    aresetn <= '1';
    
    wait;
  end process;


  update_process : process
  begin
    wait for 1 ns;
    update_e <= '0';
    wait for 10 ns;
    update_e <= '1';
    wait for 70 ns;
    update_e <= '0';
    --wait;
  end process;

  show_process : process
  begin
    show_output <= '1';
    wait until (count = 100);
    wait for 10 ns;
    show_output <= '0';
    wait;
  end process; 


  
  output_process : process
    variable l : line;
  begin
    wait for 50 ns;

    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 5);
      write  (l, String'(" clk_b: "));
      write  (l, clk_b);
      write  (l, String'("| update_e: "));
      write  (l, update_e);
 

      write  (l, String'(" pulse: "));
      write  (l, pulse);
      write  (l, String'("| sync: "));
      write  (l, debug(0));
      write  (l, String'(" old: "));
      write  (l, debug(1));
      write  (l, String'("| count: "));
      write  (l, pulse_count);


      
      if (aresetn = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;
 
end behaviour;  
