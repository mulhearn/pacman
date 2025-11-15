#!/usr/bin/env python3

from larpix_control import asic_spec, asic_spec_from_yaml

def main():
    spec = asic_spec_from_yaml("config/asics/larpix_v3.yaml")
    spec.print_register_map()

if __name__ == "__main__":
    main()
