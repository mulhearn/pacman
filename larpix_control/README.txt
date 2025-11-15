
The larpix_control package supports control of the PACMAN/LArPix hardware.

-----------
To Install:
-----------

From withing the directory containing this README.txt file:
conda env create -f environment.yaml
conda activate larpix
pip install -e .

The -e flag makes edits made to the local files here take immediate
effect.  You'll have to run the conda activate command before each new
session, but the other command are only needed once.

If you want to use flake8 for development, with env activated:
pip install flake8

--------------
To Uninstall:
--------------

If larpix environment is active, deactivate via:
conda deactivate

Then remove the environment:
conda env remove -n larpix

