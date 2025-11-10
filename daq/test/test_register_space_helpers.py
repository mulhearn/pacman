import unittest

from   asic.helpers import dict_from_yaml

from   asic.register_space_helpers import (
    validate_register_space_dict,
    build_field_to_reg_lut,
    print_field_to_reg_lut,
    build_reg_to_field_lut,
    print_reg_to_field_lut,
    print_register_map,
    print_register_field_reset_values,
    build_register_write_list,
    build_register_read_list,
)

verbose = False

class test_register_space_helpers(unittest.TestCase):
    """test the register_space helper functions"""

    def setUp(self):
        print("")
        self.asic_dict = dict_from_yaml("config/asics/larpix_v3.yaml")
        validate_register_space_dict(self.asic_dict)
        
    def test_aaa_validate(self):
        validate_register_space_dict(self.asic_dict, verbose=verbose)

    def test_bbb_print_register_field_reset_values(self):
        if (verbose):
            print_register_field_reset_values(self.asic_dict)
        
    def test_ccc_luts(self):
        ftr = build_field_to_reg_lut(self.asic_dict)
        if (verbose):
            print_field_to_reg_lut(ftr)
        rtf = build_reg_to_field_lut(ftr)
        if (verbose):
            print_reg_to_field_lut(rtf)
        print_register_map(ftr, rtf)

    def test_ddd_build_register_write_list(self):        
        ftr = build_field_to_reg_lut(self.asic_dict)
        rtf = build_reg_to_field_lut(ftr)

        update = build_register_write_list(self.asic_dict, ftr, rtf, update={"r_term[0]":0x3}, verbose=verbose)
        print(update)
        update = build_register_write_list(self.asic_dict, ftr, rtf, update={"r_term":0x3, "r_term[1]":0x7}, verbose=verbose)
        print(update)

    def test_eee_build_register_read_list(self):        
        ftr = build_field_to_reg_lut(self.asic_dict)
        rtf = build_reg_to_field_lut(ftr)

        update = build_register_read_list(self.asic_dict, ftr, refresh=["r_term[0]"], verbose=verbose)
        print(update)
        update = build_register_read_list(self.asic_dict, ftr, refresh=["r_term"], verbose=verbose)
        print(update)

        
if __name__ == "__main__":
    unittest.main()
