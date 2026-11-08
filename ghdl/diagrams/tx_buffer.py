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
TFINISH = 600

clk_t, clk_v                = td.get_time_series_single_bit(vcd, "tx_buffer_tb.clk",   TSTART, TFINISH)
tvalid_t, tvalid_v          = td.get_time_series_single_bit(vcd, "tx_buffer_tb.tvalid", TSTART, TFINISH)
tlast_t, tlast_v            = td.get_time_series_single_bit(vcd, "tx_buffer_tb.tlast",  TSTART, TFINISH)
tready_t, tready_v          = td.get_time_series_single_bit(vcd, "tx_buffer_tb.tready", TSTART, TFINISH)

tdata_t, tdata_va, tdata_vb, tdata_lt, tdata_lv      = td.get_time_series_bus(vcd, "tx_buffer_tb.tdata[63:0]", TSTART, TFINISH, 1)
uvalid_t, uvalid_va, uvalid_vb, uvalid_lt, uvalid_lv = td.get_time_series_bus(vcd, "tx_buffer_tb.uvalid[39:0]", TSTART, TFINISH, 1)
uready_t, uready_va, uready_vb, uready_lt, uready_lv = td.get_time_series_bus(vcd, "tx_buffer_tb.uready[39:0]", TSTART, TFINISH, 1)

uvalida_t, uvalida_v        = td.get_time_series_single_bit(vcd, "tx_buffer_tb.uvalid_a", TSTART, TFINISH)
uvalidb_t, uvalidb_v        = td.get_time_series_single_bit(vcd, "tx_buffer_tb.uvalid_b", TSTART, TFINISH)
uvalidc_t, uvalidc_v        = td.get_time_series_single_bit(vcd, "tx_buffer_tb.uvalid_c", TSTART, TFINISH)


ureadya_t, ureadya_v        = td.get_time_series_single_bit(vcd, "tx_buffer_tb.uready_a", TSTART, TFINISH)
ureadyb_t, ureadyb_v        = td.get_time_series_single_bit(vcd, "tx_buffer_tb.uready_b", TSTART, TFINISH)
ureadyc_t, ureadyc_v        = td.get_time_series_single_bit(vcd, "tx_buffer_tb.uready_c", TSTART, TFINISH)




plt.figure(figsize=(10,8))
plt.plot(clk_t, clk_v+18, "k-")
plt.plot(tvalid_t, tvalid_v+16, "k-")
plt.plot(tlast_t,  tlast_v+14,   "k-")
plt.plot(tready_t, tready_v+12,  "k-")

plt.plot(tdata_t, tdata_va+10,  "k-")
plt.plot(tdata_t, tdata_vb+10,  "k-")

#plt.plot(uvalid_t, uvalid_va+6,  "k-")
#plt.plot(uvalid_t, uvalid_vb+6,  "k-")

plt.plot(uvalida_t, ureadya_v+6,  "k-")
plt.plot(uvalidb_t, ureadyb_v+6,  "k-")
plt.plot(uvalidc_t, ureadyc_v+6,  "k-")



plt.plot(ureadya_t, ureadya_v+2,  "k-")
plt.plot(ureadyb_t, ureadyb_v+2,  "k-")
plt.plot(ureadyc_t, ureadyc_v+2,  "k-")


plt.text(tdata_lt[1]+0.2,    11.2, "H", fontsize = 12)
plt.text(tdata_lt[2]+0.2,    11.2, "1", fontsize = 12)
plt.text(tdata_lt[3]+0.2,    11.2, "2", fontsize = 12)
plt.text(tdata_lt[4]+0.2,    11.2, "3...", fontsize = 12)
plt.text(tdata_lt[11]+0.2,   11.2, "10...", fontsize = 12)
plt.text(tdata_lt[21]+0.2,   11.2, "20...", fontsize = 12)
plt.text(tdata_lt[31]+0.2,   11.2, "30...", fontsize = 12)
plt.text(tdata_lt[41]+0.2,   11.2, "40", fontsize = 12)

for i in range(uvalid_lt.size):
     if (uvalid_lv[i]>0):
          plt.text(uvalid_lt[i],    7.2, "0x{:010X}".format(uvalid_lv[i]), fontsize = 12, rotation=40)

for i in range(uready_lt.size):
     if (uready_lv[i]>0):
          plt.text(uready_lt[i],    3.2, "0x{:010X}".format(uready_lv[i]), fontsize = 12, rotation=40)

yticks = [2.5, 6.5, 10.5, 12.5, 14.5, 16.5, 18.5] 
ytick_labels = ['uready', 'uvalid', 'tdata', 'tready', 'tlast', 'tvalid', 'clk']
plt.yticks(yticks, ytick_labels, fontsize=14, rotation=30)
plt.ylim(0, 20)
plt.xlim(TSTART, TFINISH)
plt.xlabel('Time (ns)')
plt.tight_layout()
plt.savefig("tx_buffer.pdf")
plt.show()
