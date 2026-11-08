library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Reply to an update request from a different clock domain

entity update_reply is
  port (
    --clock and active-high reset (repliers domain)
    CLK_I	           : in  std_logic;
    RST_I	           : in  std_logic;

    --local forwarding of the received udpate request
    UPDATE_O               : out std_logic;
    --combinatoric version of above signal, to act for next clock-cycle.
    UPDATE_COMB_O          : out std_logic;

    --report previous request completed (set to 1 for immediate reply)
    DONE_I                 : in  std_logic;

    --handshake with update_request (CDC)
    REQUEST_A :            in  std_logic;
    REPLY_O                : out std_logic
  );
end;

architecture behavioral of update_reply is
  signal clk        : std_logic;
  signal rst        : std_logic;
  signal reply      : std_logic;
  signal busy       : std_logic;

  -- double flopping at clock domain crossing:
  signal request_meta : std_logic; -- metastable
  signal request_sync : std_logic; -- likely stable
  signal request_prev : std_logic;

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of request_meta: signal is "TRUE";
  attribute ASYNC_REG of request_sync: signal is "TRUE";

begin
  clk       <= CLK_I;
  rst       <= RST_I;
  REPLY_O   <= reply;

  UPDATE_COMB_O <= request_sync xor request_prev;

  -- double flop synchronization of reply signal:
  process(clk, rst)
    variable waiting : std_logic := '0';
  begin
    if (rst = '1') then
      waiting      := '0';
      request_meta <= '0';
      request_sync <= '0';
      request_prev <= '0';
      reply        <= '0';
      UPDATE_O     <= '0';
    elsif (rising_edge(clk)) then
      request_meta <= REQUEST_A;
      request_sync <= request_meta;
      request_prev <= request_sync;
      reply        <= reply;
      UPDATE_O     <= '0';
      if (request_prev /= request_sync) then
        UPDATE_O   <= '1';
        waiting := '1';
      end if;
      if waiting='1' and DONE_I='1' then
        reply <= not reply;
        waiting := '0';
      end if;
    end if;
  end process;

end;
