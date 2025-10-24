library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Request an update in a different clock domain

entity update_request is
  port (
    -- clock and active-high reset (request domain)
    CLK_I	: in std_logic;
    RST_I	: in std_logic;

    -- update request:
    REQUEST_I   : in std_logic;

    -- a previous request is busy:
    BUSY_O      : out std_logic;

    -- handshake with update_reply (CDC)
    REQUEST_O   : out std_logic;
    REPLY_A     : in std_logic
  );
end;

architecture behavioral of update_request is
  signal clk        : std_logic;
  signal rst        : std_logic;
  signal request    : std_logic;
  signal busy       : std_logic;

  -- double flopping at clock domain crossing:
  signal reply_meta : std_logic; -- metastable
  signal reply_sync : std_logic; -- likely stable
  signal reply_prev : std_logic;

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of reply_meta: signal is "TRUE";
  attribute ASYNC_REG of reply_sync: signal is "TRUE";

begin
  clk              <= CLK_I;
  rst              <= RST_I;
  BUSY_O           <= busy;
  REQUEST_O        <= request;

  -- double flop synchronization of reply signal:
  process(clk, rst)
  begin
    if (rst = '1') then
      reply_meta <= '0';
      reply_sync <= '0';
      reply_prev <= '0';
      busy       <= '0';
      request    <= '0';
    elsif (rising_edge(clk)) then
      reply_meta <= REPLY_A;
      reply_sync <= reply_meta;
      reply_prev <= reply_sync;
      busy       <= busy;
      request    <= request;
      if (busy = '0') and (REQUEST_I = '1') then
        busy <= '1';
        request <= not request;
      end if;
      if (reply_prev /= reply_sync) then
        busy <= '0';
      end if;
    end if;
  end process;

end;
