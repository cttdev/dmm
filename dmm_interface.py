import os
import pyvisa
import time

import numpy as np
import pandas as pd


class DMM:
    def __init__(self):
        # Setup the resource manager
        self.rm = pyvisa.ResourceManager()
    
    def connect(self):
        # Connect to the first instrument in the list
        try:
            self.dmm = self.rm.open_resource(self.rm.list_resources()[0])
        except IndexError:
            raise Exception("Cannot find a DMM, make sure it is connected!")

    def is_connected(self):
        if self.dmm is None:
            return False
        
        # Query the instrument to make sure it is there
        try:
            self.dmm.query('*IDN?')
            return True
        except Exception:
            return False
    
    def setup(self):
        # Instrument setup
        self.dmm.write("reset()")
        self.dmm.write("display.changescreen(display.SCREEN_GRAPH_SWIPE)")

        # Digitize voltage, use the 100mV range, and autoset impedance
        self.dmm.write("dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE")
        self.dmm.write("dmm.digitize.inputimpedance = dmm.IMPEDANCE_AUTO")
        self.dmm.write("dmm.digitize.range = 0.1")

        # Display all 6.5 digits
        self.dmm.write("dmm.digitize.displaydigits = dmm.DIGITS_6_5")

    def capture_time_period(self, sample_name, sample_rate, sample_time):
        # Ccompute the total number of samples
        num_samples = sample_rate * sample_time

        self.dmm.write("dmm.digitize.samplerate = {}".format(sample_rate))
        self.dmm.write("dmm.digitize.count = {}".format(num_samples))
        self.dmm.write("defbuffer1.capacity = {}".format(num_samples))

        # Confgure the apature to maximize the precision at the given sample rate
        self.dmm.write("dmm.digitize.aperture = dmm.APERTURE_AUTO")

        # Clear the buffer and read the signal
        self.dmm.write("defbuffer1.clear()")
        self.dmm.write("dmm.digitize.read()")

        # Pause for the approximate sample time plus a small delay
        time.sleep(sample_time + 0.5)

        # Dump the buffer once it is ready
        times = self.dmm.query_ascii_values("printbuffer(1,defbuffer1.n, defbuffer1.relativetimestamps)", container=np.array)
        voltages = self.dmm.query_ascii_values("printbuffer(1,defbuffer1.n, defbuffer1)", container=np.array)

        self.save_samples(sample_name, times, voltages)

        return (times, voltages)

    @staticmethod
    def save_samples(sample_name, times, voltages):
        # Make a dtatframe and store the data
        df = pd.DataFrame()
        df["Times (s)"] = times
        df["Voltages (V)"] = voltages
        
        # Make the data directory if it doesn't already exist
        if not os.path.exists("data/"):
            os.makedirs("data/")

        # Save the data
        df.to_csv("data/{}.csv".format(sample_name), index=False)

if __name__ == "__main__":
    kt = DMM()
    kt.connect()
    kt.setup()
    print(kt.is_connected())
    print(kt.capture_time_period("Test", 1e3, 10))