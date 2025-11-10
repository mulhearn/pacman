# test/test_config_packet_helpers.py
import unittest

from   asic.helpers import dict_from_yaml

from   asic.config_packet_helpers import (
    validate_config_packet_dict,
    build_config_packet,
    build_config_read,
    build_config_write,
    valid_config_packet,
    valid_config_read_response,
    parse_chip_address_value,
    print_packet_detailed,
    print_packet,
)

class test_config_helpers(unittest.TestCase):
    """Tests for config_helpers.py functionality"""

    def setUp(self):
        print("")
        self.asic_dict = dict_from_yaml("config/asics/larpix_v3.yaml")
        validate_config_packet_dict(self.asic_dict)

    def test_aaa_validate(self):
        validate_config_packet_dict(self.asic_dict,verbose=True)
        
    def test_bbb_build_write_packet(self):
        chip = 0x12
        addr = 0x34
        value = 0xAB
        packet = build_config_write(self.asic_dict, chip, addr, value)
        print(f"Write packet:  0x{packet:016X}")
        self.assertTrue(valid_config_packet(self.asic_dict, packet))
        self.assertTrue(valid_config_packet(self.asic_dict, packet, write=True, downstream=0))
        self.assertFalse(valid_config_packet(self.asic_dict, packet, write=False))
        self.assertFalse(valid_config_packet(self.asic_dict, packet, downstream=1))
        ochip,oaddr,ovalue = parse_chip_address_value(self.asic_dict, packet)
        self.assertEqual(ochip,chip)
        self.assertEqual(oaddr,addr)
        self.assertEqual(ovalue,value)
        print_packet_detailed(self.asic_dict, packet)
        print_packet(self.asic_dict, packet)
        
    def test_ccc_build_read_packet(self):
        chip = 0x12
        addr = 0x34
        packet = build_config_read(self.asic_dict, chip, addr)
        print(f"Write packet:  0x{packet:016X}")
        self.assertTrue(valid_config_packet(self.asic_dict, packet))
        self.assertTrue(valid_config_packet(self.asic_dict, packet, write=False, downstream=0))
        self.assertFalse(valid_config_packet(self.asic_dict, packet, write=True))
        self.assertFalse(valid_config_packet(self.asic_dict, packet, downstream=1))
        ochip,oaddr,ovalue = parse_chip_address_value(self.asic_dict, packet)
        self.assertEqual(ochip,chip)
        self.assertEqual(oaddr,addr)
        self.assertEqual(ovalue,0)
        print_packet_detailed(self.asic_dict, packet)
        print_packet(self.asic_dict, packet)
        
    def test_ddd_simulate_read_reponse(self):
        chip  = 0x12
        addr  = 0x34
        value = 0xAB
        packet = build_config_packet(self.asic_dict, chip, addr, value, downstream=1, write=False)
        print(f"Write packet:  0x{packet:016X}")
        self.assertTrue(valid_config_packet(self.asic_dict, packet))
        self.assertTrue(valid_config_read_response(self.asic_dict, packet))
        ochip,oaddr,ovalue = parse_chip_address_value(self.asic_dict, packet)
        self.assertEqual(ochip,chip)
        self.assertEqual(oaddr,addr)
        self.assertEqual(ovalue,value)
        print_packet(self.asic_dict, packet)
        
    def test_ddd_print_packet(self):        
        print_packet_detailed(self.asic_dict, 0x0)
        
if __name__ == "__main__":
    unittest.main()
