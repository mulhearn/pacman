library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 
library work;
use work.common.all;

--  Defines a testbench (without any ports)
entity axis_read_tb is
  generic (
    constant C_AXIS_WIDTH  : integer  := 32;
    constant C_AXIS_BEATS   : integer  := 4
  );
begin
  assert(C_AXIS_WIDTH >= 16) severity failure; -- Assumed for test output      
end axis_read_tb;
     
architecture behaviour of axis_read_tb is
  component axis_read is
    generic (
      constant C_AXIS_WIDTH  : integer  := C_AXIS_WIDTH;
      constant C_AXIS_BEATS   : integer  := C_AXIS_BEATS
    );
    port (
      S_AXIS_ACLK        : in std_logic;
      S_AXIS_ARESETN     : in std_logic;

      S_AXIS_TDATA       : in std_logic_vector(C_AXIS_WIDTH-1 downto 0);      
      S_AXIS_TVALID      : in std_logic;
      S_AXIS_TREADY      : out std_logic;

      S_AXIS_TKEEP       : in std_logic_vector(C_AXIS_WIDTH/8-1 downto 0);      
      S_AXIS_TLAST       : in std_logic;
    
      DATA_O             : out std_logic_vector(C_AXIS_WIDTH*C_AXIS_BEATS-1 downto 0);
      VAL_O              : out std_logic
    );  
  end component;

  signal count    : integer := 0;
  signal aclk     : std_logic;
  signal aresetn  : std_logic;
  
  signal tdata    : std_logic_vector(C_AXIS_WIDTH-1 downto 0) := (others => '0');
  signal tvalid   : std_logic := '0';
  signal tready   : std_logic;
  signal tlast    : std_logic := '0';

  signal odat     : std_logic_vector(C_AXIS_WIDTH*C_AXIS_BEATS-1 downto 0);
  signal oval     : std_logic; 
begin
  uut: axis_read port map (
    S_AXIS_ACLK     => aclk,
    S_AXIS_ARESETN  => aresetn,
    S_AXIS_TDATA    => tdata,
    S_AXIS_TVALID   => tvalid,   
    S_AXIS_TREADY   => tready,
    S_AXIS_TKEEP    => (others=>'1'),
    S_AXIS_TLAST    => tlast,
    DATA_O          => odat,
    VAL_O           => oval
  );
  
  aresetn_process : process
  begin
    aresetn <= '0';
    wait for 10 ns;
    aresetn <= '1';    
    wait;
  end process;

  stream_process : process
  begin
    wait for 1 ns;
    wait for 20 ns;
    tvalid <= '1';
    tdata(15 downto 0)    <= x"BBAA";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(15 downto 0)    <= x"DDCC";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(15 downto 0)    <= x"FFEE";
    tlast                 <= '0';
    wait for 10 ns;
    tvalid <= '1';
    tdata(15 downto 0)    <= x"2211";
    tlast                 <= '1';
    wait for 10 ns;
    tvalid                <= '0';
    tdata                 <= (others => '0');
    tlast                 <= '0';
    wait for 20 ns;
  end process;
    
  aclk_process : process
  begin
    count <= count + 1;
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;


  output_process : process
    variable l : line;
  begin
    if (count < 18) then
      wait for 10 ns;   
    else
      wait;
    end if;

    write (l, String'("c: "));
    write (l, count, left, 4);
    --write (l, String'("aclk: "));
    --write (l, aclk);
    write (l, String'("|| dat: 0x"));
    hwrite (l, tdata(15 downto 0));
    write (l, String'("..."));
    write (l, String'(" val: "));
    write (l, tvalid);
    write (l, String'(" rdy: "));
    write (l, tready);
    write (l, String'(" last: "));
    write (l, tlast);
    write (l, String'(" || odat 0x (0)"));
    hwrite (l, odat);
    write (l, String'(" oval: "));
    write (l, oval);

    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
