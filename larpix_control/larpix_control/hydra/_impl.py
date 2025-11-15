from collections import deque
from .node import node

from larpix_control.common.helpers import validate_required_keys, validate_required_lists, validate_required_dicts

# validate hydra parameters contained in hydra parameter dictionary.
#  raw: dictionary for validation
#  verbose: print progress if True
# Raises: ValueError, TypeError
def validate_raw_parameters(raw: dict, verbose: bool = False) -> None:

    if verbose:
        print("INFO: validating hydra parameters dictionary.")

    if not isinstance(raw, dict):
        raise ValueError(f"Network must be a dict, got {type(raw).__name__}")

    # top-level key
    required_keys = ["parameters"]
    validate_required_keys(raw, required_keys, dict, "hydra parameters")
    params = raw["parameters"]

    # required parameter keys
    required_keys = ["max_chip_id", "ports", "grid_deltas", "port_mapping"]
    validate_required_keys(params, required_keys, tag="hydra parameters")

    # individual type checks
    if not isinstance(params["max_chip_id"], int):
        raise TypeError("hydra parameters 'max_chip_id' must be an int")

    validate_required_lists(params, ["ports"], str, "hydra parameters")
    validate_required_dicts(params, ["grid_deltas"], str, list, "hydra parameters")
    validate_required_dicts(params, ["port_mapping"], str, str, "hydra parameters")

    ports = params["ports"]
    grid_deltas = params["grid_deltas"]
    port_mapping = params["port_mapping"]

    # grid_deltas values must be [int, int]
    for p, delta in grid_deltas.items():
        if not (isinstance(delta, list) and len(delta) == 2 and all(isinstance(x, int) for x in delta)):
            raise ValueError(
                f"hydra parameters grid_deltas['{p}'] must be a 2-element list of ints, got {delta}"
            )

    # grid_deltas and port_mapping must have same keys as ports
    grid_keys = set(grid_deltas.keys())
    map_keys = set(port_mapping.keys())
    port_set = set(ports)

    if grid_keys != port_set:
        raise ValueError(
            f"hydra parameters grid_deltas keys must match ports. "
            f"Expected {sorted(port_set)}, got {sorted(grid_keys)}"
        )

    if map_keys != port_set:
        raise ValueError(
            f"hydra parameters port_mapping keys must match ports. "
            f"Expected {sorted(port_set)}, got {sorted(map_keys)}"
        )

    # port_mapping values must all come from ports and be unique
    map_values = list(port_mapping.values())
    if any(p not in port_set for p in map_values):
        raise ValueError(
            f"hydra parameters port_mapping values must all be valid ports, got {sorted(set(map_values))}"
        )
    if len(set(map_values)) != len(map_values):
        raise ValueError("hydra parameters port_mapping values contain duplicates")
    if verbose:
        print("INFO: hydra parameters validation passed.")

# validate the network described by hydra network dictionary
#  raw: network dictionary for validation
#  verbose: print progress if True
# Raises: ValueError
def validate_raw_network(raw: dict, params: dict, verbose: bool = False) -> None:

    if not isinstance(raw, dict):
        raise ValueError(f"network must be a dict, got {type(raw).__name__}")
    if verbose:
        print("INFO: network is a dictionary [OK]")

    # Top-level keys
    validate_required_lists(raw, ["chips"], dict, tag="hydra network")
    if verbose:
        print("INFO: chips key is list of dictionaries, as expected. [OK]")

    # Validate chips
    chips = raw["chips"]
    ports = params["ports"]
    max_node = params["max_chip_id"]
    chip_ids = set()
    root_chip_id = None
    root_count = 0

    for chip in chips:
        if not isinstance(chip, dict):
            raise ValueError(f"Each chip must be a dict, got {type(chip).__name__}")
        if "chip_id" not in chip:
            raise ValueError(f"A chip is missing 'chip_id': {chip}")
        cid = chip["chip_id"]
        if cid in chip_ids:
            raise ValueError(f"Duplicate chip_id found: {cid}")
        chip_ids.add(cid)

        # Check connections
        for port, neighbor in chip.items():
            if port == "chip_id":
                continue
            if port not in ports:
                raise ValueError(f"Chip {cid} has invalid port '{port}' (not in parameters.ports)")

            # Neighbor validation
            if neighbor == "fpga":
                root_count += 1
                root_chip_id = cid
            elif neighbor == "unknown" or neighbor is None:
                continue
            elif isinstance(neighbor, int):
                if not (0 <= neighbor <= max_node):
                    raise ValueError(
                        f"Neighbor {neighbor} on chip {cid} port {port} "
                        f"must be between 0 and {max_node}"
                    )
            else:
                raise ValueError(f"Invalid neighbor {neighbor} on chip {cid} port {port}")

    if root_count != 1:
        raise ValueError(f"Exactly one chip must have 'fpga' as neighbor, found {root_count}")

    if verbose:
        print(f"INFO: chips validated: chip_ids = {sorted(chip_ids)} [OK]")
        print(f"INFO: root chip identified: chip_id = {root_chip_id} [OK]")
        print(f"INFO: found {root_count} root chip [OK]")
        print("INFO: raw hydra network validation complete [OK]")


# parse a validated raw dictionary into a params dictionary:
def parse_raw_parameters(raw: dict) -> tuple[dict, dict]:
    return raw["parameters"]


# parse a validated raw dictionary into a hydra network dictionary, using params dictionary:
def parse_raw_network(raw: dict, params: dict) -> dict:
    ports = params.get("ports")

    network_dict = {}
    for chip in raw["chips"]:
        cid = chip["chip_id"]
        connections = {}
        for p in ports:
            if p in chip:
                connections[p] = chip[p]
        network_dict[cid] = connections
    return network_dict


# print the hydra network as a table, from provided hydra network and parameters dictionaries:
def print_hydra_table(parsed: dict, params: dict, width: int = 8):
    ports = params["ports"]

    for cid in sorted(parsed.keys()):
        connections = parsed[cid]
        line = [f"chip:{cid:<3}"]  # chip_id field padded to 3 chars
        for p in ports:
            target = connections.get(p, '-')
            line.append(f"{p}:{target:<{width-2}}")  # width-2 for port + colon
        print(" ".join(line))


# find the root chip ID in the provided hydra network dictionary:
def find_root_chip_id(parsed: dict) -> int:
    for chip_id, neighbors in parsed.items():
        if "fpga" in neighbors.values():
            return chip_id

    # This should never happen if network is validated
    raise RuntimeError("No root chip found in parsed hydra network")

# find the FPGA port name (str) in the provided hydra network dictionary:
def find_fpga_port(parsed: dict) -> str:
    root_chip_id = find_root_chip_id(parsed)
    neighbors = parsed[root_chip_id]
    for port, neighbor in neighbors.items():
        if (neighbor == "fpga"):
            return port

    # This should never happen if network is validated
    raise RuntimeError("No fpga neighbor found in parsed hydra network")

# build a node tree from a parsed hydra network dictionary.
def build_node_tree(parsed: dict, params: dict) -> dict:
    # retrieve hydra network parameters:
    ports = params["ports"]
    port_mapping = params["port_mapping"]
    grid_deltas = params["grid_deltas"]

    # each chip id in the direction is mapped to a node:
    nodes = {chip_id: node(chip_id=chip_id) for chip_id in parsed}

    # setup the root chip:
    root_chip = find_root_chip_id(parsed)
    visited = {root_chip}
    queue = deque([root_chip])
    root_node = nodes[root_chip]
    fpga_port = find_fpga_port(parsed)
    root_node.parent_id = "fpga"
    root_node.parent_port = fpga_port

    root_node.coordinates = (0, 0)

    # build parent/children links using BFS, starting from root chip:
    while queue:
        current_id = queue.popleft()
        current_node = nodes[current_id]
        connections = parsed[current_id]
        x0, y0 = current_node.coordinates

        for port in ports:
            neighbor = connections.get(port)
            if neighbor in ("fpga", "unknown", None) or neighbor in visited:
                continue
            # dictionary verified, so neighbor must be an int
            child_node = nodes[neighbor]
            child_node.parent_id = current_id
            child_node.parent_port = port_mapping[port]
            dx, dy = grid_deltas[port]
            child_node.coordinates = (x0 + dx, y0 + dy)
            current_node.children[neighbor] = port
            visited.add(neighbor)
            queue.append(neighbor)
    return nodes


def print_node_tree(nodes: dict):
    for chip_id,node in nodes.items():
        print(f"chip:  {chip_id}  {node}")


def reset_node_tree(nodes: dict):
    for chip_id,node in nodes.items():
        node.io_ready = False


def print_hydra_grid_no_connections(nodes: dict) -> None:
    if not nodes:
        print("[empty grid]")
        return

    # Extract coordinates
    xs = [n.coordinates[0] for n in nodes.values()]
    ys = [n.coordinates[1] for n in nodes.values()]
    x_min, x_max = min(xs), max(xs)
    y_min, y_max = min(ys), max(ys)

    width = x_max - x_min + 1
    height = y_max - y_min + 1

    # Initialize blank grid
    grid = [["   " for _ in range(width)] for _ in range(height)]

    # Fill grid with chip IDs
    for n in nodes.values():
        x, y = n.coordinates
        gx = x - x_min
        gy = y_max - y  # invert y for top-to-bottom printing
        grid[gy][gx] = f"{n.chip_id:03d}"

    # Print compact grid
    for row in grid:
        print(" ".join(row))

def print_hydra_grid(nodes: dict, params: dict) -> None:
    hpad = 3   # horizontal spacing
    hnode = 3  # node label width
    vpad = 1   # vertical padding

    # Extract coordinates
    xs = [n.coordinates[0] for n in nodes.values()]
    ys = [n.coordinates[1] for n in nodes.values()]
    x_min, x_max = min(xs), max(xs)
    y_min, y_max = min(ys), max(ys)

    grid_width = (x_max - x_min + 1) * (hnode + hpad) - hpad
    grid_height = (y_max - y_min + 1) * (1 + vpad) - vpad

    grid = [[" " for _ in range(grid_width)] for _ in range(grid_height)]

    # Map nodes to grid positions
    node_positions = {}
    for n in nodes.values():
        x, y = n.coordinates
        gx = (x - x_min) * (hnode + hpad)
        gy = (y_max - y) * (1 + vpad)
        node_positions[n.chip_id] = (gx, gy)

        label = f"{n.chip_id:0{hnode}d}"
        for i, c in enumerate(label):
            grid[gy][gx + i] = c

    # Draw connections
    for n in nodes.values():
        gx, gy = node_positions[n.chip_id]
        for child_id, port in n.children.items():
            ngx, ngy = node_positions[child_id]

            if gy == ngy:  # horizontal
                mid_x = min(gx, ngx) + hnode + (abs(ngx - gx) - hnode) // 2
                mid_y = gy
            elif gx == ngx:  # vertical
                mid_x = gx + hnode // 2
                mid_y = min(gy, ngy) + 1 + (abs(ngy - gy) - 1) // 2
            else:  # diagonal
                mid_x = (gx + ngx) // 2
                mid_y = (gy + ngy) // 2

            if 0 <= mid_y < grid_height and 0 <= mid_x < grid_width:
                grid[mid_y][mid_x] = port[0]

    for row in grid:
        print("".join(row))


# Assert that `child_node` is a child of `parent_node` and that
# the ports match according to params['port_mapping'].
def assert_parent_child(parent_node, child_node, params, io_ready = None):
    parent_id = parent_node.chip_id
    child_id = child_node.chip_id
    port_mapping = params["port_mapping"]

    # check that the child references this parent
    assert child_node.parent_id == parent_id, (
        f"child {child_id} parent_id {child_node.parent_id} "
        f"does not match expected parent {parent_id}"
    )

    # check that parent's children mapping points back to the child
    parent_port_to_child = None
    for cid, port in parent_node.children.items():
        if cid == child_id:
            parent_port_to_child = port
            break
    assert parent_port_to_child is not None, (
        f"child {child_id} not found in parent {parent_id} children"
    )

    # check that child's parent_port matches port_mapping[parent_port_to_child]
    expected_parent_port = port_mapping[parent_port_to_child]
    assert child_node.parent_port == expected_parent_port, (
        f"child {child_id} parent_port {child_node.parent_port} "
        f"does not match expected {expected_parent_port} from parent {parent_id} port {parent_port_to_child}"
    )

    if (io_ready is not None):
        assert parent_node.io_ready == io_ready, (
            f"internal error: parent {parent_id} has io_ready {parent_node.io_ready}, expecting {io_ready}"
        )


def get_io_ready_upstream_ports(parent_node, node_tree, next_child_id=None):
    ports = []

    for cid, port in parent_node.children.items():
        child_node = node_tree[cid]
        if child_node.io_ready:
            ports.append(port)
        elif next_child_id is not None and cid == next_child_id:
            ports.append(port)
    return ports

def get_input_ports(parent_node, node_tree):
    ports = []

    # always listen to your parents:
    ports.append(parent_node.parent_port)

    # only listen to children with listen_to_me=True
    for cid, port in parent_node.children.items():
        child_node = node_tree[cid]
        if child_node.listen_to_me:
            ports.append(port)
    return ports
