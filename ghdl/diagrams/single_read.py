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

TSTART  = 50
TFINISH = 85
     
clk_t, clk_v              = td.get_time_series_single_bit(vcd, "global_registers_tb.clk", TSTART, TFINISH)
rupdate_t, rupdate_v        = td.get_time_series_single_bit(vcd, "global_registers_tb.rupdate", TSTART, TFINISH)
rack_t, rack_v              = td.get_time_series_single_bit(vcd, "global_registers_tb.rack", TSTART, TFINISH)

raddr_t, raddr_vup, raddr_vdn, raddr_lt, raddr_lv = td.get_time_series_bus(vcd, "global_registers_tb.raddr[15:0]", TSTART, TFINISH, 1)
rdata_t, rdata_vup, rdata_vdn, rdata_lt, rdata_lv = td.get_time_series_bus(vcd, "global_registers_tb.rdata[31:0]", TSTART, TFINISH, 1)

plt.figure(figsize=(8,4))
plt.plot(clk_t, clk_v+10, "k-")
plt.plot(rupdate_t, rupdate_v+8, "k-")
plt.plot(raddr_t, raddr_vup+6,  "k-")
plt.plot(raddr_t, raddr_vdn+6,  "k-")
plt.plot(rdata_t, rdata_vup+4,  "k-")
plt.plot(rdata_t, rdata_vdn+4,  "k-")
plt.plot(rack_t, rack_v+2,  "k-")

for i in range(raddr_lt.size):
     plt.text(raddr_lt[i],    6.2, "0x{:X}".format(raddr_lv[i]), fontsize = 14)

for i in range(rdata_lt.size):
     plt.text(rdata_lt[i],    4.2, "0x{:X}".format(rdata_lv[i]), fontsize = 14)

yticks = [2.5, 4.5, 6.5, 8.5, 10.5] 
ytick_labels = ['rack', 'rdata', 'raddr', 'rupdate', 'clk']
plt.yticks(yticks, ytick_labels, fontsize=14, rotation=30)
plt.xlim(TSTART, TFINISH)
plt.xlabel('Time (ns)')
plt.tight_layout()
plt.savefig("single_read.pdf")
plt.show()
