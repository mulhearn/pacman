library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
use work.common.all;
use work.atc_pkg.all;

--  Defines a testbench (without any ports)
entity atc_bridge_tb is
end atc_bridge_tb;

architecture behaviour of atc_bridge_tb is
  signal count    : integer := 0;
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal uclk     : std_logic;

  signal config_req  : std_logic;
  signal config      : atc_config_t;
  signal shadow      : atc_config_t;

  signal poke_c_req : std_logic;
  signal mask_c_req : std_logic_vector(C_NUM_TILE-1 downto 0);
  signal poke_c     : std_logic;
  signal mask_c     : std_logic_vector(C_NUM_TILE-1 downto 0);

  signal poke_d_req : std_logic;
  signal mask_d_req : std_logic_vector(C_NUM_TILE-1 downto 0);
  signal poke_d     : std_logic;
  signal mask_d     : std_logic_vector(C_NUM_TILE-1 downto 0);

  signal cnt_req    : std_logic;
  signal cnt_up     : std_logic;
  signal cnt_cmd    : std_logic_vector(C_BYTE_WIDTH-1 downto 0);
  signal cnt_src    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal cnt_out    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  signal status     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal timestamp  : std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);

  signal show_output : std_logic := '0';

  component atc_bridge is
    port (
      CLK_A_I       : in  std_logic;
      RST_A_I       : in  std_logic;
      CONFIG_REQ_I  : in  std_logic;
      CONFIG_I      : in  atc_config_t;
      POKE_C_I      : in  std_logic;  -- CDC
      MASK_C_I      : in  std_logic_vector(C_NUM_TILE-1 downto 0);
      POKE_D_I      : in  std_logic;  -- CDC
      MASK_D_I      : in  std_logic_vector(C_NUM_TILE-1 downto 0);
      COUNT_REQ_I   : in  std_logic;
      COUNT_CMD_I   : in  std_logic_vector(C_BYTE_WIDTH-1 downto 0);
      COUNT_O       : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      STATUS_O      : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      TIMESTAMP_O   : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);

      CLK_B_I       : in  std_logic;
      RST_B_I       : in  std_logic;
      CONFIG_O      : out atc_config_t;
      POKE_C_O      : out std_logic;
      MASK_C_O      : out std_logic_vector(C_NUM_TILE-1 downto 0);
      POKE_D_O      : out std_logic;
      MASK_D_O      : out std_logic_vector(C_NUM_TILE-1 downto 0);
      COUNT_REQ_O   : out std_logic;
      COUNT_CMD_O   : out std_logic_vector(C_BYTE_WIDTH-1 downto 0);
      COUNT_I       : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      TIMESTAMP_TOGGLE_I : in std_logic;
      TIMESTAMP_TSYNC_I  : in std_logic
    );
  end component;

begin

  dut0: atc_bridge port map (
    CLK_A_I          => clk,
    RST_A_I          => rst,
    CONFIG_REQ_I     => config_req,
    CONFIG_I         => config,
    POKE_C_I         => poke_c_req,
    MASK_C_I         => mask_c_req,
    POKE_D_I         => poke_d_req,
    MASK_D_I         => mask_d_req,
    COUNT_REQ_I      => cnt_req,
    COUNT_CMD_I      => b"01010001",
    COUNT_O          => cnt_out,
    STATUS_O         => status,
    TIMESTAMP_O      => timestamp,
    CLK_B_I          => uclk,
    RST_B_I          => rst,
    CONFIG_O         => shadow,
    POKE_C_O         => poke_c,
    MASK_C_O         => mask_c,
    POKE_D_O         => poke_d,
    MASK_D_O         => mask_d,
    COUNT_REQ_O      => cnt_up,
    COUNT_CMD_O      => cnt_cmd,
    COUNT_I          => cnt_src,
    TIMESTAMP_TOGGLE_I => '0',
    TIMESTAMP_TSYNC_I  => '0'
    );

  update_process : process
  begin
    cnt_src <= (others => '0');
    cnt_req <= '0';
    config_req <= '0';
    config.polarity <= x"0000ABCD";
    poke_c_req <= '0';
    poke_d_req <= '0';
    mask_c_req <= (others => '0');
    mask_d_req <= (others => '0');
    wait for 120 ns;
    config_req <= '1';
    poke_d_req <= '1';
    mask_d_req <= (others => '1');
    wait for 10 ns;
    config_req <= '0';
    poke_d_req <= '0';
    wait for 100 ns;
    cnt_src    <= x"1234ABCD";
    cnt_req    <= '1';
    poke_c_req <= '1';
    mask_c_req <= (others => '1');
    wait for 10 ns;
    cnt_req    <= '0';
    poke_c_req <= '0';
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
    wait until (count=75);
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
      write (l, count, left, 3);
      write (l, String'(" "));
      write (l, uclk);
      --write (l, String'("clk: "));
      --write (l, clk);
      write (l, String'(" uc: "));
      write (l, config_req);
      write (l, String'(" cp: 0x"));
      hwrite (l, config.polarity);
      write (l, String'(" sp: 0x"));
      hwrite (l, shadow.polarity);
      write (l, String'(" s: 0x"));
      hwrite (l, status);
      write (l, String'(" rc: "));
      write (l, poke_c_req);
      write (l, String'(" pc: "));
      write (l, poke_c);
      write (l, String'(" m: "));
      hwrite (l, "00" & mask_c);
      write (l, String'(" rd: "));
      write (l, poke_d_req);
      write (l, String'(" pd: "));
      write (l, poke_d);
      write (l, String'(" m: "));
      hwrite (l, "00" & mask_d);

      write (l, String'(" cr: "));
      write (l, cnt_req);
      write (l, String'(" cu: "));
      write (l, cnt_up);
      write (l, String'(" cc: "));
      write (l, cnt_cmd);
      write (l, String'(" cnt: 0x"));
      hwrite (l, cnt_out);



      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;

end behaviour;
