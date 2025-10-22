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


fig, ax = plt.subplots(1, 1, figsize=(10, 8))
     
TSTART  = 450
TFINISH = 900

clk_t, clk_v              = td.get_time_series_single_bit(vcd, "rx_buffer_tb.clk",   TSTART, TFINISH)

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

ax.plot(uva_t, uva_v+20, "k-")
ax.plot(uvb_t, uvb_v+18, "k-")
ax.plot(uvc_t, uvc_v+16, "k-")

ax.plot(ura_t, ura_v+14, "k-")
ax.plot(urb_t, urb_v+12, "k-")
ax.plot(urc_t, urc_v+10, "k-")

ax.plot(tlk_t, tlk_va+6,  "k-")
ax.plot(tlk_t, tlk_vb+6,  "k-")

ax.plot(tvalid_t, tvalid_v+4, "k-")
ax.plot(tlast_t,  tlast_v+2,   "k-")
ax.plot(tready_t, tready_v+0,  "k-")

ax.text(tlk_lt[1],    7.2, "0x{:02X}...".format(tlk_lv[1]), fontsize = 12, rotation=40)
ax.text(tlk_lt[5],    7.2, "0x{:02X}...".format(tlk_lv[5]), fontsize = 12, rotation=40)
ax.text(tlk_lt[9],    7.2, "0x{:02X}...".format(tlk_lv[9]), fontsize = 12, rotation=40)
ax.text(tlk_lt[12],    7.2, "0x{:02X}...".format(tlk_lv[12]), fontsize = 12, rotation=40)

yticks = [0.5, 2.5, 4.5, 6.5, 10.5, 12.5, 14.5, 16.5, 18.5, 20.5] 
ytick_labels = ['tready', 'tlast', 'tvalid', 'tdata', 'uready(8)', 'uready(5)', 'uready(2)', 'uvalid(8)', 'uvalid(5)', 'uvalid(2)']
ax.set_yticks(yticks, ytick_labels, fontsize=14, rotation=30)
ax.set_ylim(0, 22)
#plt.xlabel('Time (ns)')
ax.set_xlim(TSTART, TFINISH)

fig.text(0.5, 0.04, 'Time (ns)', ha='center', va='center', fontsize=14)
plt.savefig("rx_buffer.pdf")
plt.show()
