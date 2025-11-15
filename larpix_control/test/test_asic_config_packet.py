# test/test_config_packet_helpers.py
import unittest

import larpix_control.common as common
import larpix_control.asic._config_packet as _pkt

class test_asic_config_packet(unittest.TestCase):
    """Tests for config_helpers.py functionality"""

    def setUp(self):
        print("")
        self.asic_dict = common.dict_from_yaml("config/asics/larpix_v3.yaml")
        _pkt.validate_config_packet_dict(self.asic_dict)

    def test_aaa_validate(self):
        _pkt.validate_config_packet_dict(self.asic_dict,verbose=True)

    def test_bbb_build_write_packet(self):
        chip = 0x12
        addr = 0x34
        value = 0xAB
        packet = _pkt.build_config_write(self.asic_dict, chip, addr, value)
        print(f"Write packet:  0x{packet:016X}")
        self.assertTrue(_pkt.valid_config_packet(self.asic_dict, packet))
        self.assertTrue(_pkt.valid_config_packet(self.asic_dict, packet, write=True, downstream=0))
        self.assertFalse(_pkt.valid_config_packet(self.asic_dict, packet, write=False))
        self.assertFalse(_pkt.valid_config_packet(self.asic_dict, packet, downstream=1))
        ochip,oaddr,ovalue = _pkt.parse_chip_address_value(self.asic_dict, packet)
        self.assertEqual(ochip,chip)
        self.assertEqual(oaddr,addr)
        self.assertEqual(ovalue,value)
        _pkt.print_packet_detailed(self.asic_dict, packet)
        _pkt.print_packet(self.asic_dict, packet)

    def test_ccc_build_read_packet(self):
        chip = 0x12
        addr = 0x34
        packet = _pkt.build_config_read(self.asic_dict, chip, addr)
        print(f"Write packet:  0x{packet:016X}")
        self.assertTrue(_pkt.valid_config_packet(self.asic_dict, packet))
        self.assertTrue(_pkt.valid_config_packet(self.asic_dict, packet, write=False, downstream=0))
        self.assertFalse(_pkt.valid_config_packet(self.asic_dict, packet, write=True))
        self.assertFalse(_pkt.valid_config_packet(self.asic_dict, packet, downstream=1))
        ochip,oaddr,ovalue = _pkt.parse_chip_address_value(self.asic_dict, packet)
        self.assertEqual(ochip,chip)
        self.assertEqual(oaddr,addr)
        self.assertEqual(ovalue,0)
        _pkt.print_packet_detailed(self.asic_dict, packet)
        _pkt.print_packet(self.asic_dict, packet)

    def test_ddd_simulate_read_reponse(self):
        chip  = 0x12
        addr  = 0x34
        value = 0xAB
        packet = _pkt.build_config_packet(self.asic_dict, chip, addr, value, downstream=1, write=False)
        print(f"Write packet:  0x{packet:016X}")
        self.assertTrue(_pkt.valid_config_packet(self.asic_dict, packet))
        self.assertTrue(_pkt.valid_config_read_response(self.asic_dict, packet))
        ochip,oaddr,ovalue = _pkt.parse_chip_address_value(self.asic_dict, packet)
        self.assertEqual(ochip,chip)
        self.assertEqual(oaddr,addr)
        self.assertEqual(ovalue,value)
        _pkt.print_packet(self.asic_dict, packet)

    def test_ddd_print_packet(self):
        _pkt.print_packet_detailed(self.asic_dict, 0x0)

if __name__ == "__main__":
    unittest.main()
