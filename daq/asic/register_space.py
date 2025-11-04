# register_space.py

class register_space:
    """
    Memory-efficient representation of an ASIC register space.
    Wraps around a model instance, using LUTs for fast access.
    """
    
    def __init__(self, asic_model):
        """
        Initialize register space.

        Args:
            asic_model: instance of model class
        """
        self.model = asic_model
        self.num_registers = self.model.asic_dict['parameters']['num_registers']
        self.reg_size = self.model.asic_dict['parameters']['reg_size']
        self.registers = bytearray(self.num_registers)  # store registers as bytes
        self.field_to_reg = self.model.field_to_reg  # reuse LUT
        self.reg_to_field = self.model.reg_to_field  # reuse LUT

        # initialize to reset defaults
        self.reset()

    def reset(self):
        """Set registers to reset_default values from the model."""
        # zero out registers
        for i in range(self.num_registers):
            self.registers[i] = 0

        # apply reset defaults
        for field in self.model.asic_dict['fields']:
            if 'array' in field:
                # array elements
                n_elements = field['array']
                reset_default = field['reset_default']
                for idx in range(n_elements):
                    fn = f"{field['name']}[{idx}]"
                    if isinstance(reset_default, int):
                        self._write_field(fn, reset_default)
                    else:
                        self._write_field(fn, reset_default[idx])
            else:
                fn = field['name']
                self._write_field(fn, field['reset_default'])

    def _write_field(self, field_name, value):
        """Write a value to a single field, using LUT."""
        if field_name not in self.field_to_reg:
            raise KeyError(f"Unknown field: {field_name}")
        reg, width, offset, mask = self.field_to_reg[field_name]
        if value >= (1 << width):
            raise ValueError(f"Value {value} too large for field {field_name} ({width} bits)")
        # clear field bits
        self.registers[reg] &= ~mask
        # set new value
        self.registers[reg] |= (value << offset) & mask

    def read_field(self, field_name):
        """Return the current value of a field."""
        if field_name not in self.field_to_reg:
            raise KeyError(f"Unknown field: {field_name}")
        reg, width, offset, mask = self.field_to_reg[field_name]
        return (self.registers[reg] & mask) >> offset

    def direct_update(self, update=None, as_needed=None):
        """
        Update multiple fields at once using the model's direct_update function.
        """
        reg_updates = self.model.direct_update(update=update, as_needed=as_needed)
        for reg, val in reg_updates:
            self.registers[reg] = val

    def print_registers(self):
        """Print all registers with associated field values."""
        print("Register Space:")
        for i, val in enumerate(self.registers):
            print(f"R{i:03d}: 0x{val:02X}", end=' ')
            if i in self.reg_to_field:
                for fn in self.reg_to_field[i]:
                    fv = self.read_field(fn)
                    print(f"{fn}={fv}", end=' ')
            print()
