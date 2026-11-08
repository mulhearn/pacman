library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Forward an update request from a different clock domain, with no reply.

entity toggle_only_sync is
  port (
    --clock and active-high reset (forwarders clock domain)
    CLK_I	           : in  std_logic;
    RST_I	           : in  std_logic;

    --local forwarding of the received udpate request
    UPDATE_O               : out std_logic;
    --combinatoric version of above signal, to act for next clock-cycle.
    UPDATE_COMB_O          : out std_logic;

    --toggle from requestors clock dmain
    ASYNC_TOGGLE_I         : in  std_logic
  );
end;

architecture behavioral of toggle_only_sync is
  signal clk        : std_logic;
  signal rst        : std_logic;

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

  UPDATE_COMB_O <= request_sync xor request_prev;

  -- double flop synchronization of reply signal:
  process(clk, rst)
  begin
    if (rst = '1') then
      request_meta <= '0';
      request_sync <= '0';
      request_prev <= '0';
      UPDATE_O     <= '0';
    elsif (rising_edge(clk)) then
      request_meta <= ASYNC_TOGGLE_I;
      request_sync <= request_meta;
      request_prev <= request_sync;
      UPDATE_O     <= '0';
      if (request_prev /= request_sync) then
        UPDATE_O   <= '1';
      end if;
    end if;
  end process;

end;
