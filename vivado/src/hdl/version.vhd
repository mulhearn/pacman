library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package version is
  constant C_FW_MAJOR : integer  := 3;
  constant C_FW_MINOR : integer  := 1;
  constant C_FW_BUILD : integer  := 16#7FFF0000#;
  constant C_HW_CODE  : integer  := 16#0A150000#;
end package version;
