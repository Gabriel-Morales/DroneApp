#!/usr/bin/env python3

import cv2 as cv
import numpy as np
import simplejpeg

from CameraDelegate import CameraDelegate

from BluetoothServer import BluetoothCoordinator, _BLPeripheralWrapper


if __name__ == "__main__":

    cd = CameraDelegate('192.168.0.1', 61271)
    cd.start_stream()

    while True:
        
        # Capture frame-by-frame
        frame = None
        try:
            frame = cd.get_current_frame()
        except:
            pass
        
        if frame is not None:
            frame = simplejpeg.decode_jpeg(frame,strict=False)
            frame = cv.cvtColor(frame, cv.COLOR_BGR2RGB) #cv.imdecode(frame, cv.IMREAD_COLOR)
            cv.imshow('frame', frame)
        else:
            cv.imshow('frame', np.zeros((1920,1080)))
        cv.waitKey(1)

    # When everything done, release the capture
    cv.destroyAllWindows()
