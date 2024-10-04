library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08


--  Defines a testbench (without any ports)
entity timestamp_tb is
  generic (
    constant C_TIMESTAMP_WIDTH     : integer := 4
  );
end timestamp_tb;

architecture behaviour of timestamp_tb is
  component timestamp is
    generic (
      constant C_TIMESTAMP_WIDTH     : integer := C_TIMESTAMP_WIDTH
    );
    port (
      -- Clock Domain A: (Fast Clock)
      CLK_A_I	        : in  std_logic;
      RSTN_A_I	        : in  std_logic;
      TIMESTAMP_A_O       : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      -- Clock Domain B: (Slow Clock)
      CLK_B_I             : in  std_logic;
      RSTN_B_I            : in  std_logic;    
      TIMESTAMP_B_O       : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0)
    );
  end component;

  signal count       : integer := 0;
  signal aclk        : std_logic;
  signal aresetn     : std_logic;
  signal uclk        : std_logic;  
  signal uresetn     : std_logic;
  signal show_output : std_logic := '0';
  signal timestamp_a : std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);

  signal sync_a      : std_logic;  
  
begin
  uut: timestamp port map (
    CLK_A_I        => aclk,
    RSTN_A_I	   => aresetn,
    TIMESTAMP_A_O  => timestamp_a,
    CLK_B_I        => uclk,
    RSTN_B_I       => uresetn
  );

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

  uresetn_process : process
  begin
    uresetn <= '1';
    wait for 400 ns;
    uresetn <= '0';
    wait for 400 ns;
    uresetn <= '1';
    wait;
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
      write  (l, String'(" aclk: "));
      write  (l, aclk);
      write  (l, String'(" uclk: "));
      write  (l, uclk);
      write  (l, String'(" ts_a: "));
      hwrite  (l, timestamp_a);
      
      if (aresetn = '0') then
        write (l, String'(" (RST A)"));
      end if;
      if (uresetn = '0') then
        write (l, String'(" (RST U)"));
      end if;


      writeline(output, l);
    end if;
  end process;

end behaviour;
