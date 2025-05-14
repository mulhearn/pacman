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
    constant C_CONFIG_WIDTH : integer := 32
  );
end atc_mux_tb;

architecture behaviour of atc_mux_tb is
  component atc_mux is
    port (
   UCLK	               : in  std_logic;
    RSTN	               : in  std_logic;


    --input signal
    UPDATE_LEMO_A_I	        : in  std_logic;
    UPDATE_LEMO_B_I	        : in  std_logic;
    UPDATE_POKE_C_I	        : in  std_logic;
    UPDATE_POKE_D_I	        : in  std_logic;
    --CONFIG_I_F              : in  std_logic_vector(C_CONFIG_WIDTH-1 downto 0);
    --BUSY_F_O	              : out std_logic;

    --config of output (10 for G, 10 for H and 1 for timestamp)
    ATC_CONFIG_G            : in ATC_array := (others => (others => '0'));
    ATC_CONFIG_H            : in ATC_array := (others => (others => '0'));
    ATC_CONFIG_TS           : in  std_logic_vector(C_CONFIG_WIDTH-1 downto 0);

    --output
    ATC_G_O                 : out std_logic_vector(9 downto 0) := (others => '0');
    ATC_H_O                 : out std_logic_vector(9 downto 0) := (others => '0');
    TS_SYNC                 : out std_logic;

    ATC_G_COUNT             :  out  ATC_array;
    ATC_H_COUNT             :  out  ATC_array;
    ATC_TS_COUNT            :  out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    COUNT_START             : in std_logic := '0';
    COUNT_RESET             : in std_logic := '0';
   
    DEBUG_O                 : out std_logic_vector(7 downto 0)


    );
  end component;


  signal count    : integer := 0;
  signal show_output : std_logic := '0';

  signal clk             : std_logic;
  signal rst             : std_logic;
  signal update_lemo_a   : std_logic;
  signal update_lemo_b   : std_logic;
  signal update_poke_c   : std_logic;
  signal update_poke_d   : std_logic;
  signal update_g        : std_logic_vector(9 downto 0);
  signal update_h        : std_logic_vector(9 downto 0);
  signal update_ts       : std_logic;
  signal count_s    :std_logic;
  signal count_r    : std_logic;
  signal   atc_h         :  std_logic_vector(9 downto 0) := (others => '0'); 
  signal   atc_g         :  std_logic_vector(9 downto 0) := (others => '0'); 
  signal   ts_sy         :  std_logic;
  signal  config_g        :  ATC_array;
  signal  cfg_g_in        :  ATC_array;
  signal  config_h        :  ATC_array;
  signal  cfg_h_in        :  ATC_array;
  signal  debug           :  std_logic_vector(7 downto 0);
  signal  counter_g      : ATC_array;
  signal  counter_H      : ATC_array;
  signal  counter_ts      : std_logic_vector(31 downto 0);
begin
  uut: atc_mux port map (
    UCLK  => clk,
    RSTN  => rst,
    UPDATE_LEMO_A_I => update_lemo_a,
    UPDATE_LEMO_B_I => update_lemo_b,
    UPDATE_POKE_C_I => update_poke_c,
    UPDATE_POKE_D_I => update_poke_d,


    ATC_CONFIG_G    => cfg_g_in,      
    ATC_CONFIG_H    => cfg_h_in,      
    ATC_CONFIG_TS   => x"00000A12",      
    
    ATC_G_O      => atc_g,        
    ATC_H_O      => atc_h,       
    TS_SYNC      => ts_sy,
    ATC_G_COUNT  => counter_g,          
    ATC_H_COUNT  => counter_h,          
    ATC_TS_COUNT => counter_ts,           
    COUNT_START => count_s,
    COUNT_RESET => count_r,
    DEBUG_O    => debug

  );

  cfg_g_process : process
  begin
    cfg_g_in <= (others => (others => '0'));
    cfg_g_in(0) <= x"00000212";
    cfg_g_in(1) <= x"00000000";
    cfg_g_in(2) <= x"00000000";
    cfg_g_in(3) <= x"0000011F";
    cfg_g_in(4) <= x"0000021E";
    cfg_g_in(5) <= x"0000020F";
    cfg_g_in(6) <= x"00000102";
    cfg_g_in(7) <= x"00000112";
    cfg_g_in(8) <= x"00000201";
    cfg_g_in(9) <= x"00000202";
    wait;
  end process;

  cfg_h_process : process
  begin
    cfg_h_in <= (others => (others => '0'));
    cfg_h_in(0) <= x"0000010C";
    cfg_h_in(1) <= x"00000202";
    cfg_h_in(2) <= x"00000102";
    cfg_h_in(3) <= x"00000212";
    cfg_h_in(4) <= x"00000213";
    cfg_h_in(5) <= x"00000102";
    cfg_h_in(6) <= x"00000102";
    cfg_h_in(7) <= x"00000212";
    cfg_h_in(8) <= x"00000201";
    cfg_h_in(9) <= x"00000202";
    wait;
  end process;
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
    rst <= '0';
    wait for 20 ns;
    rst <= '1';
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
    wait for 10 ns;
    update_poke_c <= '1';
    wait for 10 ns;
    update_poke_c<= '0';
    wait;
  end process;



  update_d_process : process
  begin
    wait for 1 ns;
    update_poke_d <= '0';
    wait for 30 ns;
    update_poke_d <= '1';
    wait for 10 ns;
    update_poke_d <= '0';
    wait;
  end process;
  count_process:process
  begin
    wait for 10 ns;
    count_s <='1';
    wait for 1050 ns;
    count_s <='0';
    wait for 20 ns;
    count_r <= '1';
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
      write  (l, atc_g);

      write  (l, String'(" output_h: "));
      write  (l, atc_h);
      write  (l, String'(" output_ts: "));
      write  (l, ts_sy);
       write  (l, String'(" count_ts: "));
      write  (l, counter_ts);
      write  (l, String'(" update_ts: "));
      write  (l, debug(0));
      write  (l, String'(" config_ts: "));
      write  (l, debug(1));
      if (rst = '0') then
        write (l, String'(" (RESET)"));
      end if;
      writeline(output, l);
    end if;
  end process;





end behaviour;
