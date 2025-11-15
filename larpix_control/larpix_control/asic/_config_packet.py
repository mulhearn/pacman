# config_helpers.py

from typing import Optional

# return bits [hi:lo] from word.
def _get_bits(word: int, hi: int, lo: int) -> int:
    mask = (1 << (hi - lo + 1)) - 1
    return (word >> lo) & mask

# Set bits [hi:lo] in word to value. Raises if value doesn’t fit.
def _set_bits(word: int, hi: int, lo: int, value: int) -> int:
    width = hi - lo + 1
    if value >= (1 << width):
        raise ValueError(f"value {value} does not fit in {width}-bit field [{hi}:{lo}]")
    mask = ((1 << width) - 1) << lo
    return (word & ~mask) | ((value << lo) & mask)

def validate_config_packet_dict(asic_dict: dict, verbose=False):
    """Validate the ASIC configuration packet defined by the asic_dict.

    Parameters:
        asic_dict (dict): ASIC model dictionary containing 'register_space'.

    Raises:
        ValueError: On any invalid register space configuration.

    Validation includes:
        - config_packet/parameters and config_packet/fields must exist
         - Required parameters are present
         - Parameters associated with present optional fields are present
         - Fields do not overlap
         - Bits are within total_bits
    """
    dict_name = asic_dict.get('name')
    if dict_name is None:
        raise ValueError("ASIC model missing top-level name")
    if verbose:
        print(f"INFO:  Checking config_packet defined by ASIC model dictionary {dict_name}")

    cfg_packet = asic_dict.get("config_packet")
    if cfg_packet is None:
        raise ValueError("ASIC model missing 'config_packet' section")

    # Verify 'parameters' exists
    params = cfg_packet.get('parameters')
    if params is None:
        raise ValueError("ASIC model missing 'config_packet/parameters' section")

    # Check required parameters
    for req in ["total_bits", "type_write", "type_read"]:
        if req not in params:
            raise ValueError(f"Missing required parameter {req} in config_packet/parameters")

    # Verify 'fields' exists
    fields = cfg_packet.get('fields')
    if fields is None:
        raise ValueError("ASIC model missing 'config_packet/fields' section")

    # Check required parameters
    for req in ["chip", "addr", "value"]:
        if req not in fields:
            raise ValueError(f"Missing required constant {req} in config_packet/parameters")

    # Check parameters for optional fields:
    if "magic" in fields:
        if "magic_value" not in params:
            raise ValueError(f"Missing parameter magic_value associated with magic field")
    if "parity" in fields:
        if "parity_value" not in params:
            raise ValueError(f"Missing parameter parity_value associated with parity field")


    # Check for bits out of range and overlapping fields:
    total_bits = params["total_bits"]
    used = [0] * total_bits
    for key, field in fields.items():
        hi, lo = field["bits"]
        if not (0 <= lo <= hi < total_bits):
            raise ValueError(f"Field {key} bits {field['bits']} out of range")
        for i in range(lo, hi + 1):
            if used[i]:
                raise ValueError(f"Field {key} overlaps bit {i}")
            used[i] = 1

    if verbose:
        print(f"INFO:  ASIC dictiorary for {dict_name} contains a valid config_packet defintion.")

# Calculate simple even parity (1 if number of 1s is odd).
def _calc_parity(word: int, total_bits=64) -> int:
    parity = 0
    for i in range(total_bits):
        parity ^= (word >> i) & 1
    return parity

def build_config_packet(
    asic_dict: dict,
    chip: int,
    addr: int,
    value: Optional[int] = None,
    downstream: int = 0,
    write: bool = False,
) -> int:
    """Construct a configuration packet for reading or writing.

    Builds a 64-bit configuration packet (currently) according to the ASIC model
    definition, from the provided fields.

    Parameters:
        asic_dict (dict): Validated ASIC dictionary containing the config_packet definition.
        chip (int): Chip index for the operation.
        addr (int): Register address for the operation.
        value (int | None): Value to write, or for read response, None for read requests
        downstream (int): Direction flag — 1 for toward FPGA, 0 for from FPGA.
        write (bool): True for write operations, False for reads.

    Raises:
        ValueError: If any provided field is too large for the intended bit range,
            or if value is not provided for a write.
    """
    if value is None and write == True:
        raise ValueError("value parameter not provided for a write operation")

    cfg_packet = asic_dict["config_packet"]
    params = cfg_packet["parameters"]

    packet = 0
    packet_type = params["type_write"] if write else params["type_read"]

    fields = cfg_packet["fields"]

    for name, field in fields.items():
        hi, lo = field["bits"]

        if name == "parity":
            # will calculate below
            continue

        value_to_set = None

        if name == "type":
            value_to_set = packet_type
        elif name == "chip":
            value_to_set = chip
        elif name == "addr":
            value_to_set = addr
        elif name == "value" and value is not None:
            value_to_set = value
        elif name == "magic":
            value_to_set = params.get("magic_value", 0)
        elif name == "downstream":
            value_to_set = downstream

        if value_to_set is not None:
            packet = _set_bits(packet, hi, lo, value_to_set)

    # Ensure overall parity matches parity_value parameter:
    parity_value = params.get("parity_value", 0)
    total_parity = _calc_parity(packet)
    if "parity" in fields:
        hi, lo = fields["parity"]["bits"]
        if total_parity != parity_value:
            packet = _set_bits(packet, hi, lo, 1)

    return packet

def build_config_write(asic_dict: dict, chip: int, addr: int, value: int) -> int:
    """Construct a configuration write packet.

    Builds a 64-bit configuration write packet (currently) according to the ASIC model
    definition, from the provided fields.

    Assumes upstream (from FPGA), use build_config_packet if downstream is needed.

    Parameters:
        asic_dict (dict): Validated ASIC dictionary containing the config_packet definition.
        chip (int): Chip index for the operation.
        addr (int): Register address for the operation.
        value (int): Value to write

    Raises:
        ValueError: If any provided field is too large for the intended bit range
    """
    return build_config_packet(asic_dict, chip, addr, value=value, downstream=0,write=True)

def build_config_read(asic_dict: dict, chip: int, addr: int) -> int:
    """Construct a configuration read packet.

    Builds a 64-bit configuration read packet (currently) according to the ASIC model
    definition, from the provided fields.

    Assumes upstream (from FPGA), use build_config_packet if downstream is needed.

    Parameters:
        asic_dict (dict): Validated ASIC dictionary containing the config_packet definition.
        chip (int): Chip index for the operation.
        addr (int): Register address for the operation.

    Raises:
        ValueError: If any provided field is too large for the intended bit range.
    """
    return build_config_packet(asic_dict, chip, addr, value=0, downstream=0,write=False)

def valid_config_packet(asic_dict: dict, packet: int, write: Optional[int]=None, downstream: Optional[int]=None) -> bool:
    """Check if packet is a valid configuration packet."""
    cfg_packet = asic_dict["config_packet"]
    params     = cfg_packet["parameters"]
    fields     = cfg_packet["fields"]

    type_field  = fields["type"]
    type_bits   = _get_bits(packet, *type_field["bits"])
    type_read   = (type_bits == params["type_read"])
    type_write  = (type_bits == params["type_write"])

    # must be read or write:
    if not (type_read or type_write):
        return False
    if write is not None:
        if not write == type_write:
            return False

    if downstream is not None:
        downstream_field  = fields["downstream"]
        downstream_bits   = _get_bits(packet, *downstream_field["bits"])
        if not downstream_bits == downstream:
            return False

    if "magic" in fields:
        magic_value = params.get("magic_value")
        magic_field = fields["magic"]
        if _get_bits(packet, *magic_field["bits"]) != params["magic_value"]:
            return False

    if "parity" in fields:
        total_bits = params.get("total_bits")
        parity_value = params.get("parity_value")
        if _calc_parity(packet, total_bits) != params["parity_value"]:
            return False

    return True

def valid_config_read_response(asic_dict: dict, packet: int) -> bool:
    """Check if packet is a valid configuration read response."""
    return valid_config_packet(asic_dict, packet,downstream=1,write=False)

def parse_chip_address_value(asic_dict: dict, packet: int) -> [int,int,int]:
    """Parse chip, address, and value from a valid config packet"""
    fields       = asic_dict["config_packet"]["fields"];
    chip  = _get_bits(packet, *fields["chip"]["bits"])
    addr  = _get_bits(packet, *fields["addr"]["bits"])
    value = _get_bits(packet, *fields["value"]["bits"])
    return chip, addr, value

def parse_config_packet_fields(asic_dict: dict, packet: int) -> dict:
    """Parse a packet and returns a dictionary of all fields."""
    cfg_packet = asic_dict["config_packet"]
    parsed = {}
    for name,field in cfg_packet["fields"].items():
        hi, lo = field["bits"]
        parsed[name] = _get_bits(packet, hi, lo)
    return parsed

def print_packet_detailed(asic_dict: dict, packet: int) -> None:

    print(f"INFO:  packet:  0x{packet:016X}")

    parsed = parse_config_packet_fields(asic_dict, packet)
    params = asic_dict["config_packet"]["parameters"]

    if (valid_config_packet(asic_dict, packet)):
        print("INFO:  packet is valid.")
    else:
        print("INFO:  packet is *INVALID*.")

    type_bits = int(parsed["type"])
    print(f"INFO:  type:  {type_bits}", end=" ")

    if type_bits == params["type_write"]:
        print("(WRITE)");
    elif type_bits == params["type_read"]:
        print("(READ)");
    else:
        print("(NOT CONFIG)");

    # Upstream/Downstream
    downstream_bits = parsed["downstream"]
    if (downstream_bits == 1):
        print("INFO:  packet is downstream (toward FPGA)")
    elif (downstream_bits == 0):
        print("INFO:  packet is upstream (from FPGA)")
    else:
        print("INFO:  upstream/downstream not specified")

    # Chip, address, value
    chip  = parsed.get("chip", 0)
    addr  = parsed.get("addr", 0)
    value = parsed.get("value", 0)
    print(f"INFO:  chip: {int(chip):<7d} addr: {int(addr):<7d} value: {f'0x{int(value):02x}':<7}")

    if ("magic" in parsed):
        magic_value = params["magic_value"]
        magic = int(parsed.get("magic"))
        print(f"INFO:  magic: 0x{magic:08X} expecting: 0x{magic_value:08X}")

    if ("parity" in parsed):
        parity_value = params["parity_value"]
        overall = _calc_parity(packet, params["total_bits"])
        parity = int(parsed.get("parity"))
        print(f"INFO:  parity bit: {parity:d} overall: {overall:d} expecting: {parity_value:d}")





def format_packet(asic_dict: dict, packet: int) -> str:
    """Return a string representation of a config packet."""
    parsed = parse_config_packet_fields(asic_dict, packet)
    params = asic_dict["config_packet"]["parameters"]

    parts = []

    # Validity
    if valid_config_packet(asic_dict, packet):
        parts.append("(valid)")
    else:
        parts.append("INVALID")

    # Upstream/Downstream
    downstream_bits = parsed["downstream"]
    if (downstream_bits == 1):
        parts.append("downstream")
    elif (downstream_bits == 0):
        parts.append("upstream  ")
    else:
        parts.append("          ")

    # Packet type
    type_bits = parsed.get("type", 0)
    if type_bits == params["type_write"]:
        parts.append("config write")
    elif type_bits == params["type_read"]:
        parts.append("config read ")
    else:
        parts.append(f"type: {int(type_bits):<6d}")

    # Chip, address, value
    chip  = parsed.get("chip", 0)
    addr  = parsed.get("addr", 0)
    value = parsed.get("value", 0)

    parts.append(f"chip: {int(chip):<7d}")
    parts.append(f"addr: {int(addr):<7d}")
    parts.append(f"value: {f'0x{int(value):02x}':<7}")

    # Combine all parts with spaces
    return " ".join(parts)

def print_packet(asic_dict: dict, packet: int) -> None:
    print(format_packet(asic_dict,packet));

