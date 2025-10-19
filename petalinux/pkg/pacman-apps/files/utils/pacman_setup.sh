#!/bin/sh

# pacman_setup.sh
#
# initial setup of root account for PACMAN


ROOT_HOME="/home/root"
PYLIB_DIR="$ROOT_HOME/pylib"
BASH_LINE='export PYTHONPATH=/home/root/pylib:$PYTHONPATH'

# ensure pylib exists
mkdir -p "$PYLIB_DIR"

# append pylib to .bashrc if not already present
touch "$ROOT_HOME/.bashrc"
grep -qxF "$BASH_LINE" "$ROOT_HOME/.bashrc" || echo "$BASH_LINE" >> "$ROOT_HOME/.bashrc"
