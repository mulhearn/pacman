# Hijinks firmware and software

Hijinks (2.x) is the PACMAN firmware and server for the hw1v5 test stands, from October 2024.  Its sources are on two
branches of this repository:  `hijinks-firmware` (this branch, Vivado 2020.2) and `hijinks-software` (the server,
PetaLinux 2018.3).  Both are linear, and neither is force-pushed or deleted.  Every firmware and server release below
is tagged and reproduced bitwise from the repository.  Each tag's annotation gives the build recipe and the result:

```
git tag -l 'hijinks/*'
git tag -l --format='%(contents)' hijinks/hw1v5/fw-2.8
```

## Bundles

| Bundle | Kind | Firmware | Server | BOOT.BIN | rootfs.tar.gz |
|---|---|---|---|---|---|
| UCD 1v5_20241005B_ucd_devhiijinks | dev | SYNC FIX (`legacy/hw1v5/syncfix`) | `hijinks/hw1v5/server-2v1` | (05A's) | |
| UCD 1v5_20241005C_ucd_devhiijinks | dev | `hijinks/hw1v5/fw-2.1` | `hijinks/hw1v5/server-2v1` | d671e163 | eee5e155 |
| UCD 1v5_20241007A_ucd_devhijinks | dev | `hijinks/hw1v5/fw-2.1` | `hijinks/hw1v5/server-2v2` | | ba9c4dbe |
| UCD 1v5_20241007B_ucd_hiijinks | released (first) | `hijinks/hw1v5/fw-2.2` | `hijinks/hw1v5/server-2v2` | 9aec3817 | ba9c4dbe |
| LBNL 1v5_20241010A_hijinks | released (first deployed) | `hijinks/hw1v5/fw-2.2` | `hijinks/hw1v5/server-2v4` | 9aec3817 | 82591272 |
| LBNL 1v5_20241026A_hiijinks | released | `hijinks/hw1v5/fw-2.8` | `hijinks/hw1v5/server-2v4` | b40ecf46 | 82591272 |
| pacman-server/2v5 | software only | (2.8) | `hijinks/hw1v5/server-2v5` | | |
| pacman-server/2v7 | software only | (2.8) | `hijinks/hw1v5/server-2v7` | | |
| LBNL 1v5_20241029A_hijinks | experimental, not released | `hijinks/hw1v5/fw-2.9` | | 6febb607 | |
| LBNL 1v5_20261020A_hijinks | released | `hijinks/hw1v5/fw-2.10` | `hijinks/hw1v5/server-2v7` | 74bd786d | |

Hashes are the first 8 hex digits of the sha256.  Firmware 2.7 (`hijinks/hw1v5/fw-2.7`) shipped in no bundle:  it is
the ancestor of 2.8.  Firmware 2.3 to 2.6 and server 2.3 were test increments, never released (there is no server 2.6).  image.ub is
b64633c2 in every bundle.

## Notes

- The BOOT.BINs were assembled outside the repository.  `packaging/` and `products/zsys_wrapper.hdf` on
  `hijinks-software` hold the SYNC FIX bitstream throughout, unused by the firmware releases.
- The server lives in the rootfs (`usr/bin/pacman_cmdserver`, `pacman_dataserver`).  Each rootfs carries exactly
  the binaries of a released server tarball.
- The 2.10 utilities (`hijinks_snapshot.sh`, `pacman_timing.py`) are one-off and unsupported, kept only here.
- The released directory names keep the "hiijinks" spelling.
