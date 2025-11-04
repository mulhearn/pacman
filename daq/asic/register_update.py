# register_update.py

class register_update:
    """
    Represents an update to a subset of ASIC registers.
    Each item is a pair [register_index, value].
    """

    def __init__(self, updates=None):
        """
        Initialize with optional list of updates [[reg, val], ...].
        """
        self.updates = []
        if updates is not None:
            for u in updates:
                if not (isinstance(u, list) or isinstance(u, tuple)) or len(u) != 2:
                    raise ValueError(f"Update {u} must be [reg, val]")
                self.updates.append([u[0], u[1]])

    def __repr__(self):
        return f"register_update({self.updates})"

    def pretty_print(self):
        """
        Print the register updates in human-readable form.
        """
        print("ASIC Register Update:")
        for reg, val in self.updates:
            print(f"  Reg {reg:03d}: 0x{val:02X}")

    def copy(self):
        """
        Return a new copy of this update.
        """
        return register_update([u.copy() for u in self.updates])
