import pyvisa

# Script to connect to an instrument, start data collection, and dump the output into a readable format

# Connect to the first instrument in the list
rm = pyvisa.ResourceManager()
dmm = rm.open_resource(rm.list_resources()[0])

# Query the instrument to make sure it is there
print(dmm.query('*IDN?'))

# Set a faster baud rate
dmm.baud_rate = 115200

# Instrument setup
dmm.write("reset()")
dmm.write("display.changescreen(display.SCREEN_GRAPH_SWIPE)")

# # Digitize voltage, use the 100mV range, and autoset impedance
# dmm.write("dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE")
# dmm.write("dmm.digitize.inputimpedance = dmm.IMPEDANCE_AUTO")
# dmm.write("dmm.digitize.range = 0.1")

# # Sample at 10kHz for 10s
# sample_rate = 1e3
# sample_time = 10
# num_samples = sample_rate * sample_time

# dmm.write("dmm.digitize.samplerate = {}".format(sample_rate))
# dmm.write("dmm.digitize.count = {}".format(num_samples))
# dmm.write("defbuffer1.capacity = {}".format(num_samples))

# # Confgure the apature to maximize the precision at the given sample rate
# dmm.write("dmm.digitize.aperture = dmm.APERTURE_AUTO")

# # Clear the buffer and read the signal
# dmm.write("defbuffer1.clear()")
# dmm.write("dmm.digitize.read()")

# Digitize voltage, use the 100mV range, and autoset impedance
dmm.write("dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE")
dmm.write("dmm.digitize.inputimpedance = dmm.IMPEDANCE_AUTO")
dmm.write("dmm.digitize.range = 0.1")

# Display all 6.5 digits
dmm.write("dmm.digitize.displaydigits = dmm.DIGITS_6_5")

# Sample at 10kHz for 10s
sample_rate = 1e3
sample_time = 20
num_samples = sample_rate * sample_time

dmm.write("dmm.digitize.samplerate = {}".format(sample_rate))
dmm.write("dmm.digitize.count = {}".format(num_samples))
dmm.write("defbuffer1.capacity = {}".format(num_samples))

# Confgure the apature to maximize the precision at the given sample rate
dmm.write("dmm.digitize.aperture = dmm.APERTURE_AUTO")

# Clear the buffer and read the signal
dmm.write("defbuffer1.clear()")
dmm.write("dmm.digitize.read()")






