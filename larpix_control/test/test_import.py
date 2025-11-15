# test_import.py

try:
    import larpix_control
    from larpix_control.common.helpers import dict_from_yaml
    print("Import successful!")
except ImportError as e:
    print("Import failed:", e)
