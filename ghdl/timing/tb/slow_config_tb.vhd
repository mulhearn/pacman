library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;

--  Defines a testbench (without any ports)
entity slow_config_tb is
end slow_config_tb;

architecture behaviour of slow_config_tb is

  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal uclk     : std_logic;

  signal update      : std_logic := '0';
  signal request     : std_logic;
  signal busy        : std_logic;
  signal reply       : std_logic;
  
  signal show_output : std_logic := '0';

  signal config        : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal polarity      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    
  signal config_shdw   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal polarity_shdw : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);    

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

  component slow_config is
    port (
      -- clock and active-high reset for slow clock domain:
      CLK_SLOW_I	    : in  std_logic;
      RST_SLOW_I	    : in  std_logic;
      SHADOW_CONFIG_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SHADOW_POLARITY_O    : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SHADOW_LOGIC_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SHADOW_DST_LEMO_A_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SHADOW_DST_LEMO_B_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SHADOW_DST_POKE_C_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SHADOW_DST_POKE_D_O  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SHADOW_DST_LOGIC_E_O : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      SHADOW_DST_LOGIC_F_O : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ASYNC_CONFIG_I       : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ASYNC_POLARITY_I     : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ASYNC_LOGIC_I        : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ASYNC_DST_LEMO_A_I   : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ASYNC_DST_LEMO_B_I   : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ASYNC_DST_POKE_C_I   : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ASYNC_DST_POKE_D_I   : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ASYNC_DST_LOGIC_E_I  : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ASYNC_DST_LOGIC_F_I  : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      REPLY_O         : out std_logic;
      ASYNC_REQUEST_I : in  std_logic
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

  poke0: slow_config port map (
    CLK_SLOW_I           => uclk,
    RST_SLOW_I           => rst,
    ASYNC_CONFIG_I       => config,
    ASYNC_POLARITY_I     => polarity,
    ASYNC_LOGIC_I        => (others => '0'),
    ASYNC_DST_LEMO_A_I   => (others => '0'),
    ASYNC_DST_LEMO_B_I   => (others => '0'),
    ASYNC_DST_POKE_C_I   => (others => '0'),
    ASYNC_DST_POKE_D_I   => (others => '0'),
    ASYNC_DST_LOGIC_E_I  => (others => '0'),
    ASYNC_DST_LOGIC_F_I  => (others => '0'),
    SHADOW_CONFIG_O      => config_shdw,
    SHADOW_POLARITY_O    => polarity_shdw,
    REPLY_O              => reply,
    ASYNC_REQUEST_I      => request
  );
  
  update_process : process
  begin
    config   <= x"AAAABBBB";
    polarity <= x"CCCCDDDD";
    update <= '0';
    wait for 40 ns;
    update <= '1';
    wait for 10 ns;
    update <= '0';
    wait for 300 ns;
    config   <= x"11112222";
    polarity <= x"33334444";
    wait for 10 ns;
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
      write (l, String'(" fast: u: "));
      write (l, update);
      write (l, String'(" b: "));
      write (l, busy);
      write (l, String'(" cfg: 0x"));
      hwrite (l, config);
      write (l, String'(" pol: 0x"));
      hwrite (l, polarity);
      write (l, String'(" slow: cfg: 0x"));
      hwrite (l, config_shdw);
      write (l, String'(" pol: 0x"));
      hwrite (l, polarity_shdw);
      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
