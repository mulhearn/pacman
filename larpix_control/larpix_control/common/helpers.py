# helpers.py
import yaml
from pathlib import Path
from typing import Optional, Union, Any, Dict


def dict_from_yaml(path: Union[str, Path]) -> Dict[str, Any]:
    """
    Load a YAML file and return it as a Python dictionary.

    This is a generic loader; it does not enforce any specific structure.

    Parameters:
        path: path to the YAML file.

    Returns:
        The parsed YAML content as a dictionary.

    Raises:
        FileNotFoundError: if the file does not exist.
        yaml.YAMLError: if the YAML cannot be parsed.
    """
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"YAML file not found: {p}")

    with p.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def validate_required_keys(raw: dict, required: list[str], param_type: Optional[type] = None,
                           tag: str = "(unspecified)") -> None:
    for key in required:
        if key not in raw:
            raise ValueError(f"{tag} dictionary is missing required key: '{key}'")
        if param_type is not None and not isinstance(raw[key], param_type):
            raise TypeError(f"{tag} dictionary '{key}' must be of type {param_type.__name__}, got {type(raw[key]).__name__}")


def validate_required_lists(raw: dict, required: list[str], param_type: Optional[type] = None,
                            tag: str = "(unspecified)") -> None:
    for key in required:
        if key not in raw:
            raise ValueError(f"{tag} dictionary is missing required list '{key}'")
        if not isinstance(raw[key], list):
            raise TypeError(f"{tag} dictionary '{key}' must be a list, got {type(raw[key]).__name__}")
        if param_type is not None and not all(isinstance(x, param_type) for x in raw[key]):
            bad_types = {type(x).__name__ for x in raw[key] if not isinstance(x, param_type)}
            raise TypeError(f"{tag} dictionary '{key}' must be a list of {param_type.__name__}, found non-string types: {bad_types}")


def validate_required_dicts(raw: dict, required: list[str],
                            key_type: Optional[type] = None,
                            value_type: Optional[type] = None,
                            tag: str = "(unspecified)") -> None:
    for key in required:
        if key not in raw:
            raise ValueError(f"{tag} dictionary is missing required dictionary '{key}'")
        if not isinstance(raw[key], dict):
            raise TypeError(f"{tag} dictionary '{key}' must be a dict, got {type(raw[key]).__name__}")
        for k, v in raw[key].items():
            if key_type is not None and not isinstance(k, key_type):
                raise TypeError(f"{tag} dictionary '{key}' has key {k} of {type(k).__name__}, expecting type {key_type.__name__}")
            if value_type is not None and not isinstance(v, value_type):
                raise TypeError(f"{tag} dictionary '{key}' has key {k} with value of {type(v).__name__}, expecting type {value_type.__name__}")
