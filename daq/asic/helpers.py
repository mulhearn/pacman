# helpers.py
import yaml

def asic_dict_from_yaml(path: str):
    """
    Load a YAML ASIC model file and return as a Python dictionary.
    """
    with open(path, "r") as f:
        return yaml.safe_load(f)
