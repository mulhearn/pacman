import copy


from .helpers import asic_dict_from_yaml

from .register_space_helpers import (
    validate_register_space_dict,
    build_field_to_reg_lut,
    print_field_to_reg_lut,
    build_reg_to_field_lut,
    print_reg_to_field_lut,
    print_register_map,
    print_register_field_reset_values,
)

class model:
    """
    Wrapper around an ASIC dictionary that caches lookup tables
    and provides utility methods.
    """

    def __init__(self, asic_dict):
        """
        Args:
            asic_dict: validated ASIC dictionary
        """
        self.asic_dict = asic_dict
        self.field_to_reg = build_field_to_reg_lut(self.asic_dict)
        self.reg_to_field = build_reg_to_field_lut(self.field_to_reg)

    def print_register_map(self):
        print_register_map(self.file_to_reg, self.reg_to_field)

    def print_field_defaults(self):
        print_register_field_reset_values(self.asic_dict)

    def direct_update(self, update=None, as_needed=None):
        return direct_update(self.asic_dict, self.field_to_reg, self.reg_to_field, update=update, as_needed=as_needed)
    
    def get_asic_dict(self):
        return copy.deepcopy(self.asic_dict)

    def get_field_to_reg_lut(self):
        return copy.deepcopy(self.field_to_reg)

    def get_reg_to_field_lut(self):
        return copy.deepcopy(self.reg_to_field)  

    
def model_from_yaml(path : str):
    """
    create an ASIC model from a YAML file.
    """
    asic_dict = asic_dict_from_yaml(path)
    validate_register_space_dict(asic_dict)
    return model(asic_dict)

