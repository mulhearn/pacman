library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package version is
  constant C_FIRMWARE_MAJOR  : integer  := 3;
  constant C_FIRMWARE_MINOR  : integer  := 5;
  constant C_FIRMWARE_LETTER : integer  := 0;
  constant C_HARDWARE_MAJOR  : integer  := 1;
  constant C_HARDWARE_MINOR  : integer  := 5;
  constant C_HARDWARE_LETTER : integer  := 0;
end package version;
