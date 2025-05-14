library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity adc_reg_tb is
end adc_reg_tb;
     
architecture behaviour of adc_reg_tb is
  component adc_reg is
    port (
      ACLK	             : in std_logic;
      ARESETN	             : in std_logic;

      S_REGBUS_RB_RADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;
      
      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      TRIG_MODE              : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      CLK_DIV                : out std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
      ADC_EN                 : out std_logic;
      LAST_W                 : in  std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
      );
  end component;
  signal count     : integer := 0;
  signal last_w    : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal aclk      : std_logic;
  signal aresetn   : std_logic;
  -- registers
  signal trig_mode : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal clk_div   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal adc_en    : std_logic;
  -- read signals:
  signal raddr   : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal rupdate : std_logic := '0';
  signal rdata   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  signal rack    : std_logic := '0';
  -- write signals:
  signal waddr   : std_logic_vector(C_RB_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal wupdate : std_logic := '0';
  signal wdata   : std_logic_vector(C_RB_DATA_WIDTH-1 downto 0) := (others => '0');
  signal wack    : std_logic := '0';
begin
  uut: adc_reg port map (
      TRIG_MODE      => trig_mode,
      CLK_DIV        => clk_div,
      ADC_EN         => adc_en,
      ACLK           => aclk,
      ARESETN        => aresetn,
      LAST_W         => last_w,
      S_REGBUS_RB_RUPDATE => rupdate,
      S_REGBUS_RB_RADDR   => raddr,
      S_REGBUS_RB_RDATA   => rdata,
      S_REGBUS_RB_RACK    => rack,
      S_REGBUS_RB_WUPDATE => wupdate,
      S_REGBUS_RB_WADDR   => waddr,
      S_REGBUS_RB_WDATA   => wdata,
      S_REGBUS_RB_WACK    => wack
      );
  
  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 12 ns;
    aresetn <= '1';    
    wait;
  end process;
  
  aclk_process : process
  begin
    count <= count + 1;    
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  rapid_read_process : process
  begin
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 8 ns;
    last_w <= x"000000AD";
    wait for 40 ns;
    raddr   <= x"D10C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D100";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D104";
    rupdate <= '1';
    last_w  <= x"000000BC";
    wait for 10 ns;
    raddr   <= x"D110";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"D10C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 30 ns;
    raddr   <= x"D1FF";
    rupdate <= '1';    
    wait for 10 ns;    
    raddr   <= x"D108";
    rupdate <= '1';    
    wait for 10 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait;
  end process;


  rapid_write_process : process
  begin
    wait for 1 ns;
    wait for 20 ns;
    waddr   <= x"D100";
    wdata   <= x"FEEDDADA";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D104";
    wdata   <= x"DEADBEEF";
    wupdate <= '1';
    wait for 10 ns;
    --expert write:
    waddr   <= x"D1E0";
    wdata   <= x"FFFFFFFF";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"D108";
    wdata   <= x"DABEFADE";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000"; 
    wdata   <= x"00000000";
    wupdate <= '0';
    wait;
  end process;

output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    if (count < 15) then
      wait for 10 ns;
    else
      wait;
    end if;
    write (l, String'("c: "));
    write (l, count, left, 4);
    --write (l, String'("aclk: "));
    --write (l, aclk);
    write (l, String'(" || ra: 0x"));
    hwrite (l, raddr);
    write (l, String'(" ru:"));
    write (l, rupdate);
    write (l, String'(" rd: 0x"));
    hwrite (l, rdata);
    write (l, String'(" rk:"));
    write (l, rack);
    write (l, String'(" || wa: 0x"));
    hwrite (l, waddr);
    write (l, String'(" wu:"));
    write (l, wupdate);
    write (l, String'(" wd: 0x"));
    hwrite (l, wdata);
    write (l, String'(" wk:"));
    write (l, wack);
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
