# helpers.py
import yaml
from pathlib import Path
from typing import Union, Any, Dict

def dict_from_yaml(path: Union[str, Path]) -> Dict[str, Any]:
    """
    Load a YAML file and return it as a Python dictionary.

    This is a generic loader; it does not enforce ASIC-specific structure.

    Parameters:
        path: Path to the YAML file.

    Returns:
        The parsed YAML content as a Python dictionary.

    Raises:
        FileNotFoundError: if the file does not exist.
        yaml.YAMLError: if the YAML cannot be parsed.
    """
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"YAML file not found: {p!s}")

    with p.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)
