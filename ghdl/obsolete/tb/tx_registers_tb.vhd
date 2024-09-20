library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity tx_registers_tb is
end tx_registers_tb;
     
architecture behaviour of tx_registers_tb is
  component tx_registers is
    port (
      ACLK	        : in std_logic;
      ARESETN	        : in std_logic;

      S_REGBUS_RB_RADDR	     : in  std_logic_vector(15 downto 0);
      S_REGBUS_RB_RDATA	     : out std_logic_vector(31 downto 0);
      S_REGBUS_RB_RUPDATE    : in  std_logic;
      S_REGBUS_RB_RACK       : out std_logic;
      
      S_REGBUS_RB_WUPDATE    : in  std_logic;
      S_REGBUS_RB_WADDR	     : in  std_logic_vector(15 downto 0);
      S_REGBUS_RB_WDATA	     : in  std_logic_vector(31 downto 0);
      S_REGBUS_RB_WACK       : out std_logic;

      STATUS_I               : in uart_reg_array_t;
      CYCLES_I               : in uart_reg_array_t;
      BUSYS_I                : in uart_reg_array_t;
      ACKS_I                 : in uart_reg_array_t;
      CONFIG_O               : out uart_reg_array_t;
      SEND_O                 : out uart_tx_data_array_t;
      LOOK_I                 : in uart_tx_data_array_t;
      COMMAND_O              : out uart_command_array_t      
    );
  end component;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
  -- read signals:
  signal raddr    : std_logic_vector(15 downto 0) := (others => '0');
  signal rupdate  : std_logic := '0';
  signal rdata    : std_logic_vector(31 downto 0);
  signal rack     : std_logic := '0';
  -- write signals:
  signal waddr    : std_logic_vector(15 downto 0) := (others => '0');
  signal wupdate  : std_logic := '0';
  signal wdata    : std_logic_vector(31 downto 0) := (others => '0');
  signal wack     : std_logic := '0';  

  signal config   : uart_reg_array_t;
  signal cmd      : uart_command_array_t;
  
begin
  uut0: tx_registers port map (
    ACLK           => aclk,
    ARESETN        => aresetn,      
    S_REGBUS_RB_RUPDATE => rupdate,
    S_REGBUS_RB_RADDR   => raddr,
    S_REGBUS_RB_RDATA   => rdata,
    S_REGBUS_RB_RACK    => rack,
    S_REGBUS_RB_WUPDATE => wupdate,
    S_REGBUS_RB_WADDR   => waddr,
    S_REGBUS_RB_WDATA   => wdata,
    S_REGBUS_RB_WACK    => wack,
    STATUS_I  => (others => x"11111111"),
    CYCLES_I  => (others => x"00000100"),
    BUSYS_I   => (others => x"00000080"),
    ACKS_I    => (others => x"00000010"),    
    LOOK_I  => (others => x"DDDDDDDDCCCCCCCC"),
    CONFIG_O  => config,
    COMMAND_O => cmd
  );
  
  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 20 ns;
    aresetn <= '1';    
    wait;
  end process;
  
  aclk_process : process
  begin
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  rapid_read_process : process
  begin
    wait for 1 ns;
    raddr   <= x"0000";
    rupdate <= '0';
    wait for 30 ns;
    raddr   <= x"0000";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0004";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0010";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0014";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0018";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"001C";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0040";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0440";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0840";
    rupdate <= '1';
    wait for 10 ns;
    raddr   <= x"0C40";
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
    waddr   <= x"0004";
    wdata   <= x"1111B601";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0010";
    wdata   <= x"FEEDDADA";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0014";
    wdata   <= x"CAFEF00D";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0000";
    wdata   <= x"00000000";
    wupdate <= '0';    
    wait for 20 ns;
    waddr   <= x"0020";
    wdata   <= x"00000003";
    wupdate <= '1';
    wait for 10 ns;
    waddr   <= x"0420";
    wdata   <= x"00000003";
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
    wait for 10 ns;
    write (l, String'("aclk: "));
    write (l, aclk);
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
    write (l, String'(" cmd[0]: 0x"));
    hwrite (l, cmd(0)(7 downto 0));
    write (l, String'(" cmd[1]: 0x"));
    hwrite (l, cmd(1)(7 downto 0));
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
