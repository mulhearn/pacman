library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

-- Request an update in a different clock domain

entity slow_poke is
  port (
    -- clock and active-high reset for slow clock domain:
    CLK_SLOW_I	    : in  std_logic;
    RST_SLOW_I	    : in  std_logic;

    PULSE_CYCLES_I  : in  std_logic_vector(C_REG16_WIDTH-1 downto 0);
    
    -- poke and associated mask in the slow clock domain:
    POKE_O          : out std_logic;
    MASK_O          : out std_logic_vector(C_REG16_WIDTH-1 downto 0);

    -- interface to request in the fast clock domain
    REPLY_O         : out std_logic;
    ASYNC_REQUEST_I : in  std_logic;
    ASYNC_MASK_I    : in  std_logic_vector(C_REG16_WIDTH-1 downto 0)
  );
end;

architecture behavioral of slow_poke is
  signal clk         : std_logic;
  signal rst         : std_logic;
  signal update_comb : std_logic;
  signal done        : std_logic;

  signal poke        : std_logic;
  signal mask        : std_logic_vector(C_REG16_WIDTH-1 downto 0);

  -- the update handshake ensures this register is stable when read
  -- the attribute is so that tools do not try to meet timing requirements.
  signal mask_sync   : std_logic_vector(C_REG16_WIDTH-1 downto 0);
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of mask_sync: signal is "TRUE";

  
  component update_reply is
    port (
      CLK_I	      : in  std_logic;
      RST_I	      : in  std_logic;
      UPDATE_O        : out std_logic;
      UPDATE_COMB_O   : out std_logic;
      ASYNC_REQUEST_I : in  std_logic;
      DONE_I          : in  std_logic; 
      REPLY_O         : out std_logic
      );
  end component;
  
begin
  clk <= CLK_SLOW_I;
  rst <= RST_SLOW_I;
  POKE_O <= poke;
  MASK_O <= mask;
  
  rep0: update_reply port map (
    CLK_I           => clk,
    RST_I           => rst,
    UPDATE_COMB_O   => update_comb,
    ASYNC_REQUEST_I => ASYNC_REQUEST_I,
    DONE_I          => done,
    REPLY_O         => REPLY_O
  );
  
  mask0: process(clk, rst)
  begin
    if (rst = '1') then
      mask_sync <= (others => '0'); 
    elsif (rising_edge(clk)) then
      mask_sync <= ASYNC_MASK_I;
    end if;
  end process;

  pulse0: process(clk, rst)
    variable timeout : integer := 0;
  begin
    if (rst = '1') then
      timeout := 0;
      poke <= '0';
      mask <= (others => '0'); 
      done   <= '0';
    elsif (rising_edge(clk)) then

      if (update_comb = '1') then
        poke <= '1';
        mask <= mask_sync;
        timeout := to_integer(unsigned(PULSE_CYCLES_I));
      end if;

      if (timeout > 0) then
        timeout := timeout -1;
        if (timeout = 0) then
          done <= '1';
        else
          done <= '0';
        end if;
      else
        poke <= '0';
        mask <= (others => '0');
        done <= '0';
      end if;
    end if;
  end process;
  
end;
