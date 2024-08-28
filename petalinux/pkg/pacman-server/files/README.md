PACMAN servers
==============

PACMAN runs two servers (a command server and a data server) that transfer data to and from the
base hardware and larpix chips. The command server handles configuration of both the PACMAN and
the larpix chips. The data server provides a continuous data stream of data from the larpix chips
and PACMAN fpga.

These servers should start automatically on boot, but if they do not, you can launch the
servers with::

   pacman_server start

To stop the servers::

   pacman_server stop

To restart the servers::

   pacman_server restart


Stand-alone operation
=====================

The ``pacman_util.py`` script allows the full functionality of the system to be operated from
the command line within the PACMAN::

    pacman_util.py --help

