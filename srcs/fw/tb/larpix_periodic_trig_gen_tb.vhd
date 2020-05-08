library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_periodic_trig_gen_tb is
  port (
    O : out std_logic
    );
end larpix_periodic_trig_gen_tb;

architecture implementation of larpix_periodic_trig_gen_tb is

  component larpix_periodic_trig_gen is
  generic(
    LEN : unsigned(7 downto 0) := x"14"
    );
  port (
    ACLK : in std_logic;
    ARESETN : in std_logic;
    EN : in std_logic;
    CYCLES : in unsigned(31 downto 0);
    O : out std_logic
    );
  end component;

  signal clk : std_logic:= '1';
  signal rstn : std_logic := '0';
  signal trig_out : std_logic;

  signal en : std_logic := '1';
  signal cycles : unsigned(31 downto 0) := x"00000040"; 

begin

  clk <= not clk after 5 ns;
  rstn <= '0' after 0 ns,
          '1' after 100 ns;
  
  O <= trig_out;

  process
  begin
    wait until rstn = '1';
    wait until rising_edge(clk);
    -- test trigger generation
    wait until trig_out = '1';
    wait until trig_out = '0';
    -- check period duration
    wait until trig_out = '1';
    wait until trig_out = '0';
    -- check update period duration
    cycles <= x"00000080";
    wait until trig_out = '0';
    wait until trig_out = '1';
    wait until trig_out = '0';
    wait until trig_out = '1';
    -- check disable
    en <= '0';
    wait for 3000 ns;
    en <= '1';   
  end process;

  larpix_periodic_trig_gen_inst : larpix_periodic_trig_gen port map(
    ACLK => clk,
    ARESETN => rstn,
    EN => en,
    CYCLES => cycles,
    O => trig_out
    );

end implementation;
