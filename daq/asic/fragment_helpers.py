

# check that field placeholders are strings, not inadvertent dictionaries:
def _check_field_placeholders(field_dict, context: str):
    for k, v in field_dict.items():
        if isinstance(v, dict):
            # Nested dict detected — likely a mistaken {param} without quotes
            raise ValueError(
                f"{context}: field '{k}' has a dict value {v}, "
                "did you forget quotes around a placeholder?"
            )
        # Error if value contains {param} but is not a string
        if not isinstance(v, str) and "{" in str(v) and "}" in str(v):
            raise ValueError(
                f"{context}: field '{k}' contains braces but is not a string: {v}"
            )

def validate_raw_fragment(fragment: dict, verbose: bool = False) -> None:
    """Validate structure and types of a raw fragment dictionary."""

    # fragment must be a dictionary:
    if not isinstance(fragment, dict):
        raise ValueError(f"Fragment must be a dict, got {type(fragment).__name__}")

    # required keys must exist:
    required_top_keys = ["external", "default"]
    for key in required_top_keys:
        if key not in fragment:
            raise ValueError(f"Missing required top-level key: '{key}'")

    # externals must be a list of strings
    externals = fragment["external"]
    if not isinstance(externals, list) or not all(isinstance(e, str) for e in externals):
        raise ValueError("'external' must be a list of strings")

    # all keys (besides 'external') must be dictionaries
    for k, v in fragment.items():
        if k == "external":
            continue
        if not isinstance(v, dict):
            raise ValueError(f"Version '{k}' must be a dict, got {type(v).__name__}")

    # external placeholders must be in strings (or keys):
    for k, v in fragment.items():
        if k == "external":
            continue
        _check_field_placeholders(v, context=f"version '{k}'")

    if verbose:
        print("INFO: Fragment validation complete [OK]")

def collapse_fragment(raw_fragment: dict, version: str, verbose: bool = False) -> dict:
    """
    Collapse a raw fragment by applying ASIC version-specific overrides.

    Externals (placeholders) remain unresolved.
    """
    from copy import deepcopy

    fields = deepcopy(raw_fragment["default"])
    externals = list(raw_fragment["external"])

    # Apply version overrides if present
    version_overrides = raw_fragment.get(version, {})
    fields.update(version_overrides)

    if verbose:
        print(f"INFO: Collapsed fields for version '{version}': {fields}")
        print(f"INFO: Externals: {externals}")

    return {
        "external": externals,
        "fields": fields
    }

def merge_fragments(fragments: list[dict]) -> dict:
    merged_fields = {}
    merged_externals = set()

    for i, frag in enumerate(fragments):
        if "fields" not in frag or "external" not in frag:
            raise ValueError(f"Fragment at index {i} does not appear collapsed: missing 'fields' or 'external'")
        merged_fields.update(frag["fields"])
        merged_externals.update(frag["external"])

    return {
        "fields": merged_fields,
        "external": list(merged_externals)
    }

def print_collapsed_fragment(collapsed: dict) -> None:
    """
    Print a collapsed fragment dictionary.

    Args:
        collapsed: callapsed dictionary fragment, e.g. from collapse_fragment
    """
    print("Collapsed fragment:")
    print("  Externals:", ", ".join(collapsed.get("external", [])))
    print("  Fields:")
    fields = collapsed.get("fields", {})
    for k, v in sorted(fields.items()):
        print(f"    {k}: {v}")

def evaluate_fragment(collapsed: dict, externals: dict, verbose: bool = False) -> dict:
    """Evaluate a collapsed fragment by substituting external values.

    External values may be lists, which adds additional entries to the
    dictionary as needed, but only on the LHS (the dictionary keys).

    Parameters:
        collapsed: dict from collapse_fragment() with keys "fields" and "external"
        externals: dict mapping external names to single values or lists
        verbose: if True, print progress messages

    Returns:
        A single fully resolved dictionary

    """
    from copy import deepcopy

    fields = deepcopy(collapsed["fields"])
    evaluated = {}

    for ext in collapsed.get("external", []):
        if ext not in externals:
            raise ValueError(f"External '{ext}' missing from externals dict")
        # Normalize single values to list
        vals = externals[ext]
        if not isinstance(vals, list):
            externals[ext] = [vals]
        elif len(vals) == 0:
            raise ValueError(f"External '{ext}' has empty list — not allowed")

    for key, val in fields.items():
        # Determine all key expansions for multi-value externals
        keys_to_add = [key]
        for ext in collapsed.get("external", []):
            new_keys = []
            for k in keys_to_add:
                for v in externals[ext]:
                    new_keys.append(k.replace("{" + ext + "}", str(v)))
            keys_to_add = new_keys

        # Substitute externals in value if string
        if isinstance(val, str):
            for ext in collapsed.get("external", []):
                val_str = str(externals[ext][0])  # always take first for value
                val = val.replace("{" + ext + "}", val_str)

        for k in keys_to_add:
            evaluated[k] = val

        if verbose:
            print(f"INFO: Field '{key}' expanded to {keys_to_add} -> {val}")

    if verbose:
        print(f"INFO: Evaluation complete. Total fields: {len(evaluated)}")

    return evaluated


def print_evaluated_fragment(evaluated: dict) -> None:
    """
    Print an evaluated dictionary fragment.

    Args:
        evaluated: evaluated dictionary fragment, e.g. from evaluate_fragment
    """
    print("Evaluated fragment:")
    max_key_len = max((len(k) for k in evaluated), default=0)
    for k in sorted(evaluated.keys()):
        v = evaluated[k]
        print(f"  {k.ljust(max_key_len)} : {v}")
