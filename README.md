# PACMAN zipline:  the working histories

Zipline (3.x) development has moved to the repositories pacman-firmware and pacman-software.  This branch is a
historical record only.

The streamlined zipline history, one commit per change, is the branch `zipline-archive`, with the releases tagged
`3v1` to `3v4` and `3v4-fixup1`.  Each release was made from a working branch, whose fuller history ends with exactly
the release's files.  This branch keeps those working histories and ties each to its release:  each merge has three
parents, the previous merge, the release on `zipline-archive`, and the release's working tip, and all of them hold the
same files.  The last merge brings in the 3.5 work done here before the move, which has no release in this
repository.

| Merge | Release | Working tip | Working branch |
|---|---|---|---|
| 992d99f | `3v2` (ec0190d) | 46bf1ef (tag `working-3v2`) | |
| cf3d033 | `3v3` (7d8ecc3) | 31d4e51 | working-on-3v3-hw-demo-2023.2 |
| a97ec64 | `3v4` (45cefec) | d3c8cd3 | working-on-3v4-hw-demo-2023.2 |
| 3862366 | `3v4-fixup1` (be44ad1) | 537b1e9 | working-driver-fixup-3v4 |
| e8a1530 | none (3.5 moved) | 3215e82 | working-on-zipline-3v5 |

```
git log --first-parent zipline-working-archive              # the merges
git branch working-3v3 cf3d033^3                                 # a working history back as a branch
git branch working-3v5 e8a1530^2                                 # the 3.5 work (the last merge has two parents)
```

Below this README, the branch holds the files of the 3.5 working tip (3215e82).
