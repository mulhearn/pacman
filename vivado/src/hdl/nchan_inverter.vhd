library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity nchan_inverter is
  generic (
    C_NCHAN : natural := C_NUM_TILE
  );
  port (
    --clock and active-high reset:
    CLK_I      : in  std_logic;
    RST_I      : in  std_logic;

    -- signal input (active-high)
    SIG_I      : in  std_logic_vector(C_NCHAN-1 downto 0);

    -- polarity configuration, 1-bit per channel, 1=active-low
    POLARITY_I : in  std_logic_vector(C_NCHAN-1 downto 0);

    -- signal output (active-high or low based on config)
    SIG_O      : out std_logic_vector(C_NCHAN-1 downto 0)
    );
end entity nchan_inverter;

architecture rtl of nchan_inverter is
  signal sig_next : std_logic_vector(C_NCHAN-1 downto 0);
begin
  -- combinational inversion
  gen_inv: for i in 0 to C_NCHAN-1 generate
  begin
    sig_next(i) <= not SIG_I(i) when POLARITY_I(i) = '1' else SIG_I(i);
  end generate;

  -- registered output
  process (CLK_I)
  begin
    if RST_I = '1' then
        SIG_O <= (others => '0');
    elsif rising_edge(CLK_I) then
      SIG_O <= sig_next;
    end if;
  end process;
end architecture rtl;
