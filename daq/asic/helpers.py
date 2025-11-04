# helpers.py
import yaml

def asic_dict_from_yaml(path: str):
    """
    Load a YAML ASIC model file and return as a Python dictionary.
    """
    with open(path, "r") as f:
        return yaml.safe_load(f)


def asic_dict_verify(asic_dict):
    """
    Sanity check of the ASIC model defined by asic_dict:
    - No duplicate field names
    - All required keys and no forbidden keys exist in each field
    - Bit range is properly formatted and ordered, and one register per field
    - Default values fit within declared bit width
    - Footprint covers at least the bit range of the entire field
    - No overlapping field definitions
    Raises ValueError on problems.
    """
    seen_names = set()
    occupied_bits = set()

    params = asic_dict.get('parameters', {})
    if 'num_registers' not in params:
        raise ValueError("ASIC model missing 'num_registers' in parameters")
    if 'reg_size' not in params:
        raise ValueError("ASIC model missing 'reg_size' in parameters")

    num_registers = params['num_registers']
    reg_size = params['reg_size']

    for field in asic_dict['fields']:
        name = field.get('name')
        if not name:
            raise ValueError(f"Field missing 'name': {field}")
        if name in seen_names:
            raise ValueError(f"Duplicate field name found: {name}")
        seen_names.add(name)

        # Check required keys

        is_array = 'array' in field
        if is_array:
            required_keys = ['bits', 'access', 'reset_default', 'config_default', 'register_start', 'footprint']
            forbidden_keys = ['register']
            for key in required_keys:
                if key not in field:
                    raise ValueError(f"Field array {name} missing required key '{key}'")
            for key in forbidden_keys:
                if key in field:
                    raise ValueError(f"Field array {name} should not have '{key}'")
        else:
            required_keys = ['bits', 'access', 'reset_default', 'config_default', 'register']
            forbidden_keys = ['register_start', 'footprint']
            for key in required_keys:
                if key not in field:
                    raise ValueError(f"Field array {name} missing required key '{key}'")
            for key in forbidden_keys:
                if key in field:
                    raise ValueError(f"Field array {name} should not have '{key}'")

        # Check bit order sanity
        bits = field['bits']
        if not isinstance(bits, list) or len(bits) != 2:
            raise ValueError(f"Field {name} 'bits' must be [msb, lsb]")
        if bits[0] < bits[1]:
            raise ValueError(f"Field {name} bits reversed: {bits}")
        if bits[0] >= reg_size:
            raise ValueError(
                f"Field {name} msb {bits[0]} exceeds register size {reg_size}"
            )
        
        # Check default values fit bit width
        width = abs(bits[0] - bits[1]) + 1
        max_val = (1 << width) - 1
        for key in ['reset_default', 'config_default']:
            val = field[key]

            # Handle list defaults (e.g. arrays)
            if isinstance(val, list):
                for idx, v in enumerate(val):
                    if v > max_val:
                        raise ValueError(
                            f"{key}[{idx}] for {name} = {v:#x} exceeds width {width} (max {max_val:#x})"
                        )
            else:
                if val > max_val:
                    raise ValueError(
                        f"{key} for {name} = {val:#x} exceeds width {width} (max {max_val:#x})"
                    )

        # Footprint checks for arrays only:  bit range coverage and factor of reg_size
        if is_array:
            bit_hi, bit_lo = field['bits']
            footprint = field['footprint']
            n_elements = field['array']
            if footprint < (bit_hi + 1):
                raise ValueError(
                    f"Field {name} footprint ({footprint}) too small for bit range {bit_hi}:{bit_lo}"
                )
            if (n_elements * footprint > reg_size):
                if (reg_size % footprint != 0):
                    raise ValueError(
                        f"Field {name} footprint ({footprint}) is not a factor of {reg_size}"
                    )

        # check for overlapping fields
        if is_array:
            reg_start = field['register_start']
            n_elements = field['array']
            footprint = field['footprint']

            for idx in range(n_elements):
                for b in range(reg_size * reg_start + idx * footprint, reg_size * reg_start + (idx + 1) * footprint):
                    if b not in occupied_bits:
                        occupied_bits.add(b)
                    else:
                        raise ValueError(f"Field {name} (array element {idx}) fields at bit index {b}")
        else:
            reg_start = field['register']
            bit_hi, bit_lo = field['bits']
            for b in range(reg_size * reg_start + bit_lo, reg_size * reg_start + bit_hi + 1):
                if b not in occupied_bits:
                    occupied_bits.add(b)
                else:
                    raise ValueError(f"Field {name} overlaps another field at bit index {b}")

        # Verify that all bits lie within num_registers * reg_size
        total_bits = num_registers * reg_size
        for b in occupied_bits:
            if b >= total_bits:
                raise ValueError(
                    f"Field bit index {b} exceeds ASIC register space "
                    f"({num_registers} registers of {reg_size} bits)"
                )
    print("ASIC dictionary verification passed.")


def build_field_to_reg_lut(asic_dict):
    """
    Build field -> (reg, width, offset, mask) LUT
    There is only one register per field, as verified for the model.
    """
    lut = {}
    reg_size = asic_dict['parameters']['reg_size']

    for field in asic_dict['fields']:
        name = field['name']
        bits = field['bits']
        width = bits[0] - bits[1] + 1
        if 'array' in field:
            n_elements = field['array']
            reg_start = field['register_start']
            footprint = field['footprint']
            for idx in range(n_elements):
                start_bit = reg_size * reg_start + idx * footprint
                reg = start_bit // reg_size
                offset = start_bit % reg_size
                mask = ((1 << width) - 1) << offset
                lut[f"{name}[{idx}]"] = (reg, width, offset, mask)
        else:
            reg = field['register']
            offset = bits[1]
            mask = ((1 << width) - 1) << offset
            lut[name] = (reg, width, offset, mask)
    return lut


def build_reg_to_field_lut(field_to_reg):
    """
    Invert field_to_reg_lut to produce reg -> list of fields.
    Each register maps to all field elements that occupy any part of it.
    """
    lut = {}
    for field_name, (reg, width, offset, mask) in field_to_reg.items():
        if reg not in lut:
            lut[reg] = []
        lut[reg].append(field_name)
    return lut

def normalize_field_dict(asic_dict, field_dict):
    """
    Expand array defaults and apply specific overrides.

    Args:
        field_dict: dict of field_name -> value
                    e.g. {"a": 0, "a[1]": 1, "b": 5}
        asic_dict: verified ASIC dictionary

    Returns:
        normalized dict: all array elements explicitly keyed, e.g.
        {"a[0]": 0, "a[1]": 1, "b": 5}
    """
    normalized = {}

    # Build array info from asic_dict
    array_sizes = {}
    for field in asic_dict['fields']:
        name = field['name']
        if 'array' in field:
            array_sizes[name] = field['array']

    # First pass: expand array defaults per element
    for fn, val in field_dict.items():
        if fn in array_sizes:
            n = array_sizes[fn]
            for idx in range(n):
                key = f"{fn}[{idx}]"
                normalized[key] = val

    # Second pass: apply explicit assignments, overriding pass one as needed:
    for fn, val in field_dict.items():
        if fn not in array_sizes:
            normalized[fn] = val

    return normalized


def direct_update(asic_dict, field_to_reg, reg_to_fields, update=None, as_needed=None):
    """
    Build a direct register write list from field updates.

    Args:
        asic_dict: verified ASIC dict (used to read num_registers/reg_size if needed).
        field_to_reg: dict mapping field_element_name -> (reg_index, width, offset)
                      e.g. "r_term[0]" -> (247, 3, 0)
        reg_to_fields: dict mapping reg_index -> list of field_element_names that
                       occupy any bits of that register
        update: dict {field_name: value}   -- required/explicit fields
        as_needed: dict {field_name: value} -- optional fields; used only if their
                   register is being written to satisfy other required fields.

    Returns:
        list of tuples [(reg_index, new_reg_value), ...] sorted by reg_index

    Raises:
        KeyError if a referenced field is unknown
        ValueError if a register chosen for write lacks value(s) for some fields
        ValueError if a provided value doesn't fit its declared width
    """
    if update is None:
        update = {}
    if as_needed is None:
        as_needed = {}

    # Defensive type checks
    if not isinstance(update, dict):
        raise TypeError("update must be a dict field_name->value")
    if not isinstance(as_needed, dict):
        raise TypeError("as_needed must be a dict field_name->value")

    update_norm  = normalize_field_dict(asic_dict, update)

    # merge but keep update values taking precedence over as_needed
    merged_norm  = normalize_field_dict(asic_dict, as_needed)
    merged_norm.update(update_norm)  # update overrides as_needed where keys overlap

    # quick validations: every key in merged must exist in field_to_reg
    for fn in merged_norm.keys():
        if fn not in field_to_reg:
            raise KeyError(f"Unknown field provided: {fn}")

    # Determine which registers must be written: those that contain any required field
    regs_to_write = set()
    for fn in update_norm.keys():
        if fn not in field_to_reg:
            raise KeyError(f"Unknown field in update: {fn}")
        reg = field_to_reg[fn][0]
        regs_to_write.add(reg)

    # Determine which fields are needed to fill the updated registers,
    # and make sure they are in merged dictionary.

    # Check that all fields in each required register have a value in merged
    for reg in regs_to_write:
        for field_name in reg_to_fields[reg]:
            if field_name not in merged_norm:
                raise ValueError(f"Missing value for field '{field_name}' in register {reg}")
    
    # Build the final register values
    reg_writes = []
    for reg in sorted(regs_to_write):
        reg_value = 0
        for field_name in reg_to_fields[reg]:
            value = merged_norm[field_name]
            _, width, offset,mask = field_to_reg[field_name]
            if value >= (1 << width):
                raise ValueError(f"Value {value} too large for field '{field_name}' ({width} bits)")
            reg_value |= (value & ((1 << width) - 1)) << offset
        reg_writes.append((reg, reg_value))        
    return reg_writes
    
    return None;
