library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity const_bram is
  port (
    ACLK      : in std_logic;
    ARESETN   : in std_logic;
    EN        : out std_logic; 
    DOUT      : out  std_logic_vector(31 downto 0); 
    DIN       : in std_logic_vector(31 downto 0); 
    WE        : out std_logic_vector(3 downto 0); 
    ADDR      : out std_logic_vector(12 downto 0); 
    CLK       : out std_logic; 
    RST       : out std_logic
    );
  --ATTRIBUTE X_INTERFACE_INFO : STRING;
  --ATTRIBUTE X_INTERFACE_INFO of EN: SIGNAL is "xilinx.com:interface:bram:1.0 BRAM_PORTB EN";
  --ATTRIBUTE X_INTERFACE_INFO of DOUT: SIGNAL is "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT";
  --ATTRIBUTE X_INTERFACE_INFO of DIN: SIGNAL is "xilinx.com:interface:bram:1.0 BRAM_PORTB DIN";
  --ATTRIBUTE X_INTERFACE_INFO of WE: SIGNAL is "xilinx.com:interface:bram:1.0 BRAM_PORTB WE";
  --ATTRIBUTE X_INTERFACE_INFO of ADDR: SIGNAL is "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR";
  --ATTRIBUTE X_INTERFACE_INFO of CLK: SIGNAL is "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK";
  --ATTRIBUTE X_INTERFACE_INFO of RST: SIGNAL is "xilinx.com:interface:bram:1.0 BRAM_PORTB RST";    
end entity const_bram;

architecture behavioral of const_bram is
begin
  ADDR   <= (others => '0');
  CLK    <= ACLK;
  DOUT   <= (others => '1');
  EN     <= '0';
  RST    <= '0';
  WE     <= (others => '1');
end behavioral;
