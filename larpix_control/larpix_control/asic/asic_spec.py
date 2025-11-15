import copy
from typing import Optional

# Relative imports (safe for local package development)
import larpix_control.common as common
from . import _registers as _reg
from . import _config_packet as _pkt

class asic_spec:
    """Specifications for a particular ASIC version and related tools.

    Defines the version-dependent specification of an ASIC
    (e.g., LArPix v3), including its register space and configuration
    packet format. Provides tools for mapping fields to registers and
    building or interpreting configuration packets.

    The detailed implementation is largely delegated to
    register_space_helpers and config_packet_helpers. This class
    combines the two, so, for example, a list of fields and their
    updated values can be translated into a list of configuration
    write packets that encode the updates.
    """

    def __init__(self, asic_dict):
        self.asic_dict = asic_dict
        self.field_to_reg = _reg.build_field_to_reg_lut(self.asic_dict)
        self.reg_to_field = _reg.build_reg_to_field_lut(self.field_to_reg)
        self._num_ports = self.asic_dict["register_space"]["parameters"]["num_ports"];
        self._input_directions = self.asic_dict["register_space"]["parameters"]["input_directions"];
        self._output_directions = self.asic_dict["register_space"]["parameters"]["output_directions"];
        self._input_indices = {port: i for i, port in enumerate(self._input_directions)}
        self._output_indices = {port: i for i, port in enumerate(self._output_directions)}

    def name(self):
        return self.asic_dict["name"]

    def num_ports(self):
        return self._num_ports

    def input_index(self, port: str):
        if port in self._input_indices:
            return self._input_indices[port]
        else:
            raise ValueError(f"unknown port name {port}")

    def output_index(self, port: str):
        if port in self._output_indices:
            return self._output_indices[port]
        else:
            raise ValueError(f"unknown port name {port}")

    def input_indices(self, ports: list[str]) -> list[int]:
        """Convert a list of input port names to their numeric indices."""
        return [self.input_index(p) for p in ports]

    def output_indices(self, ports: list[str]) -> list[int]:
        """Convert a list of output port names to their numeric indices."""
        return [self.output_index(p) for p in ports]

    def print_register_map(self):
        """List of registers and the location of the fields therein."""
        _reg.print_map(self.field_to_reg, self.reg_to_field)

    def print_field_reset_values(self):
        """List fields with their reset value"""
        _reg.print_register_field_reset_values(self.asic_dict)

    def build_write_list(self, update=None, as_needed=None):
        """Build a direct register write list from the provided field updates.

        Uses pre-built lookup tables (LUTs) from the provided ASIC model dictionary.
        All registers containing update fields are updated, and fields from as_needed
        are used as needed to fill out remaining fields in updated registers.

        Parameters:
            update: dict {field_name: value}   -- fields requiring an update
            as_needed: dict {field_name: value} -- optional fields

        Returns:
            list of tuples [(reg_index, new_reg_value), ...] sorted by reg_index

        Raises:
            KeyError if an update field is unknown
            ValueError if a register chosen for write lacks value(s) for some fields
            ValueError if a provided value doesn't fit its declared width
        """
        return _reg.build_write_list(self.asic_dict, self.field_to_reg, self.reg_to_field, update=update, as_needed=as_needed)

    def build_read_list(self, refresh=None):
        """Build a list of registers to read in order to refresh the provided fields.

        Uses pre-built lookup tables (LUTs) from the provided ASIC model dictionary.
        All registers containing update fields are updated, and fields from as_needed
        are used as needed to fill out remaining fields in updated registers.

        Parameters:
            field_to_reg: pre-built field-to-register LUT from asic_dict
            update: dict {field_name: value}   -- fields requiring an update

        Returns:
            list of integers indicating the registers to read

        Raises:
            KeyError if an update field is unknown
        """
        return _reg.build_read_list(self.asic_dict, self.field_to_reg, refresh=refresh)

    def build_config_packet(
            self,
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
            chip (int): Chip index for the operation.
            addr (int): Register address for the operation.
            value (int | None): Value to write, or for read response, None for read requests
            downstream (int): Direction flag — 1 for toward FPGA, 0 for from FPGA.
            write (bool): True for write operations, False for reads.

        Raises:
            ValueError: If any provided field is too large for the intended bit range,
            or if value is not provided for a write.
        """
        return _pkt.build_config_packet(self.asic_dict, chip, addr, value, downstream, write)


    def build_config_write(self, chip: int, addr: int, value: int) -> int:
        """Construct a configuration write packet.

        Builds a 64-bit configuration write packet (currently) according to the ASIC model
        definition, from the provided fields.

        Assumes upstream (from FPGA), use build_config_packet if downstream is needed.

        Parameters:
            chip (int): Chip index for the operation.
            addr (int): Register address for the operation.
            value (int): Value to write

        Raises:
            ValueError: If any provided field is too large for the intended bit range
        """
        return _pkt.build_config_write(self.asic_dict, chip, addr, value)

    def build_config_read(self, chip: int, addr: int) -> int:
        """Construct a configuration read packet.

        Builds a 64-bit configuration read packet (currently) according to the ASIC model
        definition, from the provided fields.

        Assumes upstream (from FPGA), use build_config_packet if downstream is needed.

        Parameters:
            chip (int): Chip index for the operation.
            addr (int): Register address for the operation.

        Raises:
            ValueError: If any provided field is too large for the intended bit range.
        """
        return _pkt.build_config_read(self.asic_dict, chip, addr)

    def build_config_write_list(self, chip: int, update=None, as_needed=None) -> list[int]:
        """Build a list of configuration write packets to implement the provided field updates.

        Calls build_write_list and uses the output to
        construct a list of write requests using build_config_write.

        Parameters:
            chip (int): Chip index for the operation.
            update: dict {field_name: value}   -- fields requiring an update
            as_needed: dict {field_name: value} -- optional field

        Returns:
            list[int] : list of config write request packets
        """
        reg_list = self.build_write_list(update=update, as_needed=as_needed)
        return [self.build_config_write(chip, addr, value) for addr, value in reg_list]


    def build_config_read_list(self, chip: int, refresh=None) -> list[int]:
        """Builds a list of configuration read requests to refresh the provided fields.

        Calls build_read_list and uses the output to
        construct a list of read requests using build_config_read.

        Parameters:
            chip (int): Chip index for the operation.
            update: dict {field_name: value}   -- fields requiring an update
        """
        reg_list = self.build_read_list(refresh=refresh)
        return [self.build_config_read(chip, addr) for addr in reg_list]


    def valid_config_packet(self, packet: int,
                            write: Optional[int]=None,
                            downstream: Optional[int]=None) -> bool:
        """Check if packet is a valid configuration packet."""
        return _pkt.valid_config_packet(self.asic_dict, packet, write, downstream)


    def valid_config_read_response(self, packet: int) -> bool:
        """Check if packet is a valid configuration read response."""
        return valid_config_read_response(self.asic_dict, packet)

    def parse_chip_address_value(asic_dict: dict, packet: int) -> [int,int,int]:
        """Parse chip, address, and value from a valid config packet"""
        return parse_chip_address_value(self.asic_dict, packet)

    def parse_config_packet_fields(asic_dict: dict, packet: int) -> dict:
        """Parse a packet and returns a dictionary of all of its fields."""
        return parse_config_packet_fields(self.asic_dict, packet)

    def print_packet_detailed(self, packet: int) -> None:
        """Print a detailed description of the contents of a config packet."""
        return print_packet_detailed(self.asic_dict, packet)

    def format_packet(self, packet: int) -> str :
        """Return a string representation of a config packet."""
        return _pkt.format_packet(self.asic_dict, packet)

    def print_packet(self, packet: int) -> None:
        """Print a single line summary of a config packet."""
        _pkt.print_packet(self.asic_dict, packet)

    def get_asic_dict(self):
        """Get a copy of the ASIC dictionary."""
        return copy.deepcopy(self.asic_dict)

    def get_field_to_reg_lut(self):
        """Get a copy of the field-to-register look-up table."""
        return copy.deepcopy(self.field_to_reg)

    def get_reg_to_field_lut(self):
        """Get a copy of the register-to-field look-up table."""
        return copy.deepcopy(self.reg_to_field)

def asic_spec_from_yaml(path: str):
    """Create an asic_spec instance from a YAML configuration file.

    Reads a YAML file for particular ASIC version, validates the
    register space and configuration packet definitions, and returns
    an asic_spec object encapsulating the version-specific
    specification and related helper methods.

    Parameters:
        path (str): Path to the YAML file describing the ASIC specification.

    Returns:
        asic_spec: An instance representing the ASIC version specified in the YAML.

    Raises:
        yaml.YAMLError: If the YAML file cannot be parsed.
        ValueError: If the register space or configuration packet definitions
                    are invalid.
    """
    asic_dict = common.dict_from_yaml(path)
    _reg.validate_dict(asic_dict)
    _pkt.validate_config_packet_dict(asic_dict)
    return asic_spec(asic_dict)
