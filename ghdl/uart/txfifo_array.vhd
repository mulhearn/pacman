-- txfifo_array
--
-- An array of 40 FIFOs

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity txfifo_array is      
  port (
    ACLK            : in  std_logic;
    ARESETN         : in  std_logic;
    DIN             : in  std_logic_vector(31 downto 0);
    WR_EN           : in  std_logic_vector(39 downto 0);
    BUSY            : out std_logic_vector(39 downto 0);
    --
    RD_EN           : in std_logic_vector(39 downto 0);    
    -- debugging:
    DEBUG           : out std_logic_vector(7 downto 0) := (others => '0')
    );
end;
  
architecture behavioral of txfifo_array is
  signal clk      : std_logic;
  signal rst      : std_logic;
  signal idata    : std_logic_vector(31 downto 0);
  signal wen      : std_logic_vector(39 downto 0);
  signal ren      : std_logic_vector(39 downto 0);
  signal bsy      : std_logic_vector(39 downto 0) := (others => '0');

  component txfifo is      
    port (
      clk : IN STD_LOGIC;
      srst : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      wr_en : IN STD_LOGIC;
      rd_en : IN STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      full : OUT STD_LOGIC;
      almost_full : OUT STD_LOGIC;
      empty : OUT STD_LOGIC
      );
  end component;
  
begin
  -- combinatoric signals:
  clk <= ACLK;
  BUSY <= bsy;

  u0: for i in 0 to 39 generate
    txfifo0: txfifo
      port map(
      clk => clk,
      srst => rst,
      din => din,
      wr_en => wen(i),
      rd_en => red(i),
      --dout : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      --full : OUT STD_LOGIC;
      almost_full => bsy(i)
      --empty : OUT STD_LOGIC
    );
  end generate u0;  
end;  
