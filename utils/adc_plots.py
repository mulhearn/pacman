import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

FILE = None
FINISHED = False

def open_file(file_path):
    global FILE, FINISHED
    FILE = open(file_path, 'r')
    FINISHED = False

def get_next():
    global FILE, FINISHED

    if FINISHED:
        return None

    # Read the 5 fixed header lines
    headers = []
    for i in range(5):
        line = FILE.readline()
        if not line:
            FINISHED = True
            FILE.close()
            return None
        headers.append(line.strip())

    try:
        config = int(headers[0].split(":", 1)[1].strip(), 0)
        last_address = int(headers[1].split(":", 1)[1].strip(), 0)
        last_value = int(headers[2].split(":", 1)[1].strip(), 0)
        adc_input = int(headers[3].split(":", 1)[1].strip(), 0)
        buffer_size = int(headers[4].split(":", 1)[1].strip(), 0)
    except Exception as error:
        raise ValueError(f"Error parsing headers: {error}")

    # Read exactly buffer_size integers
    buffer_values = []
    while len(buffer_values) < buffer_size:
        line = FILE.readline()
        if not line:
            raise ValueError("Unexpected end of file while reading buffer")
        parts = line.replace(",", " ").split()
        for part in parts:
            buffer_values.append(int(part.strip(), 0))
            if len(buffer_values) == buffer_size:
                break

    buffer = np.array(buffer_values, dtype=int)

    return config, last_address, last_value, adc_input, buffer_size, buffer

open_file("adc.txt")
buffer_index = 0

while True:
    result = get_next()
    if result is None:
        break

    config, last_address, last_value, adc_input, buffer_size, buffer = result

    print(f"CONFIG:        {hex(config)}")
    print(f"LAST ADDRESS:  {hex(last_address)}")
    print(f"LAST VALUE:    {hex(last_value)}")
    print(f"ADC_INPUT:     {adc_input}")
    print(f"BUFFER SIZE:   {buffer_size}")
    hex_values = [hex(val) for val in buffer[:5]]
    print("BUFFER[:5]:  ", hex_values)

    # Plot the buffer
    voltage = (buffer - 0x800)/0x800
    plt.figure(figsize=(10, 4))
    plt.plot(10*np.arange(buffer_size), voltage, marker='o', linestyle='-')
    plt.title(f"Buffer {buffer_index} (CONFIG={hex(config)}, INPUT={hex(adc_input)})")
    plt.xlabel("Time (ns)")
    plt.ylabel("ADC Voltage (mV)")
    plt.grid(True)

    filename = f"buffer_{buffer_index}.pdf"
    plt.savefig(filename)
    plt.close()
    print(f"Saved plot to {filename}")
    print("------")

    buffer_index += 1
