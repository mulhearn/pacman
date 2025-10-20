#!/bin/sh

# pacman_setup.sh
#
# initial setup of root account for PACMAN

ROOT_HOME="/home/root"
PYLIB_DIR="$ROOT_HOME/pylib"
PATH_LINE='export PYTHONPATH=/home/root/pylib:$PYTHONPATH'

# ensure pylib exists
mkdir -p "$PYLIB_DIR"

# append pylib to .bashrc if not already present
touch "$ROOT_HOME/.profile"
grep -qxF "$PATH_LINE" "$ROOT_HOME/.profile" || echo "$PATH_LINE" >> "$ROOT_HOME/.profile"
