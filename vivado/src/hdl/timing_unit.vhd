library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity timing_unit is
  port (
    ACLK                   : in std_logic; -- fast clock
    ARESETN                : in std_logic;
    UCLK_I                 : in std_logic; -- slow clock


    --lemo signal
    LEMO_A_I                : in std_logic;
    LEMO_B_I                : in std_logic;

    S_REGBUS_RB_RADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	  : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_RUPDATE   : in  std_logic;
    S_REGBUS_RB_RACK      : out std_logic;
    
    S_REGBUS_RB_WUPDATE   : in  std_logic;
    S_REGBUS_RB_WADDR	  : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	  : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK      : out std_logic;

    TIMESTAMP_O           : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
    GLB_CLK_O             : out std_logic;
    G_O                   : out std_logic_vector(C_NUM_TILE-1 downto 0);
    H_O                   : out std_logic_vector(C_NUM_TILE-1 downto 0);
    TS_SYNC_O             : out std_logic;

    DEBUG                : out std_logic_vector(7 downto 0)
  );
end timing_unit;

architecture behaviour of timing_unit is
  component timing_registers is
    port (
    ACLK	                 : in std_logic;
    ARESETN	                 : in std_logic;

    S_REGBUS_RB_RUPDATE          : in  std_logic;
    S_REGBUS_RB_RADDR	         : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	         : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK             : out std_logic;
    
    S_REGBUS_RB_WUPDATE          : in  std_logic;
    S_REGBUS_RB_WADDR	         : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK             : out std_logic;

    ATC_POKE_C                   : out std_logic;
    ATC_POKE_D                   : out std_logic;
    ATC_CONFIG_G                 : out ATC_array := (others => (others => '0'));
    ATC_CONFIG_H                 : out ATC_array := (others => (others => '0'));
    ATC_CONFIG_TS                : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    ATC_POLARITY                 : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    STATUS_I               : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    TIMESTAMP_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);   

    LEMO_A_COUNT           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    LEMO_B_COUNT           : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    --count of input in slow domain
    LEMO_A_COUNT_S         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    LEMO_B_COUNT_S         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    POKE_C_COUNT_S         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    POKE_D_COUNT_S         : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    --count of output
    ATC_G_COUNT           :  in  ATC_array;
    ATC_H_COUNT           :  in  ATC_array;
    ATC_TS_COUNT          :  in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    COUNT_START           :  out std_logic := '0';
    COUNT_RESET           :  out std_logic := '0'
    );
  end component;
 
  component atc_mux is
    generic (
      constant C_CONFIG_WIDTH : integer := C_RB_DATA_WIDTH
    );
    port (
    UCLK	               : in  std_logic;
    RSTN	               : in  std_logic;


    --input signal
    UPDATE_LEMO_A_I	        : in  std_logic;
    UPDATE_LEMO_B_I	        : in  std_logic;
    UPDATE_POKE_C_I	        : in  std_logic;
    UPDATE_POKE_D_I	        : in  std_logic;


    --config of output (10 for G, 10 for H and 1 for timestamp)
    ATC_CONFIG_G                : in ATC_array := (others => (others => '0'));
    ATC_CONFIG_H                : in ATC_array := (others => (others => '0'));
    ATC_CONFIG_TS               : in std_logic_vector(C_CONFIG_WIDTH-1 downto 0);

    --output
    ATC_G_O                     : out std_logic_vector(9 downto 0) := (others => '0');
    ATC_H_O                     : out std_logic_vector(9 downto 0) := (others => '0');
    TS_SYNC                     : out std_logic;

    ATC_G_COUNT                 :  out  ATC_array;
    ATC_H_COUNT                 :  out  ATC_array;
    ATC_TS_COUNT                :  out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    COUNT_START                 :  in std_logic := '0';
    COUNT_RESET                 :  in std_logic := '0';

    DEBUG_O                     : out std_logic_vector(7 downto 0)


    );
  end component;

  component external_update is
    port (     
      UPDATE_E_I	        : in  std_logic;
      CLK_F_I                   : in  std_logic;
      RSTN                      : in  std_logic;
      PULSE_OUT                 : out std_logic;
      COUNT_P                   : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      COUNT_START               : in std_logic := '0';
      COUNT_RESET               : in std_logic := '0';
      DEBUG                     : out std_logic_vector(7 downto 0)
    );
  end component;
  
 

  component slow_pulse is
    generic (
      constant C_CONFIG_WIDTH : integer := C_RB_DATA_WIDTH
    );
    port (
    -- Fast Clock Domain :
    CLK_F_I	              : in  std_logic;
    RSTN_F_I	              : in  std_logic;
    UPDATE_I	              : in  std_logic;
    BUSY_F_O	              : out std_logic;
    CONFIG_POL                : in  std_logic :='0';
    -- Slow Clock Domain : 
    CLK_S_I                   : in  std_logic;
    PULSE_O                   : out std_logic;
    DEBUG_O                   : out std_logic_vector(7 downto 0);
    COUNT_O                   : out std_logic_vector(31 downto 0);
    COUNT_START               : in  std_logic := '0';
    COUNT_RESET               : in  std_logic := '0'
    );
  end component;


  component timestamp is
    generic (
      constant C_TIMESTAMP_WIDTH     : integer := C_TIMESTAMP_WIDTH
    );
    port (
      -- Clock Domain A: (Fast Clock)
      CLK_A_I	             : in  std_logic;
      RSTN_A_I	             : in  std_logic;
      TIMESTAMP_A_O          : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
      -- Clock Domain B: (Slow Clock)
      CLK_B_I                : in  std_logic;
      RSTN_B_I               : in  std_logic;    
      TIMESTAMP_B_O          : out std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0)
    );
  end component;

  signal clk            : std_logic;
  signal rst            : std_logic;
  signal uresetn        : std_logic;
  signal tstamp         : std_logic_vector(C_TIMESTAMP_WIDTH-1 downto 0);
  signal status         : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');  

 --input signal and cfg
  signal atc_ts_cfg     :  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal atc_g_cfg      :  ATC_array  ;
  signal atc_h_cfg      :  ATC_array  ;
  signal polarity_cfg   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) ;
 
  --fast domain
  signal lemo_a_f         : std_logic; 
  signal lemo_b_f         : std_logic;
  signal poke_c_f         : std_logic;
  signal poke_d_f         : std_logic;

  --slow domain
  signal lemo_a_s         : std_logic; 
  signal lemo_b_s         : std_logic;
  signal poke_c_s         : std_logic;
  signal poke_d_s         : std_logic;




--output and cfg
  signal   atc_h         :  std_logic_vector(9 downto 0) := (others => '0'); 
  signal   atc_g         :  std_logic_vector(9 downto 0) := (others => '0'); 
  signal   ts_sy         :  std_logic;

 -- input count
  signal lemo_a_c       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0); -- count lemo_a input origin
  signal lemo_b_c       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0); -- count lemo_b input origin

-- counter of input in slow domain
  signal count_a_s      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal count_b_s      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal count_c_s      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal count_d_s      : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  signal atc_g_c        : ATC_array;
  signal atc_h_c        : ATC_array;
  signal atc_ts_c       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal counter_start  : std_logic;
  signal counter_reset  : std_logic;
  signal start_meta     : std_logic; -- metastable
  signal start_sync     : std_logic; -- likely stable
  signal reset_meta     : std_logic; -- metastable
  signal reset_sync     : std_logic; -- likely stable
  signal reset_s        : std_logic; -- reset for slow clock domain
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of start_meta: signal is "TRUE";
  attribute ASYNC_REG of start_sync: signal is "TRUE";
  attribute ASYNC_REG of reset_meta: signal is "TRUE";
  attribute ASYNC_REG of reset_sync: signal is "TRUE";
  
begin

  TIMESTAMP_O <= tstamp;
  GLB_CLK_O <= UCLK_I;
  rst <= not ARESETN;
  clk <= ACLK;
  DEBUG(0) <= lemo_b_f;
  DEBUG(1) <= lemo_b_s;
  DEBUG(7 downto 2) <= (others => '0');  
  TS_SYNC_O <= ts_sy;
  
  
  uut0: timing_registers port map (
    ACLK                => ACLK,   
    ARESETN             => ARESETN,
    S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,  
    S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,   
    S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,   
    S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,    
    S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE, 
    S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,   
    S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,   
    S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,

    ATC_POKE_C          => poke_c_f ,      
    ATC_POKE_D          => poke_d_f,
    ATC_CONFIG_G        => atc_g_cfg,
    ATC_CONFIG_H        => atc_h_cfg,
    ATC_CONFIG_TS       => atc_ts_cfg,
    ATC_POLARITY        => polarity_cfg,
    STATUS_I            => status,
    TIMESTAMP_I         => tstamp,
    LEMO_A_COUNT        => lemo_a_c,
    LEMO_B_COUNT        => lemo_b_c,
    LEMO_A_COUNT_S      => count_a_s,
    LEMO_B_COUNT_S      => count_b_s,
    POKE_C_COUNT_S      => count_c_s,
    POKE_D_COUNT_S      => count_d_s,
    ATC_G_COUNT         => atc_g_c, 
    ATC_H_COUNT         => atc_h_c,  
    ATC_TS_COUNT        => atc_ts_c,
    COUNT_START         => counter_start,
    COUNT_RESET         => counter_reset
  );
  -- double flop synchronization of counter signal (fast clock)
  -- counter start 
  process(clk, rst)
  begin
    if (rst = '1') then
      start_meta <= '0';
      start_sync <= '0';
    elsif (rising_edge(clk)) then
      start_meta <= counter_start;
      start_sync <= start_meta;
    end if;
  end process;
  
  --counter reset
  process(clk, rst)
  begin
    if (rst = '1') then
      reset_meta <= '0';
      reset_sync <= '0';
    elsif (rising_edge(clk)) then
      reset_meta <= counter_reset;
      reset_sync <= reset_meta;
    end if;
  end process;
  
  --reset signal across clock domain
  counter_slow: slow_pulse port map(
    CLK_F_I    => ACLK,
    RSTN_F_I   => ARESETN,
    UPDATE_I   => reset_sync ,
    CONFIG_POL => '0',

    CLK_S_I      => UCLK_I,
    PULSE_O      => reset_s,
    --COUNT_O      => count_d_s,
    COUNT_START  => '1',
    COUNT_RESET  => '0'
  );
  
  --input lemo signal (slow to fast)
  lemo_a_fast: external_update port map(
      UPDATE_E_I   => LEMO_A_I,
      CLK_F_I      => ACLK,
      RSTN         => ARESETN,
      COUNT_P      => lemo_a_c,     
      PULSE_OUT    => lemo_a_f,  
      COUNT_START  => start_sync,
      COUNT_RESET  => reset_sync
      
  );
  lemo_b_fast: external_update port map(
      UPDATE_E_I      => LEMO_B_I,
      CLK_F_I         => ACLK,
      RSTN            => ARESETN,
      COUNT_P         => lemo_b_c,     
      PULSE_OUT       =>  lemo_b_f,
      COUNT_START     => start_sync,
      COUNT_RESET     => reset_sync
  );
 
  --input 0f lemo and poke signal (fast to slow)
  lemo_a_ts: slow_pulse port map(
    CLK_F_I  => ACLK,
    RSTN_F_I  => ARESETN,
    UPDATE_I  => lemo_a_f ,
    CONFIG_POL => polarity_cfg(0),

    CLK_S_I => UCLK_I,
    PULSE_O =>lemo_a_s,
    COUNT_O => count_a_s,
    COUNT_START     => start_sync,
    COUNT_RESET     => reset_s
  );
  lemo_b_ts: slow_pulse port map(
    CLK_F_I  => ACLK,
    RSTN_F_I  => ARESETN,
    UPDATE_I  => lemo_b_f ,
    CONFIG_POL => polarity_cfg(1),

    CLK_S_I => UCLK_I,
    PULSE_O =>lemo_b_s,
    COUNT_O => count_b_s,
    COUNT_START     => start_sync,
    COUNT_RESET     => reset_s
  );
  poke_c_ts: slow_pulse port map(
    CLK_F_I  => ACLK,
    RSTN_F_I  => ARESETN,
    UPDATE_I	 => poke_c_f ,
    CONFIG_POL => polarity_cfg(2),

    CLK_S_I => UCLK_I,
    PULSE_O => poke_c_s,
    COUNT_O => count_c_s,
    COUNT_START     => start_sync,
    COUNT_RESET     => reset_s
  );
  poke_d_ts: slow_pulse port map(
    CLK_F_I    => ACLK,
    RSTN_F_I   => ARESETN,
    UPDATE_I	 => poke_d_f ,
    CONFIG_POL => polarity_cfg(3),

    CLK_S_I      => UCLK_I,
    PULSE_O      => poke_d_s,
    COUNT_O      => count_d_s,
    COUNT_START     => start_sync,
    COUNT_RESET     => reset_s
  );
  
  --output signal
  output: atc_mux port map (
    UCLK  => UCLK_I,
    RSTN  => ARESETN,
    UPDATE_LEMO_A_I => lemo_a_s,
    UPDATE_LEMO_B_I => lemo_b_s,
    UPDATE_POKE_C_I => poke_c_s,
    UPDATE_POKE_D_I => poke_d_s,


    ATC_CONFIG_G    => atc_g_cfg,      
    ATC_CONFIG_H    => atc_h_cfg,      
    ATC_CONFIG_TS   => atc_ts_cfg, 


    ATC_G_COUNT     =>   atc_g_c,    
    ATC_H_COUNT     =>   atc_h_c,    
    ATC_TS_COUNT    =>   atc_ts_c,   
   
    ATC_G_O           => G_O,        
    ATC_H_O           => H_O,       
    TS_SYNC           => ts_sy,
    COUNT_START       => start_sync,
    COUNT_RESET       => reset_s

  );
    ts: timestamp port map (
    CLK_A_I        => ACLK,
    RSTN_A_I	   => ARESETN,
    TIMESTAMP_A_O  => tstamp,
    CLK_B_I        => UCLK_I,
    RSTN_B_I       => ts_sy
  );
    
  
end behaviour;
        
