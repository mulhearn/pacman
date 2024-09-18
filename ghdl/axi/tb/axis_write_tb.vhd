library ieee;
use std.textio.all;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use IEEE.std_logic_textio.all;  -- use -fsynopsys or --std=08 

--  Defines a testbench (without any ports)
entity axis_write_tb is
  generic (
    constant C_AXIS_WIDTH  : integer  := 32;
    constant C_DEBUG_WIDTH : integer  := 8
    );
begin
  assert(C_AXIS_WIDTH >= 16) severity failure; -- Assumed for test output  
end axis_write_tb;
     
architecture behaviour of axis_write_tb is
  component axis_write is
    generic (
      constant C_AXIS_WIDTH  : integer  := C_AXIS_WIDTH;
      constant C_DEBUG_WIDTH : integer  := C_DEBUG_WIDTH
    );
    port (
      M_AXIS_ACLK        : in std_logic;
      M_AXIS_ARESETN     : in std_logic;
      
      M_AXIS_TDATA       : out std_logic_vector(C_AXIS_WIDTH-1 downto 0);      
      M_AXIS_TVALID      : out std_logic;
      M_AXIS_TREADY      : in std_logic;
      
      M_AXIS_TKEEP       : out std_logic_vector(C_AXIS_WIDTH/8-1 downto 0);      
      M_AXIS_TLAST       : out std_logic;
      
      BUSY_O             : out std_logic;
      WEN_I              : in  std_logic;
      LAST_I             : in  std_logic;    
      DATA_I             : in  std_logic_vector(C_AXIS_WIDTH-1 downto 0);
      DEBUG_O            : out std_logic_vector(C_DEBUG_WIDTH-1 downto 0)
      );
  end component;

  signal aclk     : std_logic;
  signal aresetn  : std_logic;
  
  signal odat     : std_logic_vector(C_AXIS_WIDTH-1 downto 0);      
  signal val      : std_logic;
  signal rdy      : std_logic;
  signal last     : std_logic;
  
  signal busy     : std_logic;
  signal wen      : std_logic;
  signal idat     : std_logic_vector(C_AXIS_WIDTH-1 downto 0);
  signal debug    : std_logic_vector(C_DEBUG_WIDTH-1 downto 0);
    
begin
  uut: axis_write port map (
    M_AXIS_ACLK    => aclk,
    M_AXIS_ARESETN => aresetn,
    M_AXIS_TDATA   => odat, 
    M_AXIS_TVALID  => val,
    M_AXIS_TREADY  => rdy,
    M_AXIS_TLAST   => last,
    BUSY_O   => busy,
    WEN_I    => wen,
    LAST_I   => '1',
    DATA_I   => idat,
    DEBUG_O  => debug
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
    aclk <= '1';
    wait for 5 ns;
    aclk <= '0';
    wait for 5 ns;
  end process;

  stream_process : process
  begin
    wait for 1 ns;
    rdy <= '1';
    wait for 80 ns;
    rdy <= '0';
    wait for 40 ns;
    rdy <= '1';
    wait for 10 ns;
    rdy <= '0';
    wait for 50 ns;
    rdy <= '1';
    wait;
  end process;

  wen_process : process
  begin
    wait for 1 ns;
    wen <= '0';
    wait for 40 ns;
    wen <= '1';
    wait for 60 ns;
    wen <= '0';
    wait for 40 ns;
    wen <= '1';
    wait for 10 ns;
    wen <= '0';
    wait for 50 ns;
    wen <= '1';
    wait for 50 ns;
    wen <= '0';
    wait;
  end process;

  write_process : process
    variable count : integer := 1;
  begin
    wait for 1 ns;
    if (wen = '1') then
      count := count + 1;
    end if;
    idat <= std_logic_vector(to_unsigned(count, idat'length));
    wait for 9 ns;
  end process;

  output_process : process
    variable l : line;
  begin
    --wait for 1 ns;
    wait for 10 ns;
    write (l, String'("aclk: "));
    write (l, aclk);
    write (l, String'(" | w:  busy:"));
    write (l, busy);
    write (l, String'(" wen: "));
    write (l, wen);    
    write (l, String'(" idat: 0x"));
    hwrite (l, idat(15 downto 0));
    write (l, String'(" | s:  val:"));
    write (l, val);
    write (l, String'(" rdy: "));
    write (l, rdy);    
    write (l, String'(" odat: 0x"));
    hwrite (l, odat(15 downto 0));
    write (l, String'(" l: "));
    write (l, last);    
    write (l, String'(" depth: 0b"));
    write (l, debug(1 downto 0));    

    
    if (aresetn = '0') then
      write (l, String'(" (RESET)"));
    end if;
    writeline(output, l);
  end process;
  
end behaviour;
        
