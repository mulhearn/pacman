

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
