library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

-- poke_sync.vhd
-- Synchronizes a poke (single-bit update) and its associated payload
-- from a different clock domain.
--
-- Inputs with "_A" suffix are asynchronous (CDC) signals from the source domain.
-- Outputs are synchronized to CLK_I domain.
-- Generic PAYLOAD_WIDTH controls the width of the payload vector.
--
-- We use a stable-then-acknowledge prototol.  DONE is held low until
-- the second clock cycle after the poke is sent out.  This ensures
-- that any registers updated in the clock cycle immediately following
-- the single bit update have already been stable for one full clock
-- cycle by the time that BUSY is deasserted in the other clock domain.
--

entity poke_sync is
  generic ( PAYLOAD_WIDTH : integer := 16 );

  port (
    -- clock and active-high reset for slow clock domain:
    CLK_I       : in  std_logic;
    RST_I	: in  std_logic;

    -- The synchronized update signal (poke) and it's associated payload.
    POKE_O      : out std_logic;
    PAYLOAD_O   : out std_logic_vector(PAYLOAD_WIDTH-1 downto 0);

    -- interface to update_request in the requesting domain:
    REQUEST_A   : in  std_logic;  -- A: asynchronous (CDC) input
    REPLY_O     : out std_logic;

    -- additional payload from the fast clock domain, held stable during request.
    PAYLOAD_A   : in  std_logic_vector(PAYLOAD_WIDTH-1 downto 0) -- A: asynchronous (CDC) input
  );
end;

architecture behavioral of poke_sync is
  signal clk         : std_logic;
  signal rst         : std_logic;
  signal update_comb : std_logic;

  signal update      : std_logic;
  signal update_z    : std_logic;
  signal done        : std_logic;
  signal payload     : std_logic_vector(PAYLOAD_WIDTH-1 downto 0);

  -- the handshake ensures that this register is stable when read:
  signal payload_sync   : std_logic_vector(PAYLOAD_WIDTH-1 downto 0);
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of payload_sync: signal is "TRUE";

  component update_reply is
    port (
      CLK_I	      : in  std_logic;
      RST_I	      : in  std_logic;
      UPDATE_O        : out std_logic;
      UPDATE_COMB_O   : out std_logic;
      DONE_I          : in  std_logic;
      REQUEST_A       : in  std_logic;
      REPLY_O         : out std_logic
    );
  end component;

begin
  clk <= CLK_I;
  rst <= RST_I;
  POKE_O    <= update;
  PAYLOAD_O <= payload;

  rep0: update_reply port map (
    CLK_I         => clk,
    RST_I         => rst,
    UPDATE_COMB_O => update_comb,
    DONE_I        => done,
    REQUEST_A     => REQUEST_A,
    REPLY_O       => REPLY_O
  );

  payload0: process(clk, rst)
  begin
    if (rst = '1') then
      payload_sync <= (others => '0');
    elsif (rising_edge(clk)) then
      payload_sync <= PAYLOAD_A;
    end if;
  end process;

  pulse0: process(clk, rst)
  begin
    if (rst = '1') then
      done    <= '0';
      update  <= '0';
      payload <= (others => '0');
    elsif (rising_edge(clk)) then
      done     <= update_z;
      update_z <= update;
      if (update_comb = '1') then
        update <= '1';
        payload <= payload_sync;
      else
        update <= '0';
        payload <= (others => '0');
      end if;
    end if;
  end process;

end;
