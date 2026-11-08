# PACMAN origins:  the 2024 experiments that led to zipline

This branch is a historical record only.  It records three experiments from 2024, between the legacy firmware
(branch `legacy-archive-2026`) and zipline (branch `zipline-archive`, development now in pacman-firmware and
pacman-software).  Each was merged in whole, with its history and original hashes.  The merges change no files, so this
branch holds only this README.

## The experiments

| Merge | Branch (suggested name) | Tip | When | What |
|---|---|---|---|---|
| a1be159 | legacy-gpio-only-hwcheck-2020.2 | 93a0dc3 | 2024-06 to 07 | The 1v5 board bring-up on the old flow:  the bare-metal flow ported to Vivado 2020.2, hello world, then a GPIO-only hwcheck for the first checkout of the new hardware, and the V5 schematics. |
| 1db3c1e | pacman-1v5-experimental-reorganized-2020_2 | 8657bb2 | 2024-07 to 08 | The prototype of zipline's layout and build flow:  a server fix (address space matched to the device tree), AXI-lite read and read/write demos on the Trenz test board with a bare-metal demo, then the 1v5 firmware built by a new Tcl creation flow (`vivado/`, `apps/`, `create.tcl`, `runsib.tcl`). |
| fac9a5c | working-hw-demo-2020.2 | eb371ec | 2024-10-04 | The first zipline firmware (the first GHDL modules:  axi, rx, tx, timing, with testbenches) tried in Vivado 2020.2, from zipline's second commit. |

## Why zipline is in Vivado 2023.2

Vivado 2020.2 has a bug (AMD answer record 58038):  when a block design is recreated from Tcl, the AXI-stream subset
converter loses its settings at validation, and the data stream into the DMA is wrong.  Every workaround for the DMA
path failed in 2020.2.  Only a fresh start in Vivado 2023.2 solved it, the same day as the last experiment
(`zipline-archive` 9d859fa, "start of hw demo firmware in Vivado 2023.2"), with a new DMA path that has no subset
converter.  The legacy hw1v5 line carries the 2020.2 workaround for its own build (2425e67).

## Getting an experiment back

```
git log --first-parent origins-archive                                      # the merges
git branch legacy-gpio-only-hwcheck-2020.2             a1be159^2
git branch pacman-1v5-experimental-reorganized-2020_2  1db3c1e^2
git branch working-hw-demo-2020.2                      fac9a5c^2
```
