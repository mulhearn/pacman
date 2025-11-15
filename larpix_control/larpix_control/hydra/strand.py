# hydra_strand.py

from collections import deque
from copy import deepcopy

import larpix_control.common as common
from . import _impl as _impl
from .node import node as hydra_node

class strand:
    """
    Represents a single Hydra network (strand) attached to one UART.
    Owns the network topology, chip states, and an ASIC specification.
    """
    def __init__(self, raw_hnet: dict, raw_hparams: dict, config: common.asic_config_iface):
        """
        Initialize the Hydra strand.

        Parameters:
            asic: asic_spec instance for this network (all chips share same ASIC version)
            network_raw: raw Hydra network dictionary (YAML-loaded or parsed)
        """
        # keep a reference to the ASIC configuration interface:
        self.config = config

        # deep copy the network and parameters:
        self.raw_hnet = deepcopy(raw_hnet)
        self.raw_hparams = deepcopy(raw_hparams)

        _impl.validate_raw_parameters(self.raw_hparams)
        self.hparams = _impl.parse_raw_parameters(self.raw_hparams)

        _impl.validate_raw_network(self.raw_hnet, self.hparams)
        self.hnet = _impl.parse_raw_network(self.raw_hnet, self.hparams)

        self.root_chip_id = _impl.find_root_chip_id(self.hnet)
        self.fpga_port    = _impl.find_fpga_port(self.hnet)

        # build the node tree from the fixed network:
        self.node_tree = _impl.build_node_tree(self.hnet, self.hparams)

    def print_hydra_table(self):
        _impl.print_hydra_table(self.hnet, self.hparams)

    def print_node_tree(self):
        print(f"root chip id:     {self.root_chip_id}")
        _impl.print_node_tree(self.node_tree)

    def print_hydra_grid(self):
        print(f"root_chip:  {self.root_chip_id}")
        _impl.print_hydra_grid(self.node_tree, self.hparams)
        pass

    def print_network_state(self):
        for chip_id,node in self.node_tree.items():
            if node.io_ready:
                io_ready = "I/O Ready     "
            else:
                io_ready = "I/O Not Ready "
            print(f"chip:  {chip_id}  {io_ready}")

    def init_network(self):
        """
        Initialize the Hydra network strictly from the root outward.
        A node is never initialized until its parent is fully initialized.
        """
        cfg = self.config
        nodes = self.node_tree
        params = self.hparams
        ports = params["ports"]

        # clear io_ready
        _impl.reset_node_tree(nodes)

        root = self.root_chip_id
        queue = deque([root])

        while queue:
            child_id = queue.popleft()
            child_node = nodes[child_id]
            downstream = child_node.parent_port

            # prepare the parent for child configuration:
            parent_node = None;
            if not child_node.parent_id == "fpga":
                parent_node = nodes[child_node.parent_id]

                _impl.assert_parent_child(parent_node, child_node, self.hparams, io_ready=True)

                parent_upstream = _impl.get_io_ready_upstream_ports(parent_node, nodes, next_child_id=child_id)
                cfg.set_upstream_output_enables(parent_node.chip_id, parent_upstream)

            # set chip id (value after reset is 1):
            cfg.set_chip_id(child_id)

            # init I/O for root chip or non-root chip as appropriate:
            if parent_node is None:
                cfg.init_root_chip_io(child_id, downstream)
            else:
                cfg.init_io(child_id)

            # at init we only listen to downstream:
            cfg.set_input_enables(child_id, downstream)

            # at init we send nothing upstream:
            cfg.set_upstream_output_enables(child_id, [])

            # set downstream to parent only:
            cfg.set_downstream_output_enables(child_id, downstream)

            # mark this node as I/O ready (even though upstream is not yet ready.)
            child_node.io_ready = True
            child_node.listen_to_me = True

            # update parent inputs
            if not parent_node is None:
                parent_input = _impl.get_input_ports(parent_node, nodes)
                cfg.set_input_enables(parent_node.chip_id, parent_input)

            # add grand children to the queue
            for id in sorted(child_node.children.keys()):
                queue.append(id)

    def reset(self):
        _impl.reset_node_tree(self.node_tree)
