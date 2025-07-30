import numpy as np
from vcdvcd import VCDVCD

def get_time_series(vcd, name, tmin, tmax):
     tv = vcd[name].tv
     ts = []  # in nanoseconds
     val = [] # as integer
     last_before_tmin = None

     for ts_fs, val_bin in tv:
          # convert fs to ns:
          ts_ns = round(ts_fs / 1_000_000)
          if ts_ns < tmin:
               last_before_tmin = (ts_ns, val_bin)
          else:
               ts.append(ts_ns)
               val.append(int(val_bin, 2))
          if ts_ns > tmax:
               break

     if last_before_tmin is not None:
          ts.insert(0, last_before_tmin[0])
          val.insert(0, int(last_before_tmin[1], 2))

     # If signal becomes constant before tmax, pad with a last value far past plot boundary
     if ts and ts[-1] < tmax:
          ts.append(tmax+100)
          val.append(val[-1])

     return np.array(ts), np.array(val)

def get_transitions(ts, slope_ns):
     ts = np.asarray(ts)
     t0 = ts - slope_ns/2
     t1 = ts + slope_ns/2

     x = np.empty(2 * len(ts))
     x[0::2] = t0
     x[1::2] = t1

     i = np.arange(len(ts))
     yup = np.empty_like(x)
     ydn = np.empty_like(x)

     yup[0::2] = ((i + 1) % 2)
     yup[1::2] = (i % 2)

     ydn[0::2] = (i % 2)
     ydn[1::2] = ((i + 1) % 2)

     return x, yup, ydn


def get_time_series_single_bit(vcd, name, tmin, tmax):
     ts, val     = get_time_series(vcd, name, tmin, tmax)
     t, yup, ydn = get_transitions(ts, 0)
     if (val[0]==0):
          return t, yup
     else:
          return t, ydn

def get_time_series_bus(vcd, name, tmin, tmax, slope_ns):
     ts, val     = get_time_series(vcd, name, tmin, tmax)
     t, yup, ydn = get_transitions(ts, slope_ns)

     if (ts[0] < tmin):
          ts[0] = tmin
     mask = (ts<tmax)

     ts = ts+slope_ns/2

     return t, yup, ydn, ts[mask], val[mask]
