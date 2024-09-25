library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;


entity registers_demo is
  port (
    ACLK                 : in std_logic;
    ARESETN              : in std_logic;
    
    S_REGBUS_RB_RUPDATE  : in   std_logic;
    S_REGBUS_RB_RADDR    : in   std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_RDATA    : out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
    S_REGBUS_RB_RACK     : out  std_logic;
      
    S_REGBUS_RB_WUPDATE  : in   std_logic;
    S_REGBUS_RB_WADDR    : in   std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
    S_REGBUS_RB_WDATA    : in   std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    S_REGBUS_RB_WACK     : out  std_logic
  );  
end registers_demo;
     
architecture behaviour of registers_demo is
  component regbus_mux is
    port (
      ACLK	             : in std_logic;
      ARESETN	             : in std_logic;
      -- Secondary REGBUS:
      S_REGBUS_RB_RUPDATE  : in   std_logic;
      S_REGBUS_RB_RADDR    : in   std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA    : out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      S_REGBUS_RB_RACK     : out  std_logic;
      
      S_REGBUS_RB_WUPDATE  : in   std_logic;
      S_REGBUS_RB_WADDR    : in   std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA    : in   std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK     : out  std_logic;

      -- Primary A REGBUS
      PA_REGBUS_RB_RUPDATE : out  std_logic;
      PA_REGBUS_RB_RADDR   : out  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      PA_REGBUS_RB_RDATA   : in   std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      PA_REGBUS_RB_RACK    : in   std_logic;
      PA_REGBUS_RB_WUPDATE : out  std_logic;
      PA_REGBUS_RB_WADDR   : out  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      PA_REGBUS_RB_WDATA   : out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      PA_REGBUS_RB_WACK    : in   std_logic;
      
      -- Primary B REGBUS
      PB_REGBUS_RB_RUPDATE : out  std_logic;
      PB_REGBUS_RB_RADDR   : out  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      PB_REGBUS_RB_RDATA   : in   std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      PB_REGBUS_RB_RACK    : in   std_logic;    
      PB_REGBUS_RB_WUPDATE : out  std_logic;
      PB_REGBUS_RB_WADDR   : out  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      PB_REGBUS_RB_WDATA   : out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      PB_REGBUS_RB_WACK    : in   std_logic;

      -- Primary C REGBUS
      PC_REGBUS_RB_RUPDATE : out  std_logic;
      PC_REGBUS_RB_RADDR   : out  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      PC_REGBUS_RB_RDATA   : in   std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      PC_REGBUS_RB_RACK    : in   std_logic;    
      PC_REGBUS_RB_WUPDATE : out  std_logic;
      PC_REGBUS_RB_WADDR   : out  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      PC_REGBUS_RB_WDATA   : out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      PC_REGBUS_RB_WACK    : in   std_logic;

      -- Primary D REGBUS
      PD_REGBUS_RB_RUPDATE : out  std_logic;
      PD_REGBUS_RB_RADDR   : out  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      PD_REGBUS_RB_RDATA   : in   std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);      
      PD_REGBUS_RB_RACK    : in   std_logic;    
      PD_REGBUS_RB_WUPDATE : out  std_logic;
      PD_REGBUS_RB_WADDR   : out  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      PD_REGBUS_RB_WDATA   : out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      PD_REGBUS_RB_WACK    : in   std_logic;

      --
      DEBUG               : out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
    );
  end component;
  
  component registers_scratch is
    generic (
      C_SCOPE       : integer  := 16#F#;  -- GLOBAL
      C_ROLE        : integer  := 16#1#;  -- DEBUGGING
      C_VAL_ROA     : unsigned(C_RB_DATA_WIDTH-1 downto 0)  := x"11111111";
      C_VAL_ROB     : unsigned(C_RB_DATA_WIDTH-1 downto 0)  := x"22222222"
    );          
    port (
      ACLK	        : in std_logic;
      ARESETN	        : in std_logic;
      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;
      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;
      --
      DEBUG     	: out  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0)
      );
  end component;


  constant NUM_SCRATCH : integer := 4;
  type t_data_array is array (0 to NUM_SCRATCH-1) of std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  type t_addr_array is array (0 to NUM_SCRATCH-1) of std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
  signal raddr_array   : t_addr_array;
  signal rupdate_array : std_logic_vector(NUM_SCRATCH-1 downto 0);
  signal rdata_array   : t_data_array;
  signal rack_array    : std_logic_vector(NUM_SCRATCH-1 downto 0);  
  signal waddr_array   : t_addr_array;
  signal wupdate_array : std_logic_vector(NUM_SCRATCH-1 downto 0);
  signal wdata_array   : t_data_array;
  signal wack_array    : std_logic_vector(NUM_SCRATCH-1 downto 0);
  
  type t_integer_array is array (0 to NUM_SCRATCH-1) of integer;
  constant scope_array : t_integer_array := (0=>16#F#, 1=>0, 2=>1, 3=>16#F#);
  constant role_array  : t_integer_array := (0=>16#F#, 1=>0, 2=>0, 3=>16#E#);
  constant roa_array   : t_data_array := (0=>x"11111111",1=>x"22222222",2=>x"33333333",3=>x"44444444");
  constant rob_array   : t_data_array := (0=>x"AAAAAAAA",1=>x"BBBBBBBB",2=>x"CCCCCCCC",3=>x"DDDDDDDD") ; 
begin
  
  u0: for i in 0 to NUM_SCRATCH-1 generate
    scratch0: registers_scratch
      generic map (
        C_SCOPE => scope_array(i),
        C_ROLE  => role_array(i),
        C_VAL_ROA => unsigned(roa_array(i)),
        C_VAL_ROB => unsigned(rob_array(i))
        )
      port map (
        ACLK                => ACLK,
        ARESETN             => ARESETN,      
        S_REGBUS_RB_RUPDATE => rupdate_array(i),
        S_REGBUS_RB_RADDR   => raddr_array(i),
        S_REGBUS_RB_RDATA   => rdata_array(i),
        S_REGBUS_RB_RACK    => rack_array(i),
        S_REGBUS_RB_WUPDATE => wupdate_array(i),
        S_REGBUS_RB_WADDR   => waddr_array(i),
        S_REGBUS_RB_WDATA   => wdata_array(i),
        S_REGBUS_RB_WACK    => wack_array(i)
        );
  end generate u0;

  uut: regbus_mux port map (
    ACLK           => ACLK,
    ARESETN        => ARESETN,      
    S_REGBUS_RB_RUPDATE => S_REGBUS_RB_RUPDATE,
    S_REGBUS_RB_RADDR   => S_REGBUS_RB_RADDR,
    S_REGBUS_RB_RDATA   => S_REGBUS_RB_RDATA,
    S_REGBUS_RB_RACK    => S_REGBUS_RB_RACK,
    S_REGBUS_RB_WUPDATE => S_REGBUS_RB_WUPDATE,
    S_REGBUS_RB_WADDR   => S_REGBUS_RB_WADDR,
    S_REGBUS_RB_WDATA   => S_REGBUS_RB_WDATA,
    S_REGBUS_RB_WACK    => S_REGBUS_RB_WACK,

    PA_REGBUS_RB_RUPDATE => rupdate_array(0),
    PA_REGBUS_RB_RADDR   => raddr_array(0),
    PA_REGBUS_RB_RDATA   => rdata_array(0),
    PA_REGBUS_RB_RACK    => rack_array(0),
    PA_REGBUS_RB_WUPDATE => wupdate_array(0),
    PA_REGBUS_RB_WADDR   => waddr_array(0),
    PA_REGBUS_RB_WDATA   => wdata_array(0),
    PA_REGBUS_RB_WACK    => wack_array(0),

    PB_REGBUS_RB_RUPDATE => rupdate_array(1),
    PB_REGBUS_RB_RADDR   => raddr_array(1),
    PB_REGBUS_RB_RDATA   => rdata_array(1),
    PB_REGBUS_RB_RACK    => rack_array(1),
    PB_REGBUS_RB_WUPDATE => wupdate_array(1),
    PB_REGBUS_RB_WADDR   => waddr_array(1),
    PB_REGBUS_RB_WDATA   => wdata_array(1),
    PB_REGBUS_RB_WACK    => wack_array(1),

    PC_REGBUS_RB_RUPDATE => rupdate_array(2),
    PC_REGBUS_RB_RADDR   => raddr_array(2),
    PC_REGBUS_RB_RDATA   => rdata_array(2),
    PC_REGBUS_RB_RACK    => rack_array(2),
    PC_REGBUS_RB_WUPDATE => wupdate_array(2),
    PC_REGBUS_RB_WADDR   => waddr_array(2),
    PC_REGBUS_RB_WDATA   => wdata_array(2),
    PC_REGBUS_RB_WACK    => wack_array(2),

    PD_REGBUS_RB_RUPDATE => rupdate_array(3),
    PD_REGBUS_RB_RADDR   => raddr_array(3),
    PD_REGBUS_RB_RDATA   => rdata_array(3),
    PD_REGBUS_RB_RACK    => rack_array(3),
    PD_REGBUS_RB_WUPDATE => wupdate_array(3),
    PD_REGBUS_RB_WADDR   => waddr_array(3),
    PD_REGBUS_RB_WDATA   => wdata_array(3),
    PD_REGBUS_RB_WACK    => wack_array(3)

    );
    
end behaviour;
        
