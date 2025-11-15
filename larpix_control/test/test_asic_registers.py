import unittest

import larpix_control.common as common
import larpix_control.asic._registers as _reg

verbose = False

class test_register_space_helpers(unittest.TestCase):
    """test the register_space helper functions"""

    def setUp(self):
        print("")
        self.asic_dict = common.dict_from_yaml("config/asics/larpix_v3.yaml")
        _reg.validate_dict(self.asic_dict)
        self.ftr = _reg.build_field_to_reg_lut(self.asic_dict)
        self.rtf = _reg.build_reg_to_field_lut(self.ftr)

    def test_aaa_validate(self):
        _reg.validate_dict(self.asic_dict, verbose=verbose)

    def test_bbb_print_register_field_reset_values(self):
        if (verbose):
            _reg.print_field_reset_values(self.asic_dict)

    def test_ccc_luts(self):
        ftr = _reg.build_field_to_reg_lut(self.asic_dict)
        if (verbose):
            _reg.print_field_to_reg_lut(ftr)
        rtf = _reg.build_reg_to_field_lut(ftr)
        if (verbose):
            _reg.print_reg_to_field_lut(rtf)
            _reg.print_map(ftr, rtf)

    def test_ddd_build_register_write_list(self):
        update = _reg.build_write_list(self.asic_dict, self.ftr, self.rtf, update={"r_term[0]":0x3}, verbose=verbose)
        print(update)
        update = _reg.build_write_list(self.asic_dict, self.ftr, self.rtf, update={"r_term":0x3, "r_term[1]":0x7}, verbose=verbose)
        print(update)

    def test_eee_build_register_read_list(self):
        update = _reg.build_read_list(self.asic_dict, self.ftr, refresh=["r_term[0]"], verbose=verbose)
        print(update)
        update = _reg.build_read_list(self.asic_dict, self.ftr, refresh=["r_term"], verbose=verbose)
        print(update)

if __name__ == "__main__":
    unittest.main()
