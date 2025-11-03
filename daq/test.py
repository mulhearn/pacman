# test.py

import asic_model_utils as am
from asic_register_update import asic_register_update
from asic_register_space import asic_register_space

def main():
    print("Loading yaml:");

    larpix_v3 = am.yaml_loader("config/larpix_v3.yml")
    # am.pretty_print(larpix_v3)

    am.verify_model(larpix_v3)

    am.print_register_map(larpix_v3)

    am.print_field_defaults(larpix_v3)
    
    return;
    
    print("Testing Updates:")
    
    # Create empty update
    u1 = asic_register_update()
    print("Empty update:")
    u1.pretty_print()

    # Create update from list
    updates_list = [[0, 0xA], [1, 0xB], [5, 0xFF]]
    u2 = asic_register_update(updates_list)
    print("\nUpdate from list:")
    u2.pretty_print()

    # Test __repr__
    print("\nrepr(u2):")
    print(repr(u2))

    # Test copy
    u3 = u2.copy()
    print("\nCopied update:")
    u3.pretty_print()

    # Modify original and show copy is unchanged
    u2.updates[0][1] = 0x00
    print("\nAfter modifying original:")
    print("Original:")
    u2.pretty_print()
    print("Copy:")
    u3.pretty_print()

if __name__ == "__main__":
    main()
