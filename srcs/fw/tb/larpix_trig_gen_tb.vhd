library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity larpix_trig_gen_tb is
  port (
    TRIG: out std_logic;
    TRIG_TYPE : out std_logic_vector(3 downto 0);
    TRIG_MASKED : out std_logic_vector(7 downto 0)
    );
end larpix_trig_gen_tb;

architecture arch_imp of larpix_trig_gen_tb is

  component larpix_trig_gen is
  port (
    MCLK : in std_logic;
    RSTN : in std_logic;
    TRIG_LEN : in unsigned(7 downto 0);
    TRIG0_MASK : in std_logic_vector(7 downto 0);
    TRIG1_MASK : in std_logic_vector(7 downto 0);
    TRIG2_MASK : in std_logic_vector(7 downto 0);
    TRIG3_MASK : in std_logic_vector(7 downto 0);        
    TRIG0_IN : in std_logic;
    TRIG1_IN : in std_logic;
    TRIG2_IN : in std_logic;
    TRIG3_IN : in std_logic;    
    TRIG: out std_logic;
    TRIG_TYPE : out std_logic_vector(3 downto 0);
    TRIG_MASKED : out std_logic_vector(7 downto 0)
    );
  end component;

  signal mclk : std_logic := '1';
  signal rstn : std_logic := '0';

  signal trig_len : unsigned(7 downto 0) := x"02";
  signal trig0_mask : std_logic_vector(7 downto 0) := x"00";
  signal trig1_mask : std_logic_vector(7 downto 0) := x"00";
  signal trig2_mask : std_logic_vector(7 downto 0) := x"00";
  signal trig3_mask : std_logic_vector(7 downto 0) := x"00";  

  signal trig0_in : std_logic := '0';
  signal trig1_in : std_logic := '0';
  signal trig2_in : std_logic := '0';
  signal trig3_in : std_logic := '0';

  signal trig_out : std_logic;
  signal trig_type_out : std_logic_vector(3 downto 0);
  signal trig_masked_out : std_logic_vector(7 downto 0);

begin
  mclk <= not mclk after 50 ns;
  rstn <= '0' after 0 ns,
          '1' after 1000 ns;
  
  TRIG <= trig_out;
  TRIG_TYPE <= trig_type_out;
  TRIG_MASKED <= trig_masked_out;

  process is
  begin
    wait until rstn = '1';
    wait until rising_edge(mclk);

    -- test trig0
    trig0_in <= '1';
    wait for 200 ns;
    trig0_in <= '0';
    wait until falling_edge(trig_out);

    -- test trig1
    trig1_in <= '1';
    wait for 200 ns;
    trig1_in <= '0';
    wait until falling_edge(trig_out);

    -- test update trigger length
    trig_len <= x"04";
    wait until rising_edge(mclk);
    trig2_in <= '1';
    wait for 200 ns;
    trig2_in <= '0';
    wait until falling_edge(trig_out);

    -- test update trigger mask
    trig3_mask <= b"01010101";
    wait until rising_edge(mclk);
    trig3_in <= '1';
    wait for 200 ns;
    trig3_in <= '0';
    wait until falling_edge(trig_out);
    
    trig2_in <= '1';
    wait for 200 ns;
    trig2_in <= '0';
    wait until falling_edge(trig_out);

    -- test simultaneous (async) triggers w/ trigger mask
    trig1_mask <= x"0F";
    wait until rising_edge(mclk);
    trig3_in <= '1';
    wait for 50 ns;
    trig1_in <= '1';
    wait for 150 ns;
    trig3_in <= '0';
    wait for 50 ns;
    trig1_in <= '0';
    wait until falling_edge(trig_out);
    
    -- test different phase delays
    trig0_mask <= x"FE";
    trig1_mask <= x"EF";
    trig2_mask <= x"FD";
    trig3_mask <= x"DF";
    wait until rising_edge(mclk);
    trig0_in <= '1';
    wait for 50 ns;
    trig1_in <= '1';
    wait for 50 ns;
    trig2_in <= '1';
    wait for 50 ns;
    trig3_in <= '1';
    wait for 50 ns;
    trig0_in <= '0';
    wait for 50 ns;
    trig1_in <= '0';
    wait for 50 ns;
    trig2_in <= '0';
    wait for 50 ns;
    trig3_in <= '0';
    wait until falling_edge(trig_out);
    
  end process;

  larpix_trig_gen_inst : larpix_trig_gen port map(
    MCLK => mclk,
    RSTN => rstn,
    TRIG_LEN => trig_len,
    TRIG0_MASK => trig0_mask,
    TRIG1_MASK => trig1_mask,
    TRIG2_MASK => trig2_mask,
    TRIG3_MASK => trig3_mask,
    TRIG0_IN => trig0_in,
    TRIG1_IN => trig1_in,
    TRIG2_IN => trig2_in,
    TRIG3_IN => trig3_in,
    TRIG => trig_out,
    TRIG_TYPE => trig_type_out,
    TRIG_MASKED => trig_masked_out
    );

end arch_imp;
