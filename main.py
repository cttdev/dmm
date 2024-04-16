import os
import time

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

from scipy.optimize import curve_fit

from klipper_interface import Klipper
from dmm_interface import DMM

from utils import samples_to_single_measurment, make_data_label

# Setup
K_0 = 0 # V
K_1 = 1215.9161379870343 # V / kg

hotend_temprature = 230 # deg C

flow_rates = np.linspace(5, 35, 5) # mm^3 / s
extrusion_time = 5 # s
sample_frequency = 1000 # Hz

filament_diameter = 1.75 # mm
extrusion_speeds = flow_rates / (np.pi * (filament_diameter / 2.0)**2)

calibrate = False
calibration_masses = [0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1] # kg

max_load_cell_mass = 10 # kg
load_cell_constant = 1.0 # mV / V
excitation_voltage = 10.00 # V

K_1_guess = (max_load_cell_mass * 1000) / (load_cell_constant * excitation_voltage) # kg / V

print("K_1 Guess: {} V/kg".format(K_1_guess))

# Initialize the DMM
kt = DMM()
kt.connect()
kt.setup()
print("DMM Connected: {}".format(kt.is_connected()))

# Initalize Klipper
klipper = Klipper("ratrig.mit.edu:7125")
klipper.connect()
print("Klipper Connected: {}".format(klipper.is_connected()))

if calibrate:
    # Run the calibration sequence
    num_calibration_samples = 1000
    calibration_sample_frequency = 1000 # Hz
    calibration_time = num_calibration_samples / calibration_sample_frequency # s

    # Start with the base case
    print("Running Base Case...")
    input("Press enter to measure!")
    (baseline_times, baseline_voltages) = kt.capture_time_period(make_data_label("Baseline_Calibration"), calibration_sample_frequency, calibration_time)
    (baseline_offset, baseline_offset_uncertainty) = samples_to_single_measurment(baseline_voltages)

    print("K_0 Measured: {} V".format(baseline_offset))

    # Measure the wire case
    print("Running Wire Case...")
    input("Press enter to measure!")
    (wire_times, wire_voltages) = kt.capture_time_period(make_data_label("Wire_Calibration"), calibration_sample_frequency, calibration_time)
    (wire_offset, wire_offset_uncertainty) = samples_to_single_measurment(wire_voltages)

    # Iterate over all the calibration masses
    mass_voltages = []
    mass_uncertainties = []
    for mass in calibration_masses:
        # Print the mass and wait for user input
        print("Running Mass: {} kg".format(mass))
        input("Press enter to measure!")

        # Compute the predicted voltage
        predicted_voltage = mass / K_1_guess + wire_offset
        print("Predicted Voltage: {} mV".format(predicted_voltage * 1000))

        # Measure the voltage
        (times, voltages) = kt.capture_time_period(make_data_label("Mass_{}kg_Calibration".format(mass)), calibration_sample_frequency, calibration_time)
        (mass_value, mass_uncertianty) = samples_to_single_measurment(voltages)
        
        print("Measured Voltage: {} mV".format(mass_value * 1000))

        mass_voltages.append(mass_value)
        mass_uncertainties.append(mass_uncertianty)

    # Make the mass value, mass voltage value, and mass voltage value uncertainity list into numpy arrays
    calibration_masses = np.array(calibration_masses)
    mass_voltages = np.array(mass_voltages)
    mass_uncertainties = np.array(mass_uncertainties)

    # Compute a fit on the mass values to get the K_1 coefficent
    mass_voltages_transformed = mass_voltages - wire_offset

    # Define a linear curve_fit function
    def func(x, a):
        return a * x

    (popt, pcov) = curve_fit(func, mass_voltages_transformed, calibration_masses)
    punc = np.sqrt(np.diag(pcov))

    # Extract K1 and the uncertainty
    K_1_meas = popt[0]
    K_1_meas_uncertainty = punc[0]

    print("Fit Parameters: {}".format(popt))
    print("Fit Covariances: {}".format(pcov))
    print("Fit Uncertainties: {}".format(punc))

    print("Calibration Masses:")
    print(calibration_masses)
    print("Calibration Mass Voltages:")
    print(mass_voltages)
    print("Calibration Mass Uncertainties:")
    print(mass_uncertainties)

    print("Wire Offset: {} V".format(wire_offset))
    print("Wire Offset Uncertainty: {} V".format(wire_offset_uncertainty))

    print("K_0 Measured: {} V".format(baseline_offset))

    print("K_1 Guess: {} kg/V".format(K_1_guess))
    print("K_1 Measured: {} kg/V".format(K_1_meas))
    print("K_1 Uncertainty: {} kg/V".format(K_1_meas_uncertainty))

# Clear all pressure advance settings
klipper.clear_pressure_advance()

# Switch to relative extrusion mode
klipper.extruder_relative()

# Heat the hotend to the set temprature and wait for it to get up to temprature
klipper.heat_hotend(hotend_temprature)

# Run sweeps across the given flow rates
run_times = []
run_forces = []

# Plot a figure of the data
plt.ion()
fig = plt.figure()
plt.xlabel("Time (s)")
plt.ylabel("Force (kg)")
plt.legend()
for (i, flow_rate) in enumerate(flow_rates):
    # Print the flow rate currently being run
    print("Running Flow Rate: {} mm^3 / s".format(flow_rate))

    # Get the extrusion speed for the given flow rate
    extrusion_speed = extrusion_speeds[i]
    print("Running Extrusion Speed: {} mm^3 / s".format(extrusion_speed))

    # Send a pause command to delay the extrusion start so the data collection can catch up
    klipper.pause(0.5)

    # Send the extrision command
    klipper.extrude_duration(extrusion_time, extrusion_speed)

    # Offset the extrusion time to capture the full extrusion and flow rate drop
    sample_time = extrusion_time + 2 #s

    # Start the data collection
    (times, voltages) = kt.capture_time_period(make_data_label("Flow_Rate_{}_mm3s".format(flow_rate)), sample_frequency, sample_time)
    
    # Convert the voltages to forces
    forces = K_1 * (voltages - K_0)

    # Store the run times and forces
    run_times.append(times)
    run_forces.append(forces)

    # Add the run to the figure
    plt.plot(times, forces, label="Flow Rate: {} mm^3 / s".format(flow_rate))
    plt.legend(loc="upper right")

    # Update the figure
    fig.canvas.draw()
    fig.canvas.flush_events()

    # Make the data directory if it doesn't already exist
    data_dir = "data/trials/{}/".format(flow_rate)
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)

    # Create a sample name
    sample_name = make_data_label("Flow_Rate_{}_mm3s".format(flow_rate))
    
    # Make a dataframe and store the data
    df = pd.DataFrame()
    df["Times (s)"] = times
    df["Forces (kg)"] = forces
    
    df.to_csv(data_dir + "{}.csv".format(sample_name), index=False)

    # Let the hotend temperature stabelize before the next run
    time.sleep(5)

# Disconnect from Klipper
klipper.disconnect()
