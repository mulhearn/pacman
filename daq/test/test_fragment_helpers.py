# test/test_fragment_helpers.py
import unittest

from   asic.helpers import dict_from_yaml

from   asic.fragment_helpers import (
    validate_raw_fragment,
    collapse_fragment,
    print_collapsed_fragment,
    evaluate_fragment,
    print_evaluated_fragment,
    merge_fragments,
)

class test_fragment_helpers(unittest.TestCase):
    """Tests for fragment_helpers.py functionality"""

    def setUp(self):
        print("")
        self.raw_fragment = dict_from_yaml("config/fragments/demo_eg.yml")
        validate_raw_fragment(self.raw_fragment)
        self.collapsed = collapse_fragment(self.raw_fragment, version="larpix_v3")

    def test_aaa_validate(self):
        validate_raw_fragment(self.raw_fragment, verbose=True)

    def test_bbb_collapse(self):
        collapsed = collapse_fragment(self.raw_fragment, version="larpix_v3", verbose=True)
        print_collapsed_fragment(collapsed)

    def test_ccc_evaluate(self):
        externals = {
            "up": ["1", "3"],
            "dn": ["0"],
            "chip_id": 5
        }
        evaluated = evaluate_fragment(self.collapsed, externals, verbose=True)
        print_evaluated_fragment(evaluated)

    def test_ddd_mege(self):
        # bad example (chip id needs to be alone!) but fine for test:
        fa = dict_from_yaml("config/fragments/init_chip_id.yml")
        fb = dict_from_yaml("config/fragments/init_io.yml")
        validate_raw_fragment(fa, verbose=True)
        validate_raw_fragment(fb, verbose=True)
        ca = collapse_fragment(fa, version="larpix_v3", verbose=True)
        cb = collapse_fragment(fb, version="larpix_v3", verbose=True)
        fm = merge_fragments([ca, cb])
        print_collapsed_fragment(fm)


if __name__ == "__main__":
    unittest.main()
