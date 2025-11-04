import pprint


def pretty_print(model):
    """
    Nicely prints an ASIC model (dictionary returned from YAML loader).
    Handles arrays and nested fields cleanly.
    """
    pp = pprint.PrettyPrinter(indent=2, width=120, compact=True)
    pp.pprint(model)


def print_register_map(model):
    """
    Print a human-readable view of the ASIC register layout.
    """
    reg_map = {}
    arr_map = {}

    params = model.get('parameters', {})
    reg_size = params['reg_size']

    # Build a mapping from register -> list of (name, bit_hi, bit_lo)
    for field in model['fields']:
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

    num_registers = model['parameters']['num_registers']

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


def print_field_defaults(model):
    """
    Print all fields with their reset_default and config_default values.
    """
    print(f"{'Field':<30} {'Reset Default':<20} {'Config Default':<20}")
    print("-" * 70)

    for field in model['fields']:
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


def direct_update(model, as_needed=None, **field_values):
    """
    Compute register updates for ASIC fields.
        model: verified ASIC model.
        field_values: dict of field_name -> value
        as_needed: list of field names that are only needed if the register is being updated.
    Returns:
        asic_register_update
    """
    if as_needed is None:
        as_needed = []

    # Map fields -> registers and store field info
    reg_map = {}  # reg_index -> list of field dicts
    field_map = {}  # field_name -> field dict

    for f in model['fields']:
        name = f['name']
        field_map[name] = f
        reg_index = f.get('register') or f.get('register_start')
        reg_map.setdefault(reg_index, []).append(f)

    updates = []

    for reg_index, fields_in_reg in reg_map.items():
        # Determine if this register has any required fields
        reg_required = False
        for f in fields_in_reg:
            fname = f['name']
            if fname in field_values and fname not in as_needed:
                reg_required = True
                break

        if not reg_required:
            continue  # skip this register entirely

        # Build register value from all fields
        reg_val = 0
        for f in fields_in_reg:
            fname = f['name']
            bit_hi, bit_lo = f['bits']
            width = bit_hi - bit_lo + 1

            # Decide which value to use
            if fname in field_values:
                val = field_values[fname]
            elif fname in as_needed:
                val = field_values.get(fname)
                if val is None:
                    raise ValueError(f"Field {fname} in reg {reg_index} is as_needed but missing a value")
            else:
                raise ValueError(f"Required field {fname} in reg {reg_index} missing value")

            # If array, take first element (for simplicity, could expand later)
            if isinstance(val, list):
                val = val[0]

            # Mask to width
            val &= (1 << width) - 1

            # Shift into position
            reg_val |= val << bit_lo

        updates.append((reg_index, reg_val))

    return updates
