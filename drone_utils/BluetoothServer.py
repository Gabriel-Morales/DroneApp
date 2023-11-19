#!/usr/bin/env python3

"""
This is the main module for bluetooth utilities in the drone.
To use this module, you need PyBlueZ. You can run the dependency script provided.
Identifiers prefixed with an underscore ("_IdentName") are intended to be "private".
"""


from enum import Enum
import threading

class BLServerStates(Enum):
    ADV = 0 # currently advertising
    CON = 1 # currently connected
    DIS_CON = 2 # disconnected


# A singleton object for the socket since we only need one socket.
class _BLPeripheralWrapper:
    
    _bl_comm = None

    def __init__(self):
        self.state = BLServerStates.ADV
        self.peripheral = None #Peripheral()
         
    def _transition_state(self):
        self.state  = BLServerStates[self.state % (len(BLServerStates))]
 
    def get_state(self):
        return self.state

    def get_socket(self):
        return self.bl_socket

    @classmethod
    def get_instance(self, debug=False):
        if _BLPeripheralWrapper._bl_comm is None:
            if debug:
                print("initializing new instance.")
            _BLPeripheralWrapper._bl_comm = _BLPeripheralWrapper()
        return _BLPeripheralWrapper._bl_comm




# Wrapper class as the entry point for the drone
class BluetoothCoordinator:

    def __init__(self, debug=False):
        self._bt_socket = _BLPeripheralWrapper.get_instance(debug=debug)
        self.service_hex = "EA03789F-EEEE-EEEE-FA50-6612EEFA5E98"
        
        
    def _debug_get_host_addr(self):
        print(self._bt_socket.host_addr)
    
    def start_services(self):
        self.bc_advertise_service()

    def bc_advertise_service(self):
        print('Starting adverts')
        uuid = self.service_hex
        advertise_service(self._bt_socket.get_socket(),"DroneServerBT", service_id=uuid, service_classes = [uuid, GENERIC_AUDIO_CLASS])
        # Thread just to listen for connections
        cl = threading.Thread(target=self.connection_listener, args=())
        cl.start()

    def connection_listener(self):
        print(f'Listening')
        self.client, clientInfo = self._bt_socket.get_socket().accept()
        print(f'Client connected! {clientInfo}')
        self._bt_socket._transition_state()

    def bc_stop_advertisement(self):
        os.system('hciconfig hci0 noscan')
        os.system('sudo hciconfig hci0 noleadv')
        stop_advertising(self._bt_socket.get_socket())

    def receive_message(self):
        self.client.setblocking(0)
        data = self.client.recv(2046)
        self.client.setblocking(1)
        return data

    def send_message(self, data):
        self.client.send(data)

    def get_bt_state(self):
        return self._bt_socket.get_state()


