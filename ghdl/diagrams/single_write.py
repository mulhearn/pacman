import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import numpy as np
from vcdvcd import VCDVCD

import timing_diagram as td

# Load the VCD file
vcd_path = "global_registers_tb.vcd"
vcd = VCDVCD(vcd_path)

# Print all signals for reference (optional)
print("Signals in VCD:")
for s in vcd.signals:
     print(s)

TSTART  = 10
TFINISH = 45
     

clk_t, clk_v              = td.get_time_series_single_bit(vcd, "global_registers_tb.clk", TSTART, TFINISH)
wupdate_t, wupdate_v        = td.get_time_series_single_bit(vcd, "global_registers_tb.wupdate", TSTART, TFINISH)
wack_t, wack_v              = td.get_time_series_single_bit(vcd, "global_registers_tb.wack", TSTART, TFINISH)

waddr_t, waddr_vup, waddr_vdn, waddr_lt, waddr_lv = td.get_time_series_bus(vcd, "global_registers_tb.waddr[15:0]", TSTART, TFINISH, 1)
wdata_t, wdata_vup, wdata_vdn, wdata_lt, wdata_lv = td.get_time_series_bus(vcd, "global_registers_tb.wdata[31:0]", TSTART, TFINISH, 1)

plt.figure(figsize=(8,4))
plt.plot(clk_t, clk_v+10, "k-")
plt.plot(wupdate_t, wupdate_v+8, "k-")
plt.plot(waddr_t, waddr_vup+6,  "k-")
plt.plot(waddr_t, waddr_vdn+6,  "k-")
plt.plot(wdata_t, wdata_vup+4,  "k-")
plt.plot(wdata_t, wdata_vdn+4,  "k-")
plt.plot(wack_t, wack_v+2,  "k-")

for i in range(waddr_lt.size):
     plt.text(waddr_lt[i],    6.2, "0x{:X}".format(waddr_lv[i]), fontsize = 14)

for i in range(wdata_lt.size):
     plt.text(wdata_lt[i],    4.2, "0x{:X}".format(wdata_lv[i]), fontsize = 14)

yticks = [2.5, 4.5, 6.5, 8.5, 10.5] 
ytick_labels = ['wack', 'wdata', 'waddr', 'wupdate', 'clk']
plt.yticks(yticks, ytick_labels, fontsize=14, rotation=30)
plt.xlim(TSTART, TFINISH)
plt.xlabel('Time (ns)')
plt.tight_layout()
plt.savefig("single_write.pdf")
plt.show()
