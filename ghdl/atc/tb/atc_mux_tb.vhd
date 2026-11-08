library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08
library work;
use work.common.all;


--  Defines a testbench (without any ports)
entity atc_mux_tb is
  generic (
    constant C_CONFIG_WIDTH     : integer := 32;
    constant C_NUM_TILE         : integer := 10

  );
end atc_mux_tb;

architecture behaviour of atc_mux_tb is
  component atc_mux is
    port (
    CLK_I	   : in  std_logic;
    RST_I	   : in  std_logic;
    LEMO_A_I	   : in  std_logic;
    LEMO_B_I	   : in  std_logic;
    POKE_C_I	   : in  std_logic;
    MASK_C_I       : in  std_logic_vector(C_NUM_TILE-1 downto 0);
    POKE_D_I	   : in  std_logic;
    MASK_D_I       : in  std_logic_vector(C_NUM_TILE-1 downto 0);
    LOGIC_E_I	   : in  std_logic;
    LOGIC_F_I	   : in  std_logic;
    DST_LEMO_A_I   : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_LEMO_B_I   : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_POKE_C_I   : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_POKE_D_I   : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_LOGIC_E_I  : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_LOGIC_F_I  : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    G_O            : out std_logic_vector(9 downto 0) := (others => '0');
    H_O            : out std_logic_vector(9 downto 0) := (others => '0');
    T_O            : out std_logic
  );
  end component;

  signal count    : integer := 0;
  signal show_output : std_logic := '0';

  signal clk             : std_logic;
  signal rst             : std_logic;

  -- input stimuli:
  signal update_lemo_a   : std_logic;
  signal update_lemo_b   : std_logic;
  signal update_poke_c   : std_logic;
  signal update_poke_d   : std_logic;

  -- mux outputs:
  signal   h   :  std_logic_vector(9 downto 0) := (others => '0');
  signal   g   :  std_logic_vector(9 downto 0) := (others => '0');
  signal   t  :  std_logic;



begin
  uut: atc_mux port map (
    CLK_I         => clk,
    RST_I         =>  rst,
    LEMO_A_I	  =>   update_lemo_a,
    LEMO_B_I	  =>   update_lemo_b,
    POKE_C_I	  =>   update_poke_c,
    MASK_C_I      =>   "1111111101",
    POKE_D_I      =>   update_poke_d,
    MASK_D_I      =>   "1111110111",
    LOGIC_E_I	  =>    '0' ,
    LOGIC_F_I	  =>    '0' ,
    DST_LEMO_A_I  =>  x"02FF0601",
    DST_LEMO_B_I  =>  x"02FF0501",
    DST_POKE_C_I  =>  x"00FF0022",
    DST_POKE_D_I  => x"03FF0101",
    DST_LOGIC_E_I => x"00FF0304",
    DST_LOGIC_F_I => x"00FF0404",
    G_O           => g,
    H_O           => h,
    T_O           => t
  );

  aclk_process : process
  begin
    count <= count + 1;
    clk <= '1';
    wait for 10 ns;
    clk <= '0';
    wait for 10 ns;
  end process;

  aresetn_process : process
  begin
    rst <= '1';
    wait for 20 ns;
    rst <= '0';
    wait;
  end process;


  update_a_process : process
  begin
    update_lemo_a <= '0';
    --wait for 100 ns;
    --update_lemo_a <= '1';
    --wait for 20 ns;
    update_lemo_a <= '0';
    wait;

  end process;


  update_b_process : process
  begin
    wait for 1 ns;
    update_lemo_b <= '0';
    wait for 100 ns;
    update_lemo_b <= '1';
    wait for 20 ns;
    update_lemo_b <= '0';
    wait;
  end process;


  update_c_process : process
  begin
    wait for 1 ns;
    update_poke_c <= '0';
    wait for 20 ns;
    update_poke_c <= '1';
    wait for 30 ns;
    update_poke_c<= '0';
    wait;
  end process;

  update_d_process : process
  begin
    wait for 1 ns;
    update_poke_d <= '0';
    wait for 50 ns;
    update_poke_d <= '1';
    wait for 20 ns;
    update_poke_d <= '0';
    wait;
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
    wait for 20 ns;

    if (show_output='1') then
      write (l, String'("c: "));
      write (l, count, left, 5);
      write  (l, String'(" uclk: "));
      write  (l, clk);

      write  (l, String'("| lemo_a: "));
      write  (l, update_lemo_a);
      write  (l, String'(" lemo_b: "));
      write  (l, update_lemo_b);
      write  (l, String'(" poke_c: "));
      write  (l, update_poke_c);
      write  (l, String'(" poke_d: "));
      write  (l, update_poke_d);

      write  (l, String'("| output_g: "));
      write  (l, g);

      write  (l, String'(" output_h: "));
      write  (l, h);
      write  (l, String'(" output_t: "));
      write  (l, t);

      if (rst = '1') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;





end behaviour;
