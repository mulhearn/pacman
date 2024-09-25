library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08


--  Defines a testbench (without any ports)
entity slow_broadcast_tb is
  generic (
    constant C_BROADCAST_WIDTH : integer := 10;
    constant C_CONFIG_WIDTH : integer := 32
  );
end slow_broadcast_tb;

architecture behaviour of slow_broadcast_tb is
  component slow_broadcast is
    generic (
      constant C_BROADCAST_WIDTH : integer := C_BROADCAST_WIDTH;
      constant C_CONFIG_WIDTH : integer := C_CONFIG_WIDTH
    );
    port (
      -- Clock Domain A: (Fast Clock)
      CLK_A_I	        : in  std_logic;
      RST_A_I	        : in  std_logic;
      UPDATE_A_I	        : in  std_logic;
      CONFIG_A_I          : in  std_logic_vector(C_CONFIG_WIDTH-1 downto 0);
      BUSY_A_O	        : out std_logic;

      -- Clock Domain B: (Slow Clock)
      CLK_B_I             : in  std_logic;
      BROADCAST_B_O          : out std_logic_vector(C_BROADCAST_WIDTH-1 downto 0);

      DEBUG_O             : out std_logic_vector(7 downto 0)
    );
  end component;

  signal count     : integer := 0;
  signal aclk      : std_logic;
  signal aresetn   : std_logic;
  signal uclk      : std_logic;
  signal rst       : std_logic;

  signal update    : std_logic := '0';
  signal busy      : std_logic;
  signal bcast    : std_logic_vector(C_BROADCAST_WIDTH-1 downto 0);
  signal debug    : std_logic_vector(7 downto 0);
  
  signal show_output : std_logic := '0';
begin
  uut: slow_broadcast port map (
    CLK_A_I  => aclk,
    RST_A_I  => rst,
    UPDATE_A_I => update,
    CONFIG_A_I => x"0008007A",
    BUSY_A_O => busy,
    CLK_B_I => uclk,
    BROADCAST_B_O => bcast,
    DEBUG_O => debug
  );

  rst <= not aresetn;

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
    wait for 1 ns;
    update <= '0';
    wait for 30 ns;
    update <= '1';
    wait for 10 ns;
    update <= '0';
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
    wait for 100 ns;

    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 5);
      write  (l, String'(" aclk: "));
      write  (l, aclk);
      write  (l, String'(" uclk: "));
      write  (l, uclk);

      write  (l, String'("| update: "));
      write  (l, update);
      write  (l, String'(" busy: "));
      write  (l, busy);
      write  (l, String'(" bcast: "));
      hwrite  (l,  ("00" & bcast));

      write  (l, String'("| u: "));
      write  (l, debug(0));
      write  (l, String'(" a: "));
      write  (l, debug(1));

      
      if (aresetn = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;





end behaviour;
