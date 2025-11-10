from collections import deque

def validate_raw_hydra(raw: dict, verbose: bool = False, max_node: int = 254) -> None:
    """
    Validate the structure and contents of a raw Hydra network dictionary.

    Rules:
        - Top-level keys: 'parameters' and 'chips'
        - Each chip must have a unique 'chip_id'
        - Ports must be in parameters['ports']
        - Neighbor values must be one of:
            - 'fpga' (marks root chip)
            - 'unknown'
            - None
            - integer 0..max_node
        - Exactly one chip must have 'fpga' as neighbor (the root chip)

    Args:
        raw: dictionary loaded from YAML representing the network
        verbose: if True, print progress messages
        max_node: maximum allowed integer for chip neighbor (default 254)

    Raises:
        ValueError: if the network is invalid
    """
    # Top-level keys
    required_keys = ["parameters", "chips"]
    if not isinstance(raw, dict):
        raise ValueError(f"Network must be a dict, got {type(raw).__name__}")
    if verbose:
        print("INFO: Network is a dictionary [OK]")

    for key in required_keys:
        if key not in raw:
            raise ValueError(f"Network missing required top-level key: '{key}'")
    if verbose:
        print(f"INFO: Top-level keys present: {', '.join(required_keys)} [OK]")


    # Validate parameters
    params = raw["parameters"]
    if not isinstance(params, dict):
        raise ValueError("'parameters' must be a dict")

    # Ports
    ports = params.get("ports", [])
    if not isinstance(ports, list) or not all(isinstance(p, str) for p in ports):
        raise ValueError("'parameters.ports' must be a list of strings")

    # Directions
    directions = params.get("directions", [])
    if not isinstance(directions, list):
        raise ValueError("'parameters.directions' must be a list")
    if len(directions) != len(ports):
        raise ValueError(
            f"Length of 'directions' ({len(directions)}) must match number of ports ({len(ports)})"
        )
    for d in directions:
        if not (isinstance(d, (list, tuple)) and len(d) == 2 and all(isinstance(x, (int, float)) for x in d)):
            raise ValueError(f"Each direction must be a 2-tuple of numbers, got {d}")

    if verbose:
        print(f"INFO: Parameters validated: ports = {ports}, directions = {directions} [OK]")

    # Validate chips
    chips = raw["chips"]
    if not isinstance(chips, list):
        raise ValueError("'chips' must be a list of chip definitions")

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
            if port not in ports and neighbor != "fpga":
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
        print(f"INFO: Chips validated: chip_ids = {sorted(chip_ids)} [OK]")
        print(f"INFO: Root chip identified: chip_id = {root_chip_id} [OK]")
        print(f"INFO: Root neighbor check passed [found {root_count}]")
        print("INFO: Raw Hydra network validation complete [OK]")

def parse_raw_hydra(raw: dict) -> tuple[dict, dict]:
    """
    Parse a validated raw Hydra network dictionary into a normalized Python representation.

    Args:
        raw: dictionary of the raw Hydra network (assumed validated by validate_raw_hydra)

    Returns:
        parameters: dict of top-level network parameters (e.g., ports)
        network_dict: dict keyed by chip_id, each value a dict of port -> neighbor
    """
    parameters = raw["parameters"]
    ports = parameters.get("ports", [])

    network_dict = {}
    for chip in raw["chips"]:
        cid = chip["chip_id"]
        connections = {}
        for p in ports:
            if p in chip:
                connections[p] = chip[p]
        network_dict[cid] = connections

    return parameters, network_dict

def print_hydra_table(network_dict: dict, ports: list[str] = None, width: int = 8):
    """
    Print a compact ASCII map of the Hydra network, one line per chip, with aligned columns.

    Args:
        network_dict: dict keyed by chip_id, values are dict of port->neighbor
        ports: optional list of valid ports (defaults to ['n','e','s','w'])
        width: fixed width for each port field
    """
    if ports is None:
        ports = ['n', 'e', 's', 'w']

    for cid in sorted(network_dict.keys()):
        connections = network_dict[cid]
        line = [f"chip:{cid:<3}"]  # chip_id field padded to 3 chars
        for p in ports:
            target = connections.get(p, '-')
            line.append(f"{p}:{target:<{width-2}}")  # width-2 for port + colon
        print(" ".join(line))

def find_root_chip(parsed_hydra: dict) -> int:
    """
    Find the root chip in a parsed Hydra network.

    Assumes the network has been validated: exactly one chip has a neighbor 'fpga'.

    Args:
        parsed_hydra: dict mapping chip_id -> {port: neighbor, ...}

    Returns:
        chip_id of the root chip
    """
    for chip_id, neighbors in parsed_hydra.items():
        if "fpga" in neighbors.values():
            return chip_id

    # This should never happen if network is validated
    raise RuntimeError("No root chip found in parsed Hydra network")

from collections import deque

def find_path_to_chip(parsed_hydra: dict, target_chip: int, start_chip: int = None) -> list[int]:
    """Find a path from the start chip to the target chip.

    Uses BFS to find the shortest path in terms of hops. Traversal
    ignores neighbors marked as 'fpga' or 'unknown'.  If start_chip is
    not specified (default), uses root chip as starting point.

    Parameters:
        parsed_hydra: dict mapping chip_id -> {port: neighbor, ...}
        target_chip: chip_id of the destination
        start_chip: chip_id of the start chip

    Returns:
        List of chip_ids forming the path from root_chip to target_chip,
        inclusive.

    Raises:
        ValueError: if no path exists

    """
    if (start_chip is None):
        start_chip = find_root_chip(parsed_hydra)
    
    visited = set()
    queue = deque([(start_chip, [start_chip])])
    visited.add(start_chip)

    while queue:
        current_chip, path = queue.popleft()
        if current_chip == target_chip:
            return path

        neighbors = parsed_hydra.get(current_chip, {}).values()
        for neighbor in neighbors:
            if neighbor in visited:
                continue
            if neighbor in ("fpga", "unknown", None):
                continue
            visited.add(neighbor)
            queue.append((neighbor, path + [neighbor]))

    return None

def chip_path_to_port_path(parsed_hydra: dict, chip_path: list[int]) -> list[str]:
    """
    Convert a list of chip IDs into a list of port names along the path.

    Args:
        parsed_hydra: dict mapping chip_id -> {port: neighbor, ...}
        chip_path: list of chip_ids from start to target (inclusive)

    Returns:
        List of port names corresponding to each hop in the path
    """
    port_path = []

    for from_chip, to_chip in zip(chip_path, chip_path[1:]):
        neighbors = parsed_hydra.get(from_chip, {})
        for port, neighbor in neighbors.items():
            if neighbor == to_chip:
                port_path.append(port)
                break
        else:
            raise ValueError(f"No port found from chip {from_chip} to {to_chip}")

    return port_path


def assign_coordinates(parsed_hydra: dict, ports: list[str],
                       directions: list[list[int]], root_chip: int = None) -> dict[int, tuple[int,int]]:
    """
    Assign (x, y) coordinates to each chip in the network.

    Args:
        parsed_hydra: dict mapping chip_id -> {port: neighbor, ...}
        ports: list of port names
        directions: list of [dx, dy] offsets corresponding to ports
        root_chip: chip_id to start from (optional, defaults to root)

    Returns:
        Dict mapping chip_id -> (x, y) coordinates
    """
    if root_chip is None:
        root_chip = find_root_chip(parsed_hydra)

    port_delta = {port: tuple(directions[i]) for i, port in enumerate(ports)}
    coords = {root_chip: (0, 0)}
    visited = set([root_chip])
    queue = deque([root_chip])

    while queue:
        current = queue.popleft()
        x0, y0 = coords[current]

        for port, neighbor in parsed_hydra.get(current, {}).items():
            if neighbor in ("fpga", "unknown", None):
                continue
            if neighbor in visited:
                continue
            if port not in port_delta:
                raise ValueError(f"Port {port} not in ports list")

            dx, dy = port_delta[port]
            coords[neighbor] = (x0 + dx, y0 + dy)
            visited.add(neighbor)
            queue.append(neighbor)

    return coords


def print_hydra_grid(coords: dict[int, tuple[int, int]]) -> None:
    """Print a compact ASCII grid of chip coordinates.

    Each chip is shown by its 3-digit ID (e.g. 011). No connection
    lines are drawn yet.

    Args:
        coords: dict mapping chip_id -> (x, y) coordinates
    """
    if not coords:
        print("[empty grid]")
        return

    # Determine grid bounds
    xs = [x for (_, (x, _)) in coords.items()]
    ys = [y for (_, (_, y)) in coords.items()]
    x_min, x_max = min(xs), max(xs)
    y_min, y_max = min(ys), max(ys)

    width = x_max - x_min + 1
    height = y_max - y_min + 1

    # Initialize blank grid
    grid = [["   " for _ in range(width)] for _ in range(height)]

    # Fill grid with chip IDs
    for cid, (x, y) in coords.items():
        gx = x - x_min
        gy = y_max - y  # invert y so top prints first
        grid[gy][gx] = f"{cid:03d}"

    # Print compact grid (single-space separation)
    for row in grid:
        print(" ".join(row))


def print_hydra_grid_connected(parsed_hydra: dict, params: dict) -> None:
    """
    Print a Hydra network as a 2D ASCII grid with nodes and centered single-character connections.
    """
    # Hard-coded layout parameters
    hpad = 3      # spaces between columns
    hnode = 3     # width of each node label, zero-padded
    vpad = 1      # vertical lines between rows
    
    ports = params["ports"]
    directions = params["directions"]
    port_to_delta = {p: tuple(d) for p, d in zip(ports, directions)}

    # Find root chip
    root_chip = next((cid for cid, p_dict in parsed_hydra.items()
                      if "fpga" in p_dict.values()), None)
    if root_chip is None:
        raise ValueError("No root chip found")

    # Assign coordinates
    coords = {root_chip: (0, 0)}
    queue = deque([root_chip])
    while queue:
        chip = queue.popleft()
        x, y = coords[chip]
        for port, neighbor in parsed_hydra[chip].items():
            if neighbor in ("fpga", "unknown", None):
                continue
            if neighbor not in coords:
                dx, dy = port_to_delta[port]
                coords[neighbor] = (x + dx, y + dy)
                queue.append(neighbor)

    # Determine grid bounds
    xs, ys = zip(*coords.values())
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)

    grid_width = (max_x - min_x + 1) * (hnode + hpad) - hpad
    grid_height = (max_y - min_y + 1) * (1 + vpad) - vpad

    # Initialize empty grid
    grid = [[" " for _ in range(grid_width)] for _ in range(grid_height)]

    # Place nodes
    node_positions = {}
    for chip, (x, y) in coords.items():
        gx = (x - min_x) * (hnode + hpad)
        gy = (max_y - y) * (1 + vpad)
        node_positions[chip] = (gx, gy)
        label = f"{chip:0{hnode}d}"  # zero-padded
        for i, c in enumerate(label):
            grid[gy][gx + i] = c

    # Place connections (overwrite a single character in the gap between nodes)
    for chip, neighbors in parsed_hydra.items():
        gx, gy = node_positions[chip]
        for port, neighbor in neighbors.items():
            if neighbor in ("fpga", "unknown", None):
                continue
            ngx, ngy = node_positions[neighbor]

            # Horizontal connection
            if gy == ngy and gx != ngx:
                mid_x = min(gx, ngx) + hnode + (abs(ngx - gx) - hnode) // 2
                mid_y = gy

            # Vertical connection
            elif gx == ngx and gy != ngy:
                mid_x = gx + hnode // 2  # center the N/S port
                mid_y = min(gy, ngy) + 1 + (abs(ngy - gy) - 1) // 2

            else:
                # Diagonal: pick midpoint
                mid_x = (gx + ngx) // 2
                mid_y = (gy + ngy) // 2

            # Overwrite the midpoint with port character
            if 0 <= mid_y < grid_height and 0 <= mid_x < grid_width:
                grid[mid_y][mid_x] = port[0]

    # Print the grid
    for row in grid:
        print("".join(row))
