# asic_register_space.py

class asic_register_space:
    def __init__(self, asic_model):
        """
        Initialize an ASIC register space from a given asic_model.

        :param asic_model: Parsed YAML model describing fields, defaults, etc.
        """
        self.asic_model = asic_model
        self.num_registers = asic_model.parameters['num_registers']
        self.registers = bytearray(self.num_registers)  # 8-bit registers
        self.reset()  # populate with reset_default values

    def reset(self):
        """
        Set all registers to the reset_default value from the asic_model.
        """
        for field in self.asic_model.fields:
            if 'array' in field:
                # array of elements, map sequentially across registers
                array_len = field['array']
                reg_start = field['register_start']
                bits_per_element = field.get('bits_per_element', None)
                reset_value = field['reset_default']
                
                for i in range(array_len):
                    reg_index = reg_start + (i * bits_per_element // 8)  # simplistic mapping
                    bit_offset = (i * bits_per_element) % 8
                    mask = (1 << bits_per_element) - 1
                    # Clear bits in register
                    self.registers[reg_index] &= ~(mask << bit_offset)
                    # Set reset value
                    val = reset_value[i] if isinstance(reset_value, list) else reset_value
                    self.registers[reg_index] |= (val & mask) << bit_offset
            else:
                reg_index = field['register']
                bits = field['bits']
                mask = (1 << (bits if isinstance(bits, int) else bits.split(':')[0])) - 1
                val = field['reset_default']
                self.registers[reg_index] &= ~mask
                self.registers[reg_index] |= val & mask

    def config_default(self):
        """
        Restore each field to its config_default value from the asic_model.
        """
        for field in self.asic_model.fields:
            reg_index = field.get('register', field.get('register_start'))
            val = field['config_default']
            bits = field.get('bits', None)
            mask = (1 << (bits if isinstance(bits, int) else bits.split(':')[0])) - 1
            self.registers[reg_index] &= ~mask
            self.registers[reg_index] |= val & mask

    def print_registers(self):
        """
        Print all registers in a human-readable format.
        """
        print("ASIC Register Space:")
        for i, reg in enumerate(self.registers):
            print(f"R{i:03d}: 0x{reg:02X}", end=' ')
            # Optionally list fields in this register
            for field in self.asic_model.fields:
                reg_index = field.get('register', field.get('register_start'))
                if reg_index == i:
                    print(f"{field['name']}={field['reset_default']}", end=' ')
            print()
