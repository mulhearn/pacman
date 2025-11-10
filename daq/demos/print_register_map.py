#!/usr/bin/env python3
import sys
from pathlib import Path

# Add project root (one level up from daq/) to sys.path
sys.path.append(str(Path(__file__).resolve().parents[1]))

from asic.asic_spec import asic_spec_from_yaml

def main():
    spec = asic_spec_from_yaml("config/asics/larpix_v3.yaml")
    spec.print_register_map()

if __name__ == "__main__":
    main()
