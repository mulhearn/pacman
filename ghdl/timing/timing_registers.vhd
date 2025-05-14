library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;
use work.register_map.all;


entity timing_registers is
  port (
    ACLK	                 : in std_logic;
    ARESETN	               : in std_logic;

    S_REGBUS_RB_RUPDATE    : in  std_logic;
    S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK       : out std_logic;
    
    S_REGBUS_RB_WUPDATE    : in  std_logic;
    S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK       : out std_logic;

    ATC_POKE_C             : out std_logic;
    ATC_POKE_D             : out std_logic;
    ATC_CONFIG_G           : out ATC_array := (others => (others => '0'));
    ATC_CONFIG_H           : out ATC_array := (others => (others => '0'));
    ATC_CONFIG_TS          : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    ATC_POLARITY           : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    STATUS_I               : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    TIMESTAMP_I            : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);   
    --count of input in fast domain
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
end;

architecture behavioral of timing_registers is
  signal clk      : std_logic;
  signal rst      : std_logic;

  signal rupdate  : std_logic;
  signal raddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal rdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal rack     : std_logic := '0';
  
  signal wupdate  : std_logic;
  signal waddr    : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal wdata    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal wack     : std_logic := '0';

  signal atc_g_cfg    :  ATC_array  := (others => (others => '0'));
  signal atc_h_cfg    :  ATC_array  := (others => (others => '0'));
  signal polarity_cfg : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal ts_cfg       : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal lemo_a_c     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal lemo_b_c     : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  
  signal lemo_a_sc   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal lemo_b_sc   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal poke_c_sc   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal poke_d_sc   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');

  signal atc_g_c     : ATC_array;
  signal atc_h_c     : ATC_array;
  signal atc_ts_c    : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');


begin
  -- Clock and reset inputs:
  clk <= ACLK;
  rst <= not ARESETN;
  
  --REGBUS read signals
  rupdate  <= S_REGBUS_RB_RUPDATE;
  raddr    <= S_REGBUS_RB_RADDR;
  S_REGBUS_RB_RDATA <= rdata;
  S_REGBUS_RB_RACK  <= rack;
  --REGBUS write signals
  wupdate  <= S_REGBUS_RB_WUPDATE;
  waddr    <= S_REGBUS_RB_WADDR;
  wdata    <= S_REGBUS_RB_WDATA;
  S_REGBUS_RB_WACK	 <= wack;

  ATC_CONFIG_G <= atc_g_cfg;
  ATC_CONFIG_H <= atc_h_cfg;
  ATC_CONFIG_TS<= ts_cfg; 
  ATC_POLARITY <= polarity_cfg;
  
  

  lemo_a_c <= LEMO_A_COUNT;
  lemo_b_c <= LEMO_B_COUNT;

  lemo_a_sc <= LEMO_A_COUNT_S;  
  lemo_b_sc <= LEMO_B_COUNT_S;  
  poke_c_sc <= POKE_C_COUNT_S;  
  poke_d_sc <= POKE_D_COUNT_S;  

  atc_g_c   <=   ATC_G_COUNT;
  atc_h_c   <=   ATC_H_COUNT;  
  atc_ts_c  <=   ATC_TS_COUNT;



  -- Handle Read Request:
  process(clk, rst)
    variable scope   : integer range 0 to 16#F#;
    variable role    : integer range 0 to 16#F#;
    variable reg     : integer range 0 to 16#FF#;
    variable chan    : unsigned(7 downto 0); 
  begin  
    if (rst = '1') then
      rack <= '0';
      rdata <= x"00000000";
    elsif (rising_edge(clk)) then
      rack <= '0';
      if (rupdate='1') then
        scope := to_integer(unsigned(raddr(15 downto 12)));
        role  := to_integer(unsigned(raddr(11 downto 8)));
        reg   := to_integer(unsigned(raddr(7 downto 0)));
        rdata <= x"00000000";
        if (scope = C_SCOPE_TIMING) and (role = C_TIMING_REGULAR ) then
          rdata <= x"EEEEEEEE";

          if (reg= C_ADDR_TIMING_STATUS) then
            rdata <= STATUS_I;
            rack  <= '1';
          elsif (reg= C_ADDR_TIMING_STAMP) then
            rdata <= TIMESTAMP_I;
            rack  <= '1';  
          end if;      
        elsif (scope=C_SCOPE_TIMING) and (role= C_TIMING_COUNTER ) then
          
          if(reg= C_ADDR_LEMO_A_F ) then
            rdata <= lemo_a_c;
            rack  <= '1';
          elsif (reg= C_ADDR_LEMO_B_F ) then
            rdata <= lemo_b_c;
            rack  <= '1';
          elsif (reg= C_ADDR_LEMO_A_S) then
            rdata <= lemo_a_sc ;
            rack  <= '1'; 
          elsif (reg= C_ADDR_LEMO_B_S) then
            rdata <= lemo_b_sc ;
            rack  <= '1'; 
          elsif (reg= C_ADDR_POKE_C_S) then
            rdata <= poke_c_sc ;
            rack  <= '1'; 
          elsif (reg= C_ADDR_POKE_D_S) then
            rdata <= poke_d_sc ;
            rack  <= '1';                    
          elsif (reg >= C_ADDR_ATC_G_START) and (reg <=C_ADDR_ATC_G_END ) then 
            chan :=  to_unsigned(reg - C_ADDR_ATC_G_START, 8);
            rdata <= atc_g_c(to_integer(chan(7 downto 2)));
            rack  <= '1';  
          elsif (reg >= C_ADDR_ATC_H_START) and (reg <=C_ADDR_ATC_H_END ) then 
            chan :=  to_unsigned(reg - C_ADDR_ATC_H_START, 8);
            rdata <= atc_h_c(to_integer(chan(7 downto 2)));
            rack  <= '1';
          elsif (reg= C_ADDR_ATC_TS) then
            rdata <= atc_ts_c ;
            rack  <= '1';
          end if;

        elsif (scope=C_SCOPE_TIMING) and (role=C_TIMING_CFG ) then 
          if (reg= C_ADDR_ATC_POLARITY) then
            rdata <= polarity_cfg;
            rack  <= '1';   
          elsif (reg = C_ADDR_ATC_TS ) then
            rdata <= ts_cfg;
            rack  <= '1'; 
          elsif (reg >= C_ADDR_ATC_G_START) and (reg <=C_ADDR_ATC_G_END ) then 
            chan :=  to_unsigned(reg - C_ADDR_ATC_G_START, 8);
            rdata <= atc_g_cfg(to_integer(chan(7 downto 2)));
            rack  <= '1';
          elsif (reg >= C_ADDR_ATC_H_START) and (reg <=C_ADDR_ATC_H_END ) then 
            chan :=  to_unsigned(reg - C_ADDR_ATC_H_START, 8);
            rdata <= atc_h_cfg(to_integer(chan(7 downto 2)));
            rack  <= '1';
          end if;   
        end if;
      end if;
    end if;
  end process;
        
  -- Handle Write Request:
  process(clk, rst)
    variable scope   : integer range 0 to 16#F#;
    variable role    : integer range 0 to 16#F#;
    variable reg     : integer range 0 to 16#FF#;  
    variable chan    : unsigned(7 downto 0); 
  begin  
    if (rst = '1') then
      wack  <= '0';
      atc_g_cfg <= (others => (others => '0'));
      atc_h_cfg <= (others => (others => '0'));
      polarity_cfg <= (others => '0');
      ATC_POKE_C <= '0';
      ATC_POKE_D <= '0';
      COUNT_START <= '0';
      COUNT_RESET <= '1';      
    elsif (rising_edge(clk)) then
      ATC_POKE_C <= '0';
      ATC_POKE_D <= '0';
      COUNT_RESET <= '0';
      wack <= '0';      
      if (wupdate='1') then
        scope := to_integer(unsigned(waddr(15 downto 12)));
        role  := to_integer(unsigned(waddr(11 downto 8)));
        reg   := to_integer(unsigned(waddr(7 downto 0)));           
        if (scope=C_SCOPE_TIMING) and (role=C_TIMING_REGULAR) then    
          if (reg= C_ADDR_ATC_POKE_C ) then
            ATC_POKE_C <= '1';
            wack  <= '1';   
          elsif (reg= C_ADDR_ATC_POKE_D ) then            
            ATC_POKE_D <= '1'; 
            wack  <= '1'; 
          elsif (reg= C_ADDR_COUNT_START ) then
            COUNT_START <= '1';         
            wack  <= '1'; 
          elsif (reg= C_ADDR_COUNT_STOP ) then             
            COUNT_START <= '0';
            wack  <= '1';  
          elsif (reg= C_ADDR_COUNT_RESET ) then             
            COUNT_RESET <= '1';
            wack  <= '1';   
          end if;
        elsif (scope=C_SCOPE_TIMING) and (role=C_TIMING_CFG) then      
          if (reg= C_ADDR_ATC_POLARITY ) then
            polarity_cfg <= wdata;
            wack  <= '1';  
          elsif (reg= C_ADDR_ATC_TS ) then
            ts_cfg <= wdata;
            wack  <= '1';       
          elsif (reg >= C_ADDR_ATC_G_START) and (reg <=C_ADDR_ATC_G_END ) then 
            chan :=  to_unsigned(reg - C_ADDR_ATC_G_START, 8);
            atc_g_cfg(to_integer(chan(7 downto 2))) <= wdata;
            wack  <= '1';
          elsif (reg >= C_ADDR_ATC_H_START) and (reg <=C_ADDR_ATC_H_END ) then 
            chan := to_unsigned(reg - C_ADDR_ATC_H_START, 8);
            atc_h_cfg(to_integer(chan(7 downto 2))) <= wdata;
             wack  <= '1';   
          end if;
        end if;
      end if;
    end if;
  end process;
  
end;  

