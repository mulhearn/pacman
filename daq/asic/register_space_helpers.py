

def validate_register_space_dict(asic_dict: dict, verbose: bool = False) -> None:
    """Validate the ASIC register space defined by asic_dict.

    Parameters:
        asic_dict (dict): ASIC model dictionary containing 'register_space'.

    Raises:
        ValueError: On any invalid register space configuration.

    Validation includes:
    - register_space/parameters and register_space/fields exist.
    - Required parameters (e.g., num_registers, reg_size) are present.
    - No duplicate field names.
    - All required keys exist for each field; no forbidden keys.
    - Bit ranges are properly formatted and ordered; each field occupies at least one register.
    - Default values fit within the declared bit width.
    - Footprint covers at least the full bit range of the field.
    - Fields spanning multiple registers have a footprint that is a multiple of reg_size.
    - No overlapping field definitions.
    """

    seen_names = set()
    occupied_bits = set()

    dict_name = asic_dict.get('name')
    if dict_name is None:
        raise ValueError("ASIC model missing top-level name")    
    if verbose:
        print(f"INFO:  Checking dictionary for ASIC model {dict_name}")
        
    version = asic_dict.get('version')
    if version is None:
        raise ValueError("ASIC model missing top-level version")    

    description = asic_dict.get('description')
    if description is None:
        raise ValueError("ASIC model missing top-level description")    

    if verbose:
        print(f"INFO:  Version: {version}")
        print(f"INFO:  Description: {description}")
        
    reg_space = asic_dict.get('register_space')
    if reg_space is None:
        raise ValueError("ASIC model missing 'register_space' section")
    
    # verify 'parameters' exists
    params = reg_space.get('parameters')
    if params is None:
        raise ValueError("ASIC model missing 'register_space/parameters' section")

    # verify required parameter keys
    if 'num_registers' not in params:
        raise ValueError("ASIC model missing 'num_registers' in register_space/parameters")
    if 'reg_size' not in params:
        raise ValueError("ASIC model missing 'reg_size' in register_space/parameters")

    # verify 'fields' exists (but it can be an empty list)
    fields = reg_space.get('fields')
    if fields is None:
        raise ValueError("ASIC model missing 'register_space/fields' section")
    if not isinstance(fields, list):
        raise ValueError("register_space/fields must be a list (can be empty)")

    if verbose:
        print("INFO:  register_space, parameters (including required parameters), and fields exist")
        
    num_registers = params['num_registers']
    reg_size = params['reg_size']

    for field in fields:
        if verbose:
            print(f"INFO:  Checking field: {field.get('name', '<unnamed>')}")

        name = field.get('name')
        if not name:
            raise ValueError(f"Field missing 'name': {field}")
        if name in seen_names:
            raise ValueError(f"Duplicate field name found: {name}")
        seen_names.add(name)

        # Check required keys
        is_array = 'array' in field
        if is_array:
            required_keys = ['bits', 'access', 'reset_value', 'register_start', 'footprint']
            forbidden_keys = ['register']
            for key in required_keys:
                if key not in field:
                    raise ValueError(f"Field array {name} missing required key '{key}'")
            for key in forbidden_keys:
                if key in field:
                    raise ValueError(f"Field array {name} should not have '{key}'")
        else:
            required_keys = ['bits', 'access', 'reset_value', 'register']
            forbidden_keys = ['register_start', 'footprint']
            for key in required_keys:
                if key not in field:
                    raise ValueError(f"Field {name} missing required key '{key}'")
            for key in forbidden_keys:
                if key in field:
                    raise ValueError(f"Field {name} should not have '{key}'")

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
        
        # Check reset values fit bit width
        width = abs(bits[0] - bits[1]) + 1
        max_val = (1 << width) - 1
        for key in ['reset_value']:
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
    if verbose:
        print(f"INFO:  ASIC dictionary for {dict_name} contains a valid register_space definition.")

def build_field_to_reg_lut(asic_dict: dict) -> dict[str, tuple[int, int, int, int]]:
    """Construct a look-up table (LUT) that maps logical fields to a position in the register space

    Parameters:
        asic_dict (dict): ASIC model dictionary containing 'register_space'.

    Returns:
        A dictionary that contains the LUT:  field_name -> (reg, width, offset, mask)
    """
    lut = {}
    reg_size = asic_dict['register_space']['parameters']['reg_size']

    for field in asic_dict['register_space']['fields']:
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

def print_field_to_reg_lut(field_to_reg: dict[str, tuple[int, int, int, int]]) -> None:
    """Print contents of the register field to register space location look-up table"""
    print("\nField-to-Register LUT:")
    print("-" * 60)
    print(f"{'Field':30} {'Reg':>6} {'Width':>6} {'Offset':>8}   {'Mask':<10}")
    print("-" * 60)

    for name, (reg, width, offset, mask) in field_to_reg.items():
        print(f"{name:30} {reg:6d} {width:6d} {offset:8d}   0x{mask:02x}")

    print("-" * 60)
    print(f"Total fields: {len(field_to_reg)}\n")

def build_reg_to_field_lut(field_to_reg: dict[str, tuple[int, int, int, int]]
                           ) -> dict[int, list[str]]:
    """Invert a field-to-register look up table (LUT) to constuct a register-to-field LUT.

    Parameters:
        field_to_reg (dict): the field-to-register LUT from build_field_to_reg_lut

    Returns:
        A dictionary that contains the LUT:  reg -> [field_name1, field_name2, ...]
    """
    lut = {}
    for field_name, (reg, width, offset, mask) in field_to_reg.items():
        if reg not in lut:
            lut[reg] = []
        lut[reg].append(field_name)
    return lut


def print_reg_to_field_lut(reg_to_field: dict[int, list[str]]) -> None:
    """Print contents of the register-to-field look-up table, with one field per line
    and register number printed once per group."""
    print("\nRegister-to-Field LUT:")
    print("-" * 40)
    print(f"{'Reg':>6}  Field")
    print("-" * 40)

    total_fields = 0
    for reg, field_list in reg_to_field.items():
        first = True
        for field_name in field_list:
            if first:
                print(f"{reg:6d}  {field_name}")
                first = False
            else:
                print(f"{'':6}  {field_name}")
            total_fields += 1

    print("-" * 40)
    print(f"Total registers: {len(reg_to_field)}")
    print(f"Total fields:    {total_fields}\n")

def print_register_map(field_to_reg: dict[str, tuple[int, int, int, int]],
                       reg_to_field: dict[int, list[str]]) -> None:
    """Print the complete register map, combining field-to-reg and reg-to-field LUTs.
    Each register is listed with its constituent fields, including bit range and width.
    """
    print("\nRegister Map:")
    print("-" * 60)
    print(f"{'Reg':>6}  {'Field':30} {'Bits':>10} {'Width':>6}")
    print("-" * 60)

    total_fields = 0
    for reg, field_list in reg_to_field.items():
        first = True
        for field_name in field_list:
            reg_num, width, offset, mask = field_to_reg[field_name]
            bits = f"[{offset + width - 1}:{offset}]"
            if first:
                print(f"{reg:6d}  {field_name:30} {bits:>10} {width:6d}")
                first = False
            else:
                print(f"{'':6}  {field_name:30} {bits:>10} {width:6d}")
            total_fields += 1

    print("-" * 60)
    print(f"Total registers: {len(reg_to_field)}")
    print(f"Total fields:    {total_fields}\n")
    

def normalize_field_dict(asic_dict: dict, field_dict: dict) -> dict[str, int]:
    """Normalize a field dictionary by expanding array defaults and then applying specific overrides.

    Parameters:
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
    for field in asic_dict['register_space']['fields']:
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


def direct_update(asic_dict: dict, field_to_reg: dict, reg_to_fields: dict ,
                  update: dict =None, as_needed: dict =None, verbose: bool = False
                  ) -> list[tuple[int, int]]:
    """Build a direct register write list from the provided field updates.

    Uses pre-built lookup tables (LUTs) from the provided ASIC model dictionary.
    All registers containing update fields are updated, and fields from as_needed
    are used as needed to fill out remaining fields in updated registers.

    Parameters:
        asic_dict: verified ASIC model dictionary 
        field_to_reg: pre-built field-to-register LUT from asic_dict
        reg_to_fields: pre-built register-to-field LUT from asic_dict
        update: dict {field_name: value}   -- fields requiring an update
        as_needed: dict {field_name: value} -- optional fields

    Returns:
        list of tuples [(reg_index, new_reg_value), ...] sorted by reg_index

    Raises:
        KeyError if an update field is unknown
        ValueError if a register chosen for write lacks value(s) for some fields
        ValueError if a provided value doesn't fit its declared width
    """
    
    if update is None:
        update = {}
    if as_needed is None:
        as_needed = {}

    if verbose:
        print(f"INFO: direct_update called with update={list(update.keys())} as_needed={list(as_needed.keys())}")
        

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

    if verbose:
        print(f"INFO: Registers to write: {sorted(regs_to_write)}")
        
    # Determine which fields are needed to fill the updated registers,
    # and make sure they are in merged dictionary.

    # Check that all fields in each required register have a value in merged
    for reg in regs_to_write:
        for field_name in reg_to_fields[reg]:
            if field_name not in merged_norm:
                raise ValueError(f"Missing value for field '{field_name}' in register {reg}")

    reg_size = asic_dict['register_space']['parameters']['reg_size']
            
    # Build the final register values
    reg_writes: list[tuple[int, int]] = []

    for reg in sorted(regs_to_write):
        reg_value = 0
        for field_name in reg_to_fields[reg]:
            value = merged_norm[field_name]
            _, width, offset,mask = field_to_reg[field_name]
            if value >= (1 << width):
                raise ValueError(f"Value {value} too large for field '{field_name}' ({width} bits)")
            reg_value |= (value & ((1 << width) - 1)) << offset        
        if verbose:
            print(f"INFO: Final register value: 0x{reg_value:0{reg_size//4}X}")            
        reg_writes.append((reg, reg_value))

    
    if verbose:
        print(f"INFO: direct_update generated {len(reg_writes)} register writes")

    return reg_writes


def print_register_field_reset_values(asic_dict):
    """
    Print each fields with its reset_value.
    """
    print(f"{'Field':<30} {'Reset Default':<20}")
    print("-" * 50)

    for field in asic_dict['register_space']['fields']:
        name = field['name']
        reset_val = field['reset_value']

        # If the value is a list (array), format nicely
        if isinstance(reset_val, list):
            reset_val_str = "[" + ", ".join(f"{v:#x}" for v in reset_val) + "]"
        else:
            reset_val_str = f"{reset_val:#x}"

        print(f"{name:<30} {reset_val_str:<20}")
