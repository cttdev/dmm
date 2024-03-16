import queue
import threading
import time

from jsonrpcclient import Ok, Error, parse_json, request_json
import websockets.sync.client
from websockets import ConnectionClosed, ConnectionClosedError


class Klipper():
    """
    A class to hook into the websockets interface of moonraker and send data to klipper.
    """

    def __init__(self, server_address):
        self.server_address = server_address
        
        # Setup the multithreading thread and command queue
        self.thread = threading.Thread(target=self.send_worker)
        self.stop_event = threading.Event()
        self.q = queue.Queue()
    
    def connect(self):
        # Try for 10 seconds to open the Moonraker websocket
        try:
            self.ws = websockets.sync.client.connect("ws://" + self.server_address + "/websocket")
        except TimeoutError:
            # If this fails return a timeout error
            raise TimeoutError("Cannot connect to Moonraker at {}!".format(self.server_address))

        print("Connected to Moonraker at {}!".format(self.server_address))

        # Start the gcode sender
        self.thread.start()
        self.stop_event.clear()

    def is_connected(self):
        try:
            self.ws.recv()
            return True
        except ConnectionClosed as cc:
            if cc == ConnectionClosedError:
                print("Connection was close due to error!")
            else:
                print("Connection was cleanly closed!")
            return False
        
    def disconnect(self):
        # Stop the gcode sender
        self.stop_event.set()

        # Wait for a short period to allow the thread to stop
        time.sleep(1)

        # Check if connected to moonraker
        if not self.is_connected():
            raise ConnectionError("Not Connected to Moonraker!")

        self.ws.close()

        print("Disconnected from Moonraker at {}!".format(self.server_address))
        
    def query_gcode(self, gcode):
        # Check if connected to moonraker
        if not self.is_connected():
            raise ConnectionError("Not Connected to Moonraker!")

        # Send gcode to moonraker
        self.ws.send(request_json("printer.gcode.script", params={"script": gcode}))
        print("Sending: {}".format(gcode))

        # Get response from moonraker
        while True:
            try:
                response = parse_json(self.ws.recv())
                print(response)
            except KeyError:
                continue

            if isinstance(response, Ok):
                return response.result
            elif isinstance(response, Error):
                print("Error Sending GCode: " + response.message)
                return
            
    def send_worker(self):
        while not self.stop_event.is_set():
            if self.q.qsize():
                # Get the first command in the queue and send it out
                self.query_gcode(self.q.get())

                # Indiciate the gcode has been sent and executed
                self.q.task_done()
    
    def heat_hotend(self, temprature):
        # Heat the hotend and wait for it to reach temprature
        self.q.put("M109 S{}".format(temprature))

        # Join the queue to block the calling thread until the hotend is up to temprature
        self.q.join()

    def cool_down(self):
        # Set the hotend to zero temprature
        self.q.put("M104 S0")

    def clear_pressure_advance(self):
        # Clear pressure advance settings that may mess with readings
        self.q.put("SET_PRESSURE_ADVANCE ADVANCE=0 SMOOTH_TIME=0")

    def extruder_relative(self):
        # Put the extruder into relative positioning mode
        self.q.put("M83")

    def extrude_duration(self, extrusion_duration, extrusion_speed):
        # Compute the desired extrusion length
        extrusion_length = extrusion_speed * extrusion_duration # mm

        # Extrude the computed length at the given speed (mm / min)
        self.q.put("G1 E{} F{}".format(extrusion_length, extrusion_speed * 60))

    def pause(self, duration):
        self.q.put("G4 P{}".format(duration * 1000))


    # def check_klipper_connection(self):
    #     state = self.query("server.info")

    #     if state["klippy_state"] == "ready":
    #         return True
    #     elif state["klippy_state"] == "startup":
    #         time.sleep(2)
    #         return self.check_klipper_connection()
    #     else:
    #         print("Klipper Is Not Ready! Status:" + self.query("printer.info")["state_message"])
    #         return False
    
    # def query(self, request):
    #     # Check if connected to moonraker
    #     if not self.is_connected():
    #         print("")
    #         return

    #     # Send request to moonraker
    #     self.moonraker_websocket.send(request_json(request))

    #     # Get response from moonraker
    #     while True:
    #         response = parse_json(self.moonraker_websocket.recv())
    #         if isinstance(response, Ok):
    #             return response.result
    #         elif isinstance(response, Error):
    #             print(response.message)
    #             self.throw_message_status(Klipper.MessageStatus.FAILURE)


    #     # # Start a thread to try to connect to moonraker
    #     # def run():
    #     #     while True:
    #     #         # Check if connected to moonraker
    #     #         self.moonraker_websocket.recv()

    #     #         if not self.moonraker_websocket.connected:
    #     #             try:
    #     #                 self.moonraker_websocket.connect("ws://localhost:5000")
    #     #         self.throw_connection_status(Klipper.ConnectionStatus.CONNECTED)

    # def send_initialize(self):
    #     # Check if connected to moonraker
    #     if not self.is_connected():
    #         self.throw_message_status(Klipper.MessageStatus.FAILURE)
    #         return

    #     # Send request to moonraker
    #     self.moonraker_websocket.send(request_json("printer.gcode.script", params={"script": "SET_KINEMATIC_POSITION X=20 Y=25 Z=0"}))

    #     # Get response from moonraker
    #     while True:
    #         try:
    #             response = parse_json(self.moonraker_websocket.recv())
    #         except KeyError:
    #             print("KeyError")
    #             continue

    #         if isinstance(response, Ok):
    #             self.throw_message_status(Klipper.MessageStatus.SUCCESS)
    #             return
    #         elif isinstance(response, Error):
    #             self.throw_message_status(Klipper.MessageStatus.FAILURE)
    #             print("Error Sending GCode: " + response.message)
    #             return

    # def send_end(self):
    #     # Check if connected to moonraker
    #     if not self.is_connected():
    #         self.throw_message_status(Klipper.MessageStatus.FAILURE)
    #         return

    #     # Send request to moonraker
    #     self.moonraker_websocket.send(request_json("printer.gcode.script", params={"script": "M18"}))

    #     # Get response from moonraker
    #     while True:
    #         try:
    #             response = parse_json(self.moonraker_websocket.recv())
    #         except KeyError:
    #             print("KeyError")
    #             continue

    #         if isinstance(response, Ok):
    #             self.throw_message_status(Klipper.MessageStatus.SUCCESS)
    #             return
    #         elif isinstance(response, Error):
    #             self.throw_message_status(Klipper.MessageStatus.FAILURE)
    #             print("Error Sending GCode: " + response.message)
    #             return

    # def send_gcode(self, gcode):
    #     # Check if connected to moonraker
    #     if not self.is_connected():
    #         self.throw_message_status(Klipper.MessageStatus.FAILURE)
    #         return

    #     # Send gcode to moonraker
    #     self.moonraker_websocket.send(request_json("printer.gcode.script", params={"script": gcode}))

    #     # Get response from moonraker
    #     while True:
    #         try:
    #             response = parse_json(self.moonraker_websocket.recv())
    #         except KeyError:
    #             print("KeyError")
    #             continue

    #         if isinstance(response, Ok):
    #             self.throw_message_status(Klipper.MessageStatus.SUCCESS)
    #             return
    #         elif isinstance(response, Error):
    #             self.throw_message_status(Klipper.MessageStatus.FAILURE)
    #             print("Error Sending GCode: " + response.message)
    #             return


    # # def send_gcode(self, gcode):
    #     # # Check if connected to moonraker
    #     # if self.moonraker_websocket is None:
    #     #     self.throw_message_status(Klipper.MessageStatus.FAILURE)
    #     #     return
    #     # else:
    #     #     self.throw_message_status(Klipper.MessageStatus.SUCCESS)

    #     # print("here")
    #     # if self.moonraker_websocket:            
    #     #     await self.moonraker_websocket.send(request_json("ping"))
    #     #     response = parse_json(await self.moonraker_websocket.recv())

    #     #     if isinstance(response, Ok):
    #     #         print(response.result)

    # class ConnectionStatus(Enum):
    #     CONNECTED = 1
    #     DISCONNECTED = 2

    # class MessageStatus(Enum):
    #     SUCCESS = 1
    #     FAILURE = 2
    #     READY = 3

if __name__ == "__main__":
    klipper = Klipper("ratrig.mit.edu:7125")

    klipper.connect()
    print(klipper.is_connected())
    klipper.heat_hotend(210)
    klipper.clear_pressure_advance()
    klipper.extruder_relative()
    klipper.pause(0.5)
    klipper.extrude_duration(5, 5)

    # Wait for all the commands we sent to finish before disconnecting
    time.sleep(6)

    klipper.disconnect()