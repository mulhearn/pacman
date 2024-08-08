library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 

--  Defines a testbench (without any ports)
entity axi_demo_ro_tb is
end axi_demo_ro_tb;
     
architecture behaviour of axi_demo_ro_tb is
  component axil_demo_ro is
    port (
      S_AXI_ACLK          : in std_logic;
      S_AXI_ARESETN       : in std_logic;
      S_AXI_ARADDR        : in std_logic_vector(7 downto 0);
      --S_AXI_ARPROT        : in std_logic_vector(2 downto 0);
      S_AXI_ARVALID       : in std_logic;
      S_AXI_ARREADY       : out std_logic;    
      S_AXI_RDATA         : out std_logic_vector(31 downto 0);
      S_AXI_RRESP         : out std_logic_vector(1 downto 0);
      S_AXI_RVALID        : out std_logic;
      S_AXI_RREADY        : in std_logic
      );
  end component;
  signal aclk     : std_logic;
  signal aresetn    : std_logic;
  signal araddr   : std_logic_vector(7 downto 0);
  signal arval    : std_logic;
  signal arready  : std_logic;
  signal rdata    : std_logic_vector(31 downto 0);
  signal rval     : std_logic;  
  signal rready   : std_logic;  
begin
  uut: axil_demo_ro port map (
      S_AXI_ACLK          => aclk,
      S_AXI_ARESETN       => aresetn,
      S_AXI_ARADDR        => araddr,
      S_AXI_ARVALID       => arval,
      S_AXI_ARREADY       => arready,    
      S_AXI_RDATA         => rdata,
      S_AXI_RVALID        => rval,
      S_AXI_RREADY        => rready);
  
  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 12 ns;
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
    araddr <= x"00";
    arval  <= '0';
    rready <= '0';
    wait for 20 ns;
    araddr <= x"00";
    arval  <= '1';
    rready <= '1';
    wait for 20 ns;
    araddr <= x"04";
    rready <= '1';
    wait for 20 ns;
    araddr <= x"08";
    rready <= '1';
    wait for 20 ns;
    araddr <= x"0C";
    rready <= '1';
    wait for 20 ns;
    araddr <= x"10";
    arval  <= '1';
    rready <= '1';
    wait for 20 ns;
    araddr <= x"00";
    rready <= '1';
    wait for 20 ns;
    araddr <= x"04";
    rready <= '1';
    wait for 20 ns;
    araddr <= x"08";
    rready <= '1';
    wait for 20 ns;
    araddr <= x"0C";
    rready <= '1';
    wait for 20 ns;
    araddr <= x"10";
    rready <= '1';
    wait for 20 ns;

  end process;

  
  --challenging_read_process : process
  --begin
    --araddr <= x"00";
    --arval  <= '0';
    --rready <= '0';
    --wait for 20 ns;
    --araddr <= x"01";
    --arval  <= '1';
    --wait for 10 ns;
    --araddr <= x"00";
    --arval  <= '0';
    --wait for 60 ns;
    --rready <= '1';
    --wait for 10 ns;
    --rready <= '0';
    --wait;
  --end process;

  
  --single_read_process : process
  --begin
    --araddr <= x"00";
    --arval  <= '0';
    --rready <= '0';
    --wait for 20 ns;
    --araddr <= x"01";
    --arval  <= '1';
    --rready <= '1';
    --wait for 20 ns;
    --araddr <= x"00";
    --arval  <= '0';
    --rready <= '0';
    --wait;
  --end process;
  
  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    wait for 10 ns;
    write (l, String'("aclk: "));
    write (l, aclk);    
    write (l, String'(" || ADDRESS:   araddr: 0x"));
    hwrite (l, araddr);
    write (l, String'(" arval: "));
    write (l, arval);
    write (l, String'(" arready: "));
    write (l, arready);    
    write (l, String'(" arval: "));
    write (l, arval);
    write (l, String'(" || READ:   rdata: 0x"));
    hwrite (l, rdata);
    write (l, String'(" rval: "));
    write (l, rval);
    write (l, String'(" rready: "));
    write (l, rready);

    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
