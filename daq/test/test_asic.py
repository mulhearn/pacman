import unittest
import asic

class test_model(unittest.TestCase):
    """tests related to asic model structure and verification"""

    def setUp(self):
        print("")
        self.model = asic.model_from_yaml("config/larpix_v3.yml")

    def test_aaa_test_print(self):
        self.model.print_register_map()
        self.model.print_field_defaults()
        
        
    def test_bbb_direct_update(self):
        print("")
        update = self.model.direct_update(update={"r_term[0]":0x3})
        print(update)
        update = self.model.direct_update(update={"r_term":0x3, "r_term[1]":0x7})
        print(update)
       
        # example: call should raise ValueError
        #with self.assertRaises(ValueError) as cm:
        #    update = asic.direct_update(
        #        self.asic_dict, self.field_to_reg, self.reg_to_field, update={"periodic_trigger_mask[0]":0x1})
        # optional: check exception message
        #self.assertIn("Missing value", str(cm.exception))
        
    def test_ccc_register_space(self):        
        print("");
        rspace = asic.register_space(self.model)
        rspace.print_registers()

if __name__ == "__main__":
    unittest.main()
