library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;

--  Defines a testbench (without any ports)
entity slow_poke_tb is
end slow_poke_tb;

architecture behaviour of slow_poke_tb is

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal uclk     : std_logic;

  signal update      : std_logic := '0';
  signal request     : std_logic;
  signal busy        : std_logic;
  signal reply       : std_logic;
  signal poke        : std_logic;
  signal mask        : std_logic_vector(C_REG16_WIDTH-1 downto 0);
  
  signal show_output : std_logic := '0';
  
  component update_request is
    port (
      CLK_I	    : in  std_logic;
      RST_I	    : in  std_logic;
      UPDATE_I      : in std_logic;
      BUSY_O        : out std_logic;
      REQUEST_O     : out std_logic;
      ASYNC_REPLY_I : in std_logic
      );
  end component;

  component slow_poke is
    port (
      -- clock and active-high reset for slow clock domain:
      CLK_SLOW_I	    : in  std_logic;
      RST_SLOW_I	    : in  std_logic;

      PULSE_CYCLES_I  : in  std_logic_vector(C_REG16_WIDTH-1 downto 0);
    
      -- poke and associated mask in the slow clock domain:
      POKE_O          : out std_logic;
      MASK_O          : out std_logic_vector(C_REG16_WIDTH-1 downto 0);

      -- interface to request in the fast clock domain
      REPLY_O         : out std_logic;
      ASYNC_REQUEST_I : in  std_logic;
      ASYNC_MASK_I    : in  std_logic_vector(C_REG16_WIDTH-1 downto 0) 
    );
  end component;

begin
  dut0: update_request port map (
    CLK_I          => clk,
    RST_I          => rst,
    UPDATE_I       => update,
    BUSY_O         => busy,
    REQUEST_O      => request,
    ASYNC_REPLY_I  => reply
    );

  poke0: slow_poke port map (
    CLK_SLOW_I      => uclk,
    RST_SLOW_I      => rst,
    PULSE_CYCLES_I  => x"0003",
    POKE_O          => poke,
    MASK_O          => mask,    
    REPLY_O         => reply,
    ASYNC_REQUEST_I => request,
    ASYNC_MASK_I    => x"03FF"
  );
  
  update_process : process
  begin
    update <= '0';
    wait for 40 ns;
    update <= '1';
    wait for 10 ns;
    update <= '0';
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
    wait until (count=100);
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
      --write (l, String'("clk: "));
      --write (l, clk);
      write (l, String'(" fast: update: "));
      write (l, update);
      write (l, String'(" busy: "));
      write (l, busy);      
      write (l, String'(" slow: poke:"));
      write (l, poke);
      write (l, String'(" mask: "));
      write (l, mask);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
