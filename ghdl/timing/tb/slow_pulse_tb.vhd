library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08


--  Defines a testbench (without any ports)
entity slow_pulse_tb is
  generic (
    constant C_CONFIG_WIDTH : integer := 32
  );
end slow_pulse_tb;

architecture behaviour of slow_pulse_tb is
  component slow_pulse is
    generic (
      constant C_CONFIG_WIDTH : integer := C_CONFIG_WIDTH
    );
    port (
    -- Fast Clock Domain :
    CLK_F_I	                : in  std_logic;
    RSTN_F_I	              : in  std_logic;
    UPDATE_I	              : in  std_logic;
   
    BUSY_F_O	              : out std_logic;

    CONFIG_POL              : in  std_logic :='0';


    -- Slow Clock Domain : 
    CLK_S_I                 : in  std_logic;
    PULSE_O                 : out std_logic;
    DEBUG_O                 : out std_logic_vector(7 downto 0);

    COUNT_O                 : out std_logic_vector(31 downto 0);
    COUNT_START             : in std_logic := '0';
    COUNT_RESET             : in std_logic := '0'
    );
  end component;

  signal count     : integer := 0;
  signal aclk      : std_logic;
  signal aresetn   : std_logic;
  signal uclk      : std_logic;
  signal rst       : std_logic;
  signal update_in   : std_logic;
  signal sig_out   : std_logic;
  signal busy      : std_logic;
  signal debug     : std_logic_vector(7 downto 0);
  signal cout      : std_logic_vector(31 downto 0);
  signal show_output_f : std_logic := '0';
  signal show_output_s : std_logic := '0';
  signal count_s    :std_logic;
  signal count_r    : std_logic;
begin
  uut: slow_pulse port map (
    CLK_F_I  => aclk,
    RSTN_F_I  => aresetn,
    UPDATE_I	 => update_in ,
    CONFIG_POL => '0',
    BUSY_F_O => busy,
    CLK_S_I => uclk,
    PULSE_O =>sig_out,
    DEBUG_O => debug,
    COUNT_O => cout,
    COUNT_START => count_s,
    COUNT_RESET => count_r
  );

  --clock A is 10ns period
  aclk_process : process
  begin
    count <= count + 1;
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 20 ns;
    aresetn <= '1';
    wait;
  end process;

  uclk_process : process
  begin
    uclk <= '1';
    wait for 50 ns;
    uclk <= '0';
    wait for 50 ns;
  end process;

  update_process : process
  begin
    wait for 100 ns;
    update_in <= '1';
    wait for 10 ns;
    update_in <= '0';
    wait for 1000 ns;
    update_in <= '1';
    wait for 10 ns;
    update_in <= '0';
    wait;
  end process;

  count_process:process
  begin
    wait for 10 ns;
    count_s <='1';
    wait for 1550 ns;
    count_s <='0';
    wait for 20 ns;
    count_r <= '1';
    wait;
  end process;

  show_process : process
  begin
    show_output_s <= '1';
    show_output_f <= '0';
    wait until (count = 10);
    show_output_s <= '0';
    show_output_f <= '1';
    wait until (count = 170);
    show_output_s <= '1';
    show_output_f <= '0';
    wait for 10 ns;
    show_output_s <= '0';
    show_output_f <= '0';
    wait;
  end process;

  output_slow_process : process
    variable l : line;
  begin
    wait for 100 ns;

    if (show_output_s='1') then
      wait for 10 ns;
      write (l, String'("c: "));
      write (l, count, left, 5);
      write  (l, String'(" aclk: "));
      write  (l, aclk);
      write  (l, String'(" uclk: "));
      write  (l, uclk);
      write  (l, String'("| update_in: "));
      write  (l, update_in);
      
    
     

      write  (l, String'(" pulse: "));
      write  (l, sig_out);
      write  (l, String'("| request: "));
      write  (l, debug(0));
      write  (l, String'(" busy: "));
      write  (l, busy);
      write  (l, String'(" request_sync: "));
      write  (l, debug(1));
      write  (l, String'("| ack: "));
      write  (l, debug(2));
      write  (l, String'(" ack_sync: "));
      write  (l, debug(3));
      write  (l, String'(" count_out: "));
      write  (l, cout);
      
      if (aresetn = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;


  output_fast_process : process
    variable l : line;
  begin
    wait for 10 ns;

    if (show_output_f='1') then
      write (l, String'("c: "));
      write (l, count, left, 5);
      write  (l, String'(" aclk: "));
      write  (l, aclk);
      write  (l, String'(" uclk: "));
      write  (l, uclk);
      write  (l, String'("| update_in: "));
      write  (l, update_in);
      
    
     

      write  (l, String'(" pulse: "));
      write  (l, sig_out);
      write  (l, String'("| request: "));
      write  (l, debug(0));
      write  (l, String'(" busy: "));
      write  (l, busy);
      write  (l, String'(" request_sync: "));
      write  (l, debug(1));
      write  (l, String'("| ack: "));
      write  (l, debug(2));
      write  (l, String'(" ack_sync: "));
      write  (l, debug(3));
      write  (l, String'(" count_out: "));
      write  (l, cout);
      write  (l, String'(" count_reset: "));
      write  (l, count_r);
      
      if (aresetn = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;  
  




end behaviour;
