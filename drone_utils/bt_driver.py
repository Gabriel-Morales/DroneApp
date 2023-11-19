#!/usr/bin/env python3

import os
import time
from BluetoothServer import BluetoothCoordinator, _BLSocketWrapper

'''
This file is meant to debug and test the bluetooth module
'''

def entrypoint_basics():
    bc = BluetoothCoordinator(debug=True)
    print(f"Debug testing: Object map - {_BLSocketWrapper.get_instance()}")
    print("Debug testing: printing host bluetooth address:")
    bc._debug_get_host_addr()
    
    print("Debug testing: printing singleton test (no duplicate files or inits should take place)")
    for _ in range(10):
        print("Test one: ", os.path.exists("./btaddr"))
        bc = BluetoothCoordinator(debug=True)
        print("Test two: ", os.path.exists("./btaddr"))
        print(f"Socket object map test two: {_BLSocketWrapper.get_instance()}")


def entrypoint_advertise():
    bc = BluetoothCoordinator()
    bc.bc_advertise_service()
    time.sleep(50)
    bc.bc_stop_advertisement()

if __name__ == "__main__":
    entrypoint_basics()
    print("\n"*3)
    entrypoint_advertise()

