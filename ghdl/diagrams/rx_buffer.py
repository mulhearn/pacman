import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import numpy as np
from vcdvcd import VCDVCD

import timing_diagram as td

# Load the VCD file
vcd_path = "rx_buffer_tb.vcd"
vcd = VCDVCD(vcd_path)

# Print all signals for reference (optional)
print("Signals in VCD:")
for s in vcd.signals:
     print(s)


fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 8))
     
TSTART  = 1290
TFINISH = 1350

aclk_t, aclk_v              = td.get_time_series_single_bit(vcd, "rx_buffer_tb.aclk",   TSTART, TFINISH)

uva_t, uva_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.uva", TSTART, TFINISH)
uvb_t, uvb_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.uvb", TSTART, TFINISH)
uvc_t, uvc_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.uvc", TSTART, TFINISH)
ura_t, ura_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.ura", TSTART, TFINISH)
urb_t, urb_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.urb", TSTART, TFINISH)
urc_t, urc_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.urc", TSTART, TFINISH)

tvalid_t, tvalid_v          = td.get_time_series_single_bit(vcd, "rx_buffer_tb.tvalid", TSTART, TFINISH)
tlast_t, tlast_v            = td.get_time_series_single_bit(vcd, "rx_buffer_tb.tlast",  TSTART, TFINISH)
tready_t, tready_v          = td.get_time_series_single_bit(vcd, "rx_buffer_tb.tready", TSTART, TFINISH)

tlk_t, tlk_va, tlk_vb, tlk_lt, tlk_lv = td.get_time_series_bus(vcd, "rx_buffer_tb.tlk[7:0]", TSTART, TFINISH, 1)
twt_t, twt_va, twt_vb, twt_lt, twt_lv = td.get_time_series_bus(vcd, "rx_buffer_tb.twt[7:0]", TSTART, TFINISH, 1)

ax1.plot(uva_t, uva_v+20, "k-")
ax1.plot(uvb_t, uvb_v+18, "k-")
ax1.plot(uvc_t, uvc_v+16, "k-")

ax1.plot(ura_t, ura_v+14, "k-")
ax1.plot(urb_t, urb_v+12, "k-")
ax1.plot(urc_t, urc_v+10, "k-")

ax1.plot(tvalid_t, tvalid_v+4, "k-")
ax1.plot(tlast_t,  tlast_v+2,   "k-")
ax1.plot(tready_t, tready_v+0,  "k-")

ax1.plot(twt_t, twt_va+8,  "k-")
ax1.plot(twt_t, twt_vb+8,  "k-")

ax1.plot(tlk_t, tlk_va+6,  "k-")
ax1.plot(tlk_t, tlk_vb+6,  "k-")

for i in range(tlk_lt.size):
     ax1.text(tlk_lt[i],    6.2, "0x{:02X}".format(tlk_lv[i]), fontsize = 12)

for i in range(twt_lt.size):
     ax1.text(twt_lt[i],    8.2, "0x{:02X}".format(twt_lv[i]), fontsize = 12)

yticks = [0.5, 2.5, 4.5, 6.5, 8.5, 10.5, 12.5, 14.5, 16.5, 18.5, 20.5] 
ytick_labels = ['tready', 'tlast', 'tvalid', 'tdata', 'ttype', 'uready(2)', 'uready(1)', 'uready(0)', 'uvalid(2)', 'uvalid(1)', 'uvalid(0)']
ax1.set_yticks(yticks, ytick_labels, fontsize=14, rotation=30)
ax1.set_ylim(0, 22)
#plt.xlabel('Time (ns)')
ax1.set_xlim(TSTART, TFINISH)

TSTART  = 1780
TFINISH = 1840

aclk_t, aclk_v              = td.get_time_series_single_bit(vcd, "rx_buffer_tb.aclk",   TSTART, TFINISH)

uva_t, uva_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.uva", TSTART, TFINISH)
uvb_t, uvb_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.uvb", TSTART, TFINISH)
uvc_t, uvc_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.uvc", TSTART, TFINISH)
ura_t, ura_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.ura", TSTART, TFINISH)
urb_t, urb_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.urb", TSTART, TFINISH)
urc_t, urc_v                = td.get_time_series_single_bit(vcd, "rx_buffer_tb.urc", TSTART, TFINISH)

tvalid_t, tvalid_v          = td.get_time_series_single_bit(vcd, "rx_buffer_tb.tvalid", TSTART, TFINISH)
tlast_t, tlast_v            = td.get_time_series_single_bit(vcd, "rx_buffer_tb.tlast",  TSTART, TFINISH)
tready_t, tready_v          = td.get_time_series_single_bit(vcd, "rx_buffer_tb.tready", TSTART, TFINISH)

tlk_t, tlk_va, tlk_vb, tlk_lt, tlk_lv = td.get_time_series_bus(vcd, "rx_buffer_tb.tlk[7:0]", TSTART, TFINISH, 1)
twt_t, twt_va, twt_vb, twt_lt, twt_lv = td.get_time_series_bus(vcd, "rx_buffer_tb.twt[7:0]", TSTART, TFINISH, 1)

ax2.plot(uva_t, uva_v+20, "k-")
ax2.plot(uvb_t, uvb_v+18, "k-")
ax2.plot(uvc_t, uvc_v+16, "k-")

ax2.plot(ura_t, ura_v+14, "k-")
ax2.plot(urb_t, urb_v+12, "k-")
ax2.plot(urc_t, urc_v+10, "k-")

ax2.plot(tvalid_t, tvalid_v+4, "k-")
ax2.plot(tlast_t,  tlast_v+2,   "k-")
ax2.plot(tready_t, tready_v+0,  "k-")

ax2.plot(twt_t, twt_va+8,  "k-")
ax2.plot(twt_t, twt_vb+8,  "k-")

ax2.plot(tlk_t, tlk_va+6,  "k-")
ax2.plot(tlk_t, tlk_vb+6,  "k-")

ax2.set_xlim(TSTART, TFINISH)
for i in range(tlk_lt.size):
     ax2.text(tlk_lt[i],    6.2, "0x{:02X}".format(tlk_lv[i]), fontsize = 12)

for i in range(twt_lt.size):
     ax2.text(twt_lt[i],    8.2, "0x{:02X}".format(twt_lv[i]), fontsize = 12)

ax2.set_yticks([], [])
ax2.set_ylim(0, 22)

ax1.spines['right'].set_visible(False)
ax2.spines['left'].set_visible(False)

fig.text(0.5, 0.04, 'Time (ns)', ha='center', va='center', fontsize=14)
plt.savefig("rx_buffer.pdf")
plt.show()
