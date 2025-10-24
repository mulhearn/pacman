library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.common.all;

entity atc_mux is
  generic (
    constant C_CONFIG_WIDTH     : integer := 32;
    constant C_NUM_TILE         : integer := 10
  );

  port (
    --clock and active-high reset:
    CLK_I	: in  std_logic;
    RST_I	: in  std_logic;

    --Input stimuli: one-clock cycle long active high pulses LEMO is
    --from front-panel, pokes are from the PS, and logic is from the
    --logic unit
    LEMO_A_I	: in  std_logic;
    LEMO_B_I	: in  std_logic;
    POKE_C_I	: in  std_logic;
    POKE_D_I	: in  std_logic;
    LOGIC_E_I	: in  std_logic;
    LOGIC_F_I	: in  std_logic;

    -- Transient masks: the pokes (from PS) include a mask applicable
    -- to this poke only:
    MASK_C_I    : in  std_logic_vector(C_NUM_TILE-1 downto 0);
    MASK_D_I    : in  std_logic_vector(C_NUM_TILE-1 downto 0);

    --Configuration:  each stimuli has a destination configuration, detailing
    -- how and where it should be forwarded:
    -- MSB: 0XMMM DDDO LSB O=output enables, D=duration, M=output mask
    -- O(0)= enable G, O(1) = enable H, O(2) = enable T O(3) = RESERVED
    -- D(0-11) pulse duration (maximum is 4095 clock cycles)
    -- M(0-9) tile mask for G/H outputs, e.g. M(0) = TILE 1, M(1) = TILE 2, ...
    DST_LEMO_A_I  : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_LEMO_B_I  : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_POKE_C_I  : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_POKE_D_I  : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_LOGIC_E_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
    DST_LOGIC_F_I : in std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);

    --output
    G_O     : out std_logic_vector(9 downto 0) := (others => '0');
    H_O     : out std_logic_vector(9 downto 0) := (others => '0');
    T_O     : out std_logic
  );
end;

architecture behavioral of atc_mux is
  type config_arr is array (0 to 5) of std_logic_vector(C_RB_DATA_WIDTH-1 downto 0);
  type cnt_arr is array (0 to 5) of unsigned(11 downto 0); --counter of duration
  signal clk             : std_logic;
  signal rst             : std_logic;
  signal output_g        : std_logic_vector(9 downto 0);
  signal output_h        : std_logic_vector(9 downto 0);
  signal output_t        : std_logic;
  signal sel_g           : std_logic_vector(5 downto 0);
  signal sel_h           : std_logic_vector(5 downto 0);
  signal sel_t           : std_logic_vector(5 downto 0);

  signal config          : config_arr;

  signal mask_c          : std_logic_vector(C_NUM_TILE-1 downto 0):= (others => '0');
  signal mask_d          : std_logic_vector(C_NUM_TILE-1 downto 0):= (others => '0');
  signal input_ext       : std_logic_vector(5 downto 0) := (others => '0'); --extend window for 6 input
  signal cnt             : cnt_arr := (others => (others => '0'));
  signal update_vec      : std_logic_vector(5 downto 0);
begin
  clk            <= CLK_I;
  rst            <= RST_I;

  update_vec <= (
  0 => LEMO_A_I,
  1 => LEMO_B_I,
  2 => POKE_C_I,
  3 => POKE_D_I,
  4 => LOGIC_E_I,
  5 => LOGIC_F_I
  );

  config   <= (
    0 => DST_LEMO_A_I,
    1 => DST_LEMO_B_I,
    2 => DST_POKE_C_I,
    3 => DST_POKE_D_I,
    4 => DST_LOGIC_E_I,
    5 => DST_LOGIC_F_I
  );

  --determine the enabled output ports for each stimuli:
  gen_port : for i in 0 to 5 generate
  begin
    sel_g(i)  <= config(i)(0);
    sel_h(i)  <= config(i)(1);
    sel_t(i) <= config(i)(2);
  end generate;



  -- extend input signal
  gen_input_ext : for j in 0 to 5 generate
    input_ext(j) <= '1' when cnt(j) > 0 else '0';
  end generate;

  process (clk, rst)
  begin
    if rst = '1' then
      for j in 0 to 5 loop
        cnt(j) <= (others => '0');
      end loop;
      mask_c <= (others => '0');
      mask_d <= (others => '0');
    elsif rising_edge(clk) then
      if update_vec(2) = '1' then
        mask_c         <= MASK_C_I;
      end if;

      if update_vec(3) = '1' then
        mask_d        <= MASK_D_I;
      end if;
      for j in 0 to 5 loop

        if update_vec(j) = '1' then
          cnt(j) <= unsigned( config(j)(15 downto 4) );
        elsif cnt(j) > 0 then
          cnt(j) <= cnt(j) - 1;
        end if;
      end loop;
    end if;
  end process;

  gen_g : for i in 0 to C_NUM_TILE-1 generate
  begin
    output_g(i) <=
      (sel_g(0) and input_ext(0) and config(0)(16+i)) or
      (sel_g(1) and input_ext(1) and config(1)(16+i)) or
      (sel_g(2) and input_ext(2) and config(2)(16+i) and mask_c(i)) or
      (sel_g(3) and input_ext(3) and config(3)(16+i) and mask_d(i)) or
      (sel_g(4) and input_ext(4) and config(4)(16+i)) or
      (sel_g(5) and input_ext(5) and config(5)(16+i));
  end generate;

  gen_h : for i in 0 to C_NUM_TILE-1 generate
  begin
    output_h(i) <=
      (sel_h(0) and input_ext(0) and config(0)(16+i)) or
      (sel_h(1) and input_ext(1) and config(1)(16+i)) or
      (sel_h(2) and input_ext(2) and config(2)(16+i) and mask_c(i)) or
      (sel_h(3) and input_ext(3) and config(3)(16+i) and mask_d(i)) or
      (sel_h(4) and input_ext(4) and config(4)(16+i)) or
      (sel_h(5) and input_ext(5) and config(5)(16+i));
  end generate;

  output_t <=
    ( sel_t(0) and input_ext(0) ) or
    ( sel_t(1) and input_ext(1) ) or
    ( sel_t(2) and input_ext(2) ) or
    ( sel_t(3) and input_ext(3) ) or
    ( sel_t(4) and input_ext(4) ) or
    ( sel_t(5) and input_ext(5) );

  process(clk,rst)
  begin
    if rst = '1' then
      G_O  <= (others => '0');
      H_O  <= (others => '0');
      T_O  <=  '0';
    elsif (rising_edge(clk)) then
      G_O  <= output_g;
      H_O  <= output_h;
      T_O  <= output_t;
    end if;
  end process;

end;
