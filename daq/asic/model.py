# model.py
import yaml


def yaml_loader(path: str):
    """
    Load a YAML ASIC model file and return as a Python dictionary.
    """
    with open(path, "r") as f:
        return yaml.safe_load(f)


def verify_model(model):
    """
    Sanity check of the asic model:
    - No duplicate field names
    - All required keys and no forbidden keys exist in each field
    - Bit range is properly formatted and ordered
    - Default values fit within declared bit width
    - Footprint covers at least the bit range of the entire field
    - No overlapping field definitions
    Raises ValueError on problems.
    """
    seen_names = set()
    occupied_bits = set()

    params = model.get('parameters', {})
    if 'num_registers' not in params:
        raise ValueError("ASIC model missing 'num_registers' in parameters")
    if 'reg_size' not in params:
        raise ValueError("ASIC model missing 'reg_size' in parameters")

    num_registers = params['num_registers']
    reg_size = params['reg_size']

    for field in model['fields']:
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
    print("ASIC model verification passed.")
