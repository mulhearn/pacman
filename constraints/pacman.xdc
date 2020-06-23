# pacman-v1-rev1
# UARTs
set_property IOSTANDARD LVCMOS33 [get_ports MOSI1]
set_property IOSTANDARD LVCMOS33 [get_ports MISO1]
set_property IOSTANDARD LVCMOS33 [get_ports MOSI2]
set_property IOSTANDARD LVCMOS33 [get_ports MISO2]
set_property IOSTANDARD LVCMOS33 [get_ports MOSI3]
set_property IOSTANDARD LVCMOS33 [get_ports MISO3]
set_property IOSTANDARD LVCMOS33 [get_ports MOSI4]
set_property IOSTANDARD LVCMOS33 [get_ports MISO4]
set_property PACKAGE_PIN AA22 [get_ports MOSI1]
set_property PACKAGE_PIN AB22 [get_ports MISO1]
set_property PACKAGE_PIN AA21 [get_ports MOSI2]
set_property PACKAGE_PIN AB21 [get_ports MISO2]
set_property PACKAGE_PIN Y19 [get_ports MOSI3]
set_property PACKAGE_PIN AA19 [get_ports MISO3]
set_property PACKAGE_PIN AA17 [get_ports MOSI4]
set_property PACKAGE_PIN AB17 [get_ports MISO4]
set_property PULLUP TRUE [get_ports MISO1]
set_property PULLUP TRUE [get_ports MISO2]
set_property PULLUP TRUE [get_ports MISO3]
set_property PULLUP TRUE [get_ports MISO4]

# TILE en/sel
set_property IOSTANDARD LVCMOS33 [get_ports {TILE_SEL1[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {TILE_EN1[0]}]
set_property PACKAGE_PIN W18 [get_ports {TILE_SEL1[0]}]
set_property PACKAGE_PIN Y18 [get_ports {TILE_EN1[0]}]

# RESET out
set_property IOSTANDARD LVCMOS33 [get_ports RESETN]
set_property PACKAGE_PIN W20 [get_ports RESETN]

# TRIG out
set_property IOSTANDARD LVCMOS33 [get_ports {TRIG[0]}]
set_property PACKAGE_PIN W21 [get_ports {TRIG[0]}]

# CLK out
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports CLK_P]
set_property IOSTANDARD DIFF_HSTL_II_18 [get_ports CLK_N]
set_property PACKAGE_PIN G19 [get_ports CLK_P]
set_property PACKAGE_PIN F19 [get_ports CLK_N]
