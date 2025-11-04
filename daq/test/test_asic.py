import unittest
import asic

class test_model(unittest.TestCase):
    """tests related to asic model structure and verification"""

    def setUp(self):
        print("")
        self.model = asic.model.yaml_loader("config/larpix_v3.yml")

    def test_aaa_verify(self):
        print("")
        asic.model.verify_model(self.model)
        
    def test_bbb_print_register_map(self):
        print("")
        asic.utils.print_register_map(self.model)

    def test_ccc_print_field_defaults(self):
        print("")
        asic.utils.print_field_defaults(self.model)

class test_update(unittest.TestCase):
    """tests related to asic model structure and verification"""

    def test_aaa_update(self):
        print("")
        
        # Create empty update
        u1 = asic.register_update()
        print("Empty update:")
        u1.pretty_print()

        # Create update from list
        updates_list = [[0, 0xA], [1, 0xB], [5, 0xFF]]
        u2 = asic.register_update(updates_list)
        print("\nUpdate from list:")
        u2.pretty_print()

        # Test __repr__
        print("\nrepr(u2):")
        print(repr(u2))

        # Test copy
        u3 = u2.copy()
        print("\nCopied update:")
        u3.pretty_print()

        # Modify original and show copy is unchanged
        u2.updates[0][1] = 0x00
        print("\nAfter modifying original:")
        print("Original:")
        u2.pretty_print()
        print("Copy:")
        u3.pretty_print()
    
        
        
        

if __name__ == "__main__":
    unittest.main()
