# test/test_fragment_helpers.py
import unittest

import larpix_control.common as common
import larpix_control.asic._fragment as _frag

from   larpix_control import fragment_lib_from_yaml

class test_asic_fragment(unittest.TestCase):
    """Tests for fragment_helpers.py functionality"""

    def setUp(self):
        print("")
        self.raw_fragment = common.dict_from_yaml("config/fragments/demo_eg.yaml")
        _frag.validate_raw_fragment(self.raw_fragment)
        self.collapsed = _frag.collapse_fragment(self.raw_fragment, version="larpix_v3")

    def test_aaa_validate(self):
        _frag.validate_raw_fragment(self.raw_fragment, verbose=True)

    def test_bbb_collapse(self):
        collapsed = _frag.collapse_fragment(self.raw_fragment, version="larpix_v3", verbose=True)
        _frag.print_collapsed(collapsed)

    def test_ccc_evaluate(self):
        externals = {
            "up": ["1", "3"],
            "dn": ["0"],
            "chip_id": 5
        }
        evaluated = _frag.evaluate_collapsed(self.collapsed, externals, verbose=True)
        _frag.print_evaluated(evaluated)

    def test_ddd_merge(self):
        fa = common.dict_from_yaml("config/fragments/init_rx.yaml")
        fb = common.dict_from_yaml("config/fragments/init_rx_root_chip.yaml")
        _frag.validate_raw_fragment(fa, verbose=True)
        _frag.validate_raw_fragment(fb, verbose=True)
        ca = _frag.collapse_fragment(fa, version="larpix_v3", verbose=True)
        cb = _frag.collapse_fragment(fb, version="larpix_v3", verbose=True)
        fm = _frag.merge_fragments([ca, cb])
        _frag.print_collapsed(fm)

    def test_eee_library(self):
        frag_lib = fragment_lib_from_yaml("config/fragments/library.yaml", "larpix_v3")
        print(frag_lib)

if __name__ == "__main__":
    unittest.main()
