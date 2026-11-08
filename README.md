# PACMAN legacy firmware and software

Development of legacy firmware and software has ended. This branch is a historical record only.

"Legacy" is the PACMAN firmware and software before consistent versioning: the v1.x releases and the snapshots that
followed them, for the hw1v3, hw1v4 and hw1v5 boards (2019 to 2024).  Its successors live elsewhere: hijinks (2.x) on
the branches hijinks-firmware and hijinks-software of this repository, zipline (3.x) in mulhearn/pacman-firmware and
mulhearn/pacman-software.

Every legacy commit is reachable from this branch.  Each line was merged in whole, with its history and original hashes.
The merges change no files, so this branch holds only this README.

## The merges

| Merge | Line (suggested local branch) | Tip | Contents | Tags |
|---|---|---|---|---|
| f3584fe | legacy-hw1v3 | 9fbc1dc | v1.2, v1.2b, v1.3-0.0 .. v1.3-1.0;  893 (Armin, 2024-02) and its build step;  883 (2024-05) | legacy/hw1v3/v1.3-0.0, -0.1, -0.2, -0.3, legacy/hw1v3/v1.3-1.0, legacy/hw1v3/893, legacy/hw1v3/883 |
| df51664 | legacy-hw1v4 | d08d199 | from v1.3-0.3:  v1.4-0.0, v1.4-0.2, resethack 1.8 (894) and its build step | legacy/hw1v4/v1.4-0.0, legacy/hw1v4/v1.4-0.2, legacy/hw1v4/894 |
| c119fd5 | legacy-hw1v5 | 7062e17 | from v1.4-0.0:  the 2024 hw1v5 work, SYNC FIX and its build step, build option rot8 | legacy/hw1v5/syncfix, legacy/hw1v5/rot8 |
| 1169b63 | legacy-firmware-excursions | d5fd1c7 | record merges of superseded build options:  v1.2b 1 MHz, v1.3 1 MHz, v1.3 5 MHz | |
| 4482068 | legacy-software-excursions | 4a27ae1 | record merges of software side lines:  v1.2b-0.1 maintenance, Armin's PetaLinux 2020.2 port, the I2C fix for the MUX | |

The merges, each with a fuller description:

```
git log --first-parent legacy-archive-2026
```

## Getting a line back

Each line is the second parent of its merge (the tags give the same tips for the three hardware lines):

```
git branch legacy-hw1v3               f3584fe^2     # = legacy/hw1v3/883
git branch legacy-hw1v4               df51664^2     # = legacy/hw1v4/894
git branch legacy-hw1v5               c119fd5^2     # = legacy/hw1v5/rot8
git branch legacy-firmware-excursions 1169b63^2
git branch legacy-software-excursions 4482068^2
```

The excursions are `-s ours` merges on 2425e67 (SYNC FIX):  their trees are 2425e67's, and each side line is the
second parent of its record merge.

## Building

Every legacy state of interest to the PACMAN 1v3 and later carries an annotated tag: the toolchain, the build commands,
and the hashes of the build products, with the result of a build from a fresh clone (BITWISE where a released bitstream
exists to compare with).

```
git tag --merged legacy-archive-2026                           # every tag on this branch
git tag -l --format='%(contents)' legacy/<board>/<state>       # one tag's annotation:  how to build it, and the result
git show legacy/<board>/<state>                                # the annotation, then the commit and its diff
git checkout legacy/<board>/<state>                            # the state itself, ready to build
```

The v1.x states build as committed with Vivado 2018.3; 893, 883 and 894 with Vivado 2021.1 through the build steps on
their lines; SYNC FIX and rot8 with Vivado 2020.2.

Not reproduced from this repository:  "74" (the 2x2 PACMAN image) and the 2x2 run1 SD BOOT.BIN (configuration body
60209db9, which matches neither v1.3-0.3 nor v1.3-1.0).
