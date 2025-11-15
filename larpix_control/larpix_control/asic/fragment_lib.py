import yaml
from pathlib import Path
from . import _fragment as _frag

def fragment_lib_from_yaml(library_yaml_path: str, version: str, verbose=False):
    """Load and collapse all fragments defined in a fragment library YAML."""
    with open(library_yaml_path, 'r') as f:
        library_yaml = yaml.safe_load(f)

    collapsed_fragments = {}

    for entry in library_yaml.get("library", []):
        name = entry["name"]
        path = Path(entry["path"])
        if not path.exists():
            raise FileNotFoundError(f"Fragment file not found: {path}")

        with open(path, 'r') as frag_file:
            raw_fragment = yaml.safe_load(frag_file)

        _frag.validate_raw_fragment(raw_fragment, verbose)
        collapsed = _frag.collapse_fragment(raw_fragment, version, verbose)
        collapsed_fragments[name] = collapsed

        if verbose:
            print(f"Loaded and collapsed fragment: {name}")

    return collapsed_fragments
