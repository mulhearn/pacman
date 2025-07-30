import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import numpy as np
from vcdvcd import VCDVCD

import timing_diagram as td

# Load the VCD file
vcd_path = "tx_buffer_tb.vcd"
vcd = VCDVCD(vcd_path)

# Print all signals for reference (optional)
print("Signals in VCD:")
for s in vcd.signals:
     print(s)

TSTART  = 0
TFINISH = 310

aclk_t, aclk_v              = td.get_time_series_single_bit(vcd, "tx_buffer_tb.aclk",   TSTART, TFINISH)
tvalid_t, tvalid_v          = td.get_time_series_single_bit(vcd, "tx_buffer_tb.tvalid", TSTART, TFINISH)
tlast_t, tlast_v            = td.get_time_series_single_bit(vcd, "tx_buffer_tb.tlast",  TSTART, TFINISH)
tready_t, tready_v          = td.get_time_series_single_bit(vcd, "tx_buffer_tb.tready", TSTART, TFINISH)

tdata_t, tdata_va, tdata_vb, tdata_lt, tdata_lv = td.get_time_series_bus(vcd, "tx_buffer_tb.tdata[127:0]", TSTART, TFINISH, 1)
ovalid_t, ovalid_va, ovalid_vb, ovalid_lt, ovalid_lv = td.get_time_series_bus(vcd, "tx_buffer_tb.ovalid[39:0]", TSTART, TFINISH, 1)
oready_t, oready_va, oready_vb, oready_lt, oready_lv = td.get_time_series_bus(vcd, "tx_buffer_tb.oready[39:0]", TSTART, TFINISH, 1)

plt.figure(figsize=(12,8))
plt.plot(aclk_t, aclk_v+18, "k-")
plt.plot(tvalid_t, tvalid_v+16, "k-")
plt.plot(tlast_t,  tlast_v+14,   "k-")
plt.plot(tready_t, tready_v+12,  "k-")

plt.plot(tdata_t, tdata_va+10,  "k-")
plt.plot(tdata_t, tdata_vb+10,  "k-")

plt.plot(ovalid_t, ovalid_va+6,  "k-")
plt.plot(ovalid_t, ovalid_vb+6,  "k-")

plt.plot(oready_t, oready_va+2,  "k-")
plt.plot(oready_t, oready_vb+2,  "k-")


plt.text(tdata_lt[1]+0.2,    10.2, "H", fontsize = 12)

for i in range(1,21):
     plt.text(tdata_lt[i+1]+0.2,    10.2, i, fontsize = 12)

for i in range(ovalid_lt.size):
     plt.text(ovalid_lt[i],    7.2, "0x{:010X}".format(ovalid_lv[i]), fontsize = 12, rotation=40)

for i in range(oready_lt.size):
     plt.text(oready_lt[i],    3.2, "0x{:010X}".format(oready_lv[i]), fontsize = 12, rotation=40)


yticks = [2.5, 6.5, 10.5, 12.5, 14.5, 16.5, 18.5] 
ytick_labels = ['uready', 'uvalid', 'tdata', 'tready', 'tlast', 'tvalid', 'clk']
plt.yticks(yticks, ytick_labels, fontsize=14, rotation=30)
plt.ylim(0, 20)
plt.xlim(TSTART, TFINISH)
plt.xlabel('Time (ns)')
plt.tight_layout()
plt.savefig("tx_buffer.pdf")
plt.show()
