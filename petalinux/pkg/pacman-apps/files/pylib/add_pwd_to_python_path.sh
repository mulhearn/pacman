# add_pwd_to_python_path.sh
#!/bin/bash
# Adds the current working directory to PYTHONPATH
# (This is for special testing only)

export PYTHONPATH="$PWD:$PYTHONPATH"
echo "PYTHONPATH is now: $PYTHONPATH"
