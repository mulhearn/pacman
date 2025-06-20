import numpy as np
import re
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def parse_tile_data(filename, tile_number):
    vset_list = []
    vdda_list = []
    idda_list = []
    vddd_list = []
    iddd_list = []

    with open(filename, 'r') as f:
        lines = f.readlines()

    tile_found = False

    for line in lines:
        # Detect TILE section
        tile_match = re.match(r'TILE:\s+(\d+)', line)
        if tile_match:
            current_tile = int(tile_match.group(1))
            tile_found = (current_tile == tile_number)
            continue

        if tile_found and line.startswith("vset:"):
            # Extract values
            match = re.search(
                r'vset:\s+0x([0-9a-fA-F]+)\s+vdda:\s+(\d+)\s+idda:\s+(\d+)\s+vddd:\s+(\d+)\s+iddd:\s+(\d+)', line)
            if match:
                vset_list.append(int(match.group(1), 16))  # Convert from hex
                vdda_list.append(int(match.group(2)))
                idda_list.append(int(match.group(3)))
                vddd_list.append(int(match.group(4)))
                iddd_list.append(int(match.group(5)))
        elif tile_found and line.startswith("TILE:"):
            break  # Next tile reached

    return (
        np.array(vset_list),
        np.array(vdda_list),
        np.array(idda_list),
        np.array(vddd_list),
        np.array(iddd_list)
    )

# Example usage
filename = 'iv.txt'
tile_number = 6  # Choose the TILE you want
vset, vdda, idda, vddd, iddd = parse_tile_data(filename, tile_number)

print("vset:", vset)
print("vdda:", vdda)
print("idda:", idda)
print("vddd:", vddd)
print("iddd:", iddd)

plt.plot(vset, vdda, "bo-")
plt.title("VDDA vs DAC")
plt.xlabel("DAC (hex)")
plt.ylabel("VDDA (mV)")
# include origin:
plt.xlim(left=0)
plt.ylim(bottom=0)
# format x-axis ticks as hex
hex_labels = [f'0x{x:04x}' for x in vset]
plt.xticks(ticks=vset, labels=hex_labels, rotation=45)
plt.tight_layout()
plt.savefig("vdda_dac.pdf")
plt.close()

plt.plot(vdda, idda, "bo-")
plt.title("IDDA vs VDDA")
plt.xlabel("VDDA (mV)")
plt.ylabel("IDDA (mV)")
# include origin:
plt.xlim(left=0)
plt.ylim(bottom=0)
plt.tight_layout()
plt.savefig("idda_vdda.pdf")
