library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

-- Request a config update in a different clock domain

entity slow_config is
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
    
    -- interface to the request in the fast clock domain
    REPLY_O         : out std_logic;
    ASYNC_REQUEST_I : in  std_logic
  );
end;

architecture behavioral of slow_config is
  signal clk         : std_logic;
  signal rst         : std_logic;
  signal update_comb : std_logic;

  signal config       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal polarity     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal logic        : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal dst_lemo_a   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal dst_lemo_b   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal dst_poke_c   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal dst_poke_d   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal dst_logic_e  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal dst_logic_f  : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of config       : signal is "TRUE";
  attribute ASYNC_REG of polarity     : signal is "TRUE";
  attribute ASYNC_REG of logic        : signal is "TRUE";
  attribute ASYNC_REG of dst_lemo_a   : signal is "TRUE";
  attribute ASYNC_REG of dst_lemo_b   : signal is "TRUE";
  attribute ASYNC_REG of dst_poke_c   : signal is "TRUE";
  attribute ASYNC_REG of dst_poke_d   : signal is "TRUE";
  attribute ASYNC_REG of dst_logic_e  : signal is "TRUE";
  attribute ASYNC_REG of dst_logic_f  : signal is "TRUE";

  component update_reply is
    port (
      CLK_I	      : in  std_logic;
      RST_I	      : in  std_logic;
      UPDATE_O        : out std_logic;
      UPDATE_COMB_O   : out std_logic;
      ASYNC_REQUEST_I : in  std_logic;
      DONE_I          : in  std_logic; 
      REPLY_O         : out std_logic
      );
  end component;
  
begin
  clk <= CLK_SLOW_I;
  rst <= RST_SLOW_I;
  
  rep0: update_reply port map (
    CLK_I           => clk,
    RST_I           => rst,
    UPDATE_COMB_O   => update_comb,
    ASYNC_REQUEST_I => ASYNC_REQUEST_I,
    DONE_I          => '1',
    REPLY_O         => REPLY_O
  );
  
  mask0: process(clk, rst)
  begin
    if (rst = '1') then
      config      <= (others => '0');      
      polarity    <= (others => '0');          
      logic       <= (others => '0');          
      dst_lemo_a  <= (others => '0');      
      dst_lemo_b  <= (others => '0');      
      dst_poke_c  <= (others => '0');      
      dst_poke_d  <= (others => '0');      
      dst_logic_e <= (others => '0');      
      dst_logic_f <= (others => '0');      
    elsif (rising_edge(clk)) then
      config      <= ASYNC_CONFIG_I;      
      polarity    <= ASYNC_POLARITY_I;          
      logic       <= ASYNC_LOGIC_I;          
      dst_lemo_a  <= ASYNC_DST_LEMO_A_I;      
      dst_lemo_b  <= ASYNC_DST_LEMO_B_I;      
      dst_poke_c  <= ASYNC_DST_POKE_C_I;      
      dst_poke_d  <= ASYNC_DST_POKE_D_I;      
      dst_logic_e <= ASYNC_DST_LOGIC_E_I;      
      dst_logic_f <= ASYNC_DST_LOGIC_F_I;      
    end if;
  end process;

  pulse0: process(clk, rst)
    variable timeout : integer := 0;
  begin
    if (rst = '1') then
      SHADOW_CONFIG_O      <= (others => '0');
      SHADOW_POLARITY_O    <= (others => '0');
      SHADOW_LOGIC_O       <= (others => '0');
      SHADOW_DST_LEMO_A_O  <= (others => '0');
      SHADOW_DST_LEMO_B_O  <= (others => '0');
      SHADOW_DST_POKE_C_O  <= (others => '0');
      SHADOW_DST_POKE_D_O  <= (others => '0');
      SHADOW_DST_LOGIC_E_O <= (others => '0');
      SHADOW_DST_LOGIC_F_O <= (others => '0');      
    elsif (rising_edge(clk)) then
      if (update_comb = '1') then
        SHADOW_CONFIG_O      <= config;      
        SHADOW_POLARITY_O    <= polarity;    
        SHADOW_LOGIC_O       <= logic;       
        SHADOW_DST_LEMO_A_O  <= dst_lemo_a;  
        SHADOW_DST_LEMO_B_O  <= dst_lemo_b;  
        SHADOW_DST_POKE_C_O  <= dst_poke_c;  
        SHADOW_DST_POKE_D_O  <= dst_poke_d;  
        SHADOW_DST_LOGIC_E_O <= dst_logic_e; 
        SHADOW_DST_LOGIC_F_O <= dst_logic_f; 
      end if;
    end if;
  end process;
  
end;
