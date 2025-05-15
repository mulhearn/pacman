library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;


entity atc_mux is
  generic (
    constant C_CONFIG_WIDTH     : integer := 32
  );

  port (
    UCLK	               : in  std_logic;
    RSTN	               : in  std_logic;


    --input signal
    UPDATE_LEMO_A_I	          : in  std_logic;
    UPDATE_LEMO_B_I	          : in  std_logic;
    UPDATE_POKE_C_I	          : in  std_logic;
    UPDATE_POKE_D_I	          : in  std_logic;
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
end;

architecture behavioral of atc_mux is
  component atc_mux_single is
    port (
    UCLK	               : in  std_logic;
    RSTN	               : in  std_logic;


    --input signal
    UPDATE_LEMO_A_I	        : in  std_logic;
    UPDATE_LEMO_B_I	        : in  std_logic;
    UPDATE_POKE_C_I	        : in  std_logic;
    UPDATE_POKE_D_I	        : in  std_logic;

    CONFIG_ATC             : in std_logic_vector(C_CONFIG_WIDTH-1 downto 0);

    --output
    ATC_OUT                 : out std_logic;
    ATC_COUNT               : out std_logic_vector(C_CONFIG_WIDTH-1 downto 0);
    COUNT_START           : in std_logic := '0';
    COUNT_RESET            : in std_logic := '0'
    );
  end component;

  --signal clk           : std_logic;
  --signal rst           : std_logic;
  signal update_lemo_a   : std_logic;
  signal update_lemo_b   : std_logic;
  signal update_poke_c   : std_logic;
  signal update_poke_d   : std_logic;
  signal update_g        : std_logic_vector(9 downto 0);
  signal update_h        : std_logic_vector(9 downto 0);
  signal update_ts       : std_logic;
  --signal busy_f          : std_logic;

  signal config_g          :  ATC_array;
  signal config_h          :  ATC_array;
  signal config_ts         :  std_logic_vector(C_CONFIG_WIDTH-1 downto 0);
  signal counter_g          :  ATC_array;
  signal counter_h          :  ATC_array;
  signal counter_ts         :  std_logic_vector(C_CONFIG_WIDTH-1 downto 0);
begin
  --clk    <= UCLK;
  --rst    <= not RSTN;
  update_lemo_a <= UPDATE_LEMO_A_I;
  update_lemo_b <= UPDATE_LEMO_B_I;
  update_poke_c <= UPDATE_POKE_C_I;
  update_poke_d <= UPDATE_POKE_D_I;  
  --BUSY_F_O <= busy_f;
  config_g    <= ATC_CONFIG_G;
  config_h    <= ATC_CONFIG_H;
  config_ts   <= ATC_CONFIG_TS;
  ATC_G_COUNT  <=counter_g;
  ATC_H_COUNT  <=counter_h;
  ATC_TS_COUNT <=counter_ts;
  
  DEBUG_O(0) <= update_ts;
  DEBUG_O(1) <= config_ts(4);
  --DEBUG_O(2) <= ;
  DEBUG_O(7 downto 2) <= (others => '0');  
  -- Output signal for G
  -- (A&a) or (B&b) or (C&c) or (D&d) 
  -- A come from config and a is the input signal
  gen_g:for i in 0 to 9 generate
    update_g(i) <= (config_g(i)(0) and update_lemo_a) or (config_g(i)(1) and update_lemo_b) or (config_g(i)(2) and update_poke_c) or (config_g(i)(3) and update_poke_d);
    mux_g:atc_mux_single
      port map (
        UCLK            => UCLK,
        RSTN            => RSTN,
        UPDATE_LEMO_A_I => update_lemo_a,
        UPDATE_LEMO_B_I => update_lemo_b,
        UPDATE_POKE_C_I => update_poke_c,
        UPDATE_POKE_D_I => update_poke_d,
        CONFIG_ATC      => config_g(i),
        ATC_OUT         => ATC_G_O(i),
        ATC_COUNT       => counter_g(i),
        COUNT_START     => COUNT_START,
        COUNT_RESET     => COUNT_RESET
      );
  end generate;


  -- Output signal for H
  gen_h:for i in 0 to 9 generate
    update_h(i) <= (config_h(i)(0) and update_lemo_a) or (config_h(i)(1) and update_lemo_b) or (config_h(i)(2) and update_poke_c) or (config_h(i)(3) and update_poke_d);
    mux_h:atc_mux_single
      port map (
        UCLK            => UCLK,
        RSTN            => RSTN,
        UPDATE_LEMO_A_I => update_lemo_a,
        UPDATE_LEMO_B_I => update_lemo_b,
        UPDATE_POKE_C_I => update_poke_c,
        UPDATE_POKE_D_I => update_poke_d,
        CONFIG_ATC      => config_h(i),
        ATC_OUT         => ATC_H_O(i),
        ATC_COUNT       => counter_h(i),
        COUNT_START     => COUNT_START,
        COUNT_RESET     => COUNT_RESET
      );
  end generate;
  
  -- Output signal for TS
  update_ts <= (config_ts(0) and update_lemo_a) or (config_ts(1) and update_lemo_b) or (config_ts(2) and update_poke_c) or (config_ts(3) and update_poke_d); 
  mux_ts:atc_mux_single
    port map (
      UCLK            => UCLK,
      RSTN            => RSTN,
      UPDATE_LEMO_A_I => update_lemo_a,
      UPDATE_LEMO_B_I => update_lemo_b,
      UPDATE_POKE_C_I => update_poke_c,
      UPDATE_POKE_D_I => update_poke_d,
      CONFIG_ATC      => config_ts,
      ATC_OUT         =>  TS_SYNC,
      ATC_COUNT       =>  counter_ts,
      COUNT_START     => COUNT_START,
      COUNT_RESET     => COUNT_RESET
      );

 



end;
