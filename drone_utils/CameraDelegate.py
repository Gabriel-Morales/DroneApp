#!/usr/bin/env python3

import cv2 as cv
import numpy as np
import threading
import queue
import time
import signal 
import os, sys
import socket
import io
import simplejpeg
import subprocess
import time

class CameraDelegate:

    def __init__(self, drone_ip, drone_port):
        self.frame_local = None
        self.lock = threading.Semaphore(1)
        self.drone_ip = drone_ip
        self.drone_port = drone_port
         
        self.udp_drone_instruction = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        self.frame_queue = queue.Queue()

        # self.udp_proxy_frame_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        self.proxy_ip = subprocess.check_output(['ip', 'addr', 'show', 'enp34s0']).decode().split("inet ")[1].split("/")[0]
        # self.udp_proxy_frame_socket.bind((proxy_ip, 6789)) # binds the interface on port 6789
        

    # Calling point to capture frames indefinitely
    def start_stream(self):
        print('Started camera delegate service')
        stream_thread = threading.Thread(target=self._stream_thread_func, args=())
        stream_thread.start()


    def _stream_thread_func(self):
        print('Waiting for drone IP assignment')
        while True:
            try:
                drone_assigned_ap_ip = subprocess.check_output(['ip', 'addr', 'show', 'wlx000f55a8e804']).decode().split("inet ")[1].split("/")[0]
                
                print(f'Assigned: {drone_assigned_ap_ip}')
                print(f'Drone is at: {self.drone_ip}')
                break
            except Exception as e:
                pass
        
       
        # Patch for re-entrancy?
        if 'prior_p' in os.environ:
            self.udp_drone_instruction.bind(('192.168.0.1', int(os.environ['prior_p'])))
        else:
            self.udp_drone_instruction.sendto(b'\x63\x63\x01\x00\x00\x00\x00',(self.drone_ip, 40000))
        #print('waiting for client')
        #_, target_host = self.udp_proxy_frame_socket.recvfrom(2048) #TODO: Make this reentrant to the client
        #print('connected client') 
        frame_size_prev = -1
        buffer = []#io.BytesIO(b'')
        buff_time = 0 
        # self.udp_proxy_frame_socket.settimeout(2)
        #self.udp_proxy_frame_socket.setblocking(0)
        

        while True:
            
            # This is the reentrant code
            # print('awaiting client')
            # try:
            #     _, target_host = self.udp_proxy_frame_socket.recvfrom(3)
            #     print('got client keepalive')
            # except:
            #     print(f'no keepalive, continuing with {target_host}')
            #     pass
    
            frame_recv, inf = self.udp_drone_instruction.recvfrom(2048)
            os.environ['prior_p'] = str(inf[1])

            # send via proxy
            #self.udp_proxy_frame_socket.sendto(frame_recv, target_host)
            # JPEG JFIF: \xFF\xD8\xFF\xE0\x00\x10\x4A\x46\x49\x46\x00\x01
            #seq_num = frame_recv[3] # seems to be the fourth byte - not needed anymore
            
            if frame_recv[54:56] == b'\xFF\xD8' :#b'\xff\xd9'):
                
                buffer = []
                buffer.append(frame_recv[54:])
                
                while True:
                    frame_recv2, _ = self.udp_drone_instruction.recvfrom(2048)

                    buffer.append(frame_recv2[54:])
                    
                    if frame_recv2[-2:] == b'\xFF\xD9':
                        self.frame_local = b''.join(buffer)
                        self.frame_queue.put_nowait(self.frame_local)
                        break



    def get_current_frame(self):
        return self.frame_queue.get(timeout=2)



    # wrapper method for convenience to retrieve jpeg mage
    @classmethod
    def decode_jpeg(self, frame_buffer):
        return simplejpeg.decode_jpeg(frame_buffer, strict=False)


