import pprint

def pretty_print(dict):
    """
    Nicely prints an ASIC model (dictionary returned from YAML loader).
    Handles arrays and nested fields cleanly.
    """
    pp = pprint.PrettyPrinter(indent=2, width=120, compact=True)
    pp.pprint(dict)


def print_register_map(asic_dict):
    """
    Print a human-readable view of the ASIC register layout.
    """
    reg_map = {}
    arr_map = {}

    params = asic_dict.get('parameters', {})
    reg_size = params['reg_size']

    # Build a mapping from register -> list of (name, bit_hi, bit_lo)
    for field in asic_dict['fields']:
        if 'array' in field:
            reg_start = field['register_start']
            n_elements = field['array']
            footprint = field['footprint']

            for idx in range(n_elements):
                reg_idx = reg_start + (footprint * idx) // reg_size
                offset = (footprint * idx) % reg_size
                reg_map.setdefault(reg_idx, [])
                arr_map.setdefault(reg_idx, field['name'])
                bit_hi, bit_lo = field['bits']
                reg_map[reg_idx].append((f"[{idx}]", offset + bit_hi, offset + bit_lo))
        else:
            reg_idx = field['register']
            reg_map.setdefault(reg_idx, [])
            bit_hi, bit_lo = field['bits']
            reg_map[reg_idx].append((field['name'], bit_hi, bit_lo))

    num_registers = asic_dict['parameters']['num_registers']

    # Print registers
    for reg in range(num_registers):
        if reg in reg_map:
            print(f"reg {reg:03}:", end=" ")
            if reg in arr_map:
                print(arr_map[reg], end=" ")
            # MSB fields first
            fields_in_reg = sorted(reg_map[reg], key=lambda f: f[1], reverse=True)
            line = " ".join(f"{name} ({hi}:{lo})" for name, hi, lo in fields_in_reg)
            print(f"{line}")


def print_field_defaults(asic_dict):
    """
    Print all fields with their reset_default and config_default values.
    """
    print(f"{'Field':<30} {'Reset Default':<20} {'Config Default':<20}")
    print("-" * 70)

    for field in asic_dict['fields']:
        name = field['name']
        reset_val = field['reset_default']
        config_val = field['config_default']

        # If the value is a list (array), format nicely
        if isinstance(reset_val, list):
            reset_val_str = "[" + ", ".join(f"{v:#x}" for v in reset_val) + "]"
        else:
            reset_val_str = f"{reset_val:#x}"

        if isinstance(config_val, list):
            config_val_str = "[" + ", ".join(f"{v:#x}" for v in config_val) + "]"
        else:
            config_val_str = f"{config_val:#x}"

        print(f"{name:<30} {reset_val_str:<20} {config_val_str:<20}")


