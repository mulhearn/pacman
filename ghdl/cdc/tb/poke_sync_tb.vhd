library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;

--  Defines a testbench (without any ports)
entity poke_sync_tb is
end poke_sync_tb;

architecture behaviour of poke_sync_tb is

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal uclk     : std_logic;

  signal update      : std_logic := '0';
  signal request     : std_logic;
  signal busy        : std_logic;
  signal reply       : std_logic;
  signal poke        : std_logic;
  signal payload     : std_logic_vector(C_REG16_WIDTH-1 downto 0);
  signal payload_req : std_logic_vector(C_REG16_WIDTH-1 downto 0);
  signal show_output : std_logic := '0';

  component update_request is
    port (
      CLK_I	 : in  std_logic;
      RST_I	 : in  std_logic;
      REQUEST_I  : in std_logic;
      BUSY_O     : out std_logic;
      REQUEST_O  : out std_logic;
      REPLY_A    : in std_logic
      );
  end component;

  component poke_sync is
    generic ( PAYLOAD_WIDTH : integer := 16 );
    port (
      CLK_I	  : in  std_logic;
      RST_I	  : in  std_logic;
      POKE_O      : out std_logic;
      PAYLOAD_O   : out std_logic_vector(PAYLOAD_WIDTH-1 downto 0);
      REPLY_O     : out std_logic;
      REQUEST_A   : in  std_logic;
      PAYLOAD_A   : in  std_logic_vector(PAYLOAD_WIDTH-1 downto 0)
    );
  end component;

begin
  dut0: update_request port map (
    CLK_I      => clk,
    RST_I      => rst,
    REQUEST_I  => update,
    BUSY_O     => busy,
    REQUEST_O  => request,
    REPLY_A    => reply
    );

  poke0: poke_sync port map (
    CLK_I      => uclk,
    RST_I      => rst,
    POKE_O     => poke,
    PAYLOAD_O  => payload,
    REPLY_O    => reply,
    REQUEST_A  => request,
    PAYLOAD_A  => payload_req
  );

  update_process : process
  begin
    payload_req <= x"0000";
    update <= '0';
    wait for 40 ns;
    payload_req <= x"03FF";
    update <= '1';
    wait for 10 ns;
    --payload_req <= x"0000";
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
      --write (l, String'("clk: "));
      --write (l, clk);
      write (l, String'(" fast: update: "));
      write (l, update);
      write (l, String'(" busy: "));
      write (l, busy);
      write (l, String'(" slow: poke:"));
      write (l, poke);
      write (l, String'(" payload: "));
      write (l, payload);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
