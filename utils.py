import datetime

import numpy as np

def samples_to_single_measurment(voltages):
    return (np.mean(voltages), np.std(voltages, ddof = 1) / np.sqrt(len(voltages)))

def make_data_label(name):
    return "{}_{}".format(name, datetime.datetime.now().time().isoformat("seconds").replace(":", "-"))