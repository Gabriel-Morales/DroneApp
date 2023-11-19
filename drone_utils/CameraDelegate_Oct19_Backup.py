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

        self.udp_proxy_frame_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        proxy_ip = subprocess.check_output(['ip', 'addr', 'show', 'wlan0']).decode().split("inet ")[1].split("/")[0]
        self.udp_proxy_frame_socket.bind((proxy_ip, 6789)) # binds the interface on port 6789
        

    # Calling point to capture frames indefinitely
    def start_stream(self):
        print('Started camera delegate service')
        stream_thread = threading.Thread(target=self._stream_thread_func, args=())
        stream_thread.start()


    def _stream_thread_func(self):
        print('Waiting for drone IP assignment')
        while True:
            try:
                drone_assigned_ap_ip = subprocess.check_output(['ip', 'addr', 'show', 'wlan1']).decode().split("inet ")[1].split("/")[0]
                
                print(f'Assigned: {drone_assigned_ap_ip}')
                print(f'Drone is at: {self.drone_ip}')
                break
            except Exception as e:
                pass
        
        self.udp_drone_instruction.sendto(b'\x63\x63\x01\x00\x00\x00\x00',(self.drone_ip, 40000))
        #print('waiting for client')
        #_, target_host = self.udp_proxy_frame_socket.recvfrom(2048) #TODO: Make this reentrant to the client
        #print('connected client') 
        frame_size_prev = -1
        buffer = []#io.BytesIO(b'')
        buff_time = 0 
        self.udp_proxy_frame_socket.settimeout(2)
        self.udp_proxy_frame_socket.setblocking(0)
        
        target_host = ('192.168.0.8', 6789)
        while True:
            
            # This is the reentrant code
            print('awaiting client')
            try:
                _, target_host = self.udp_proxy_frame_socket.recvfrom(3)
                print('got client keepalive')
            except:
                print(f'no keepalive, continuing with {target_host}')
                pass
    
            frame_recv, inf = self.udp_drone_instruction.recvfrom(2048)
            print('received frame')
            # send via proxy
            self.udp_proxy_frame_socket.sendto(frame_recv, target_host)
             
            #seq_num = frame_recv[3] # seems to be the fourth byte - not needed anymore
            if frame_recv[54:56] != b'\xff\xd8' :#b'\xff\xd9'):
                continue
            else:
                buffer = []
                buffer.append(frame_recv[54:])
                self.lock.acquire()
                while True:
                    frame_recv2, _ = self.udp_drone_instruction.recvfrom(4096)
                    # send via proxy
                    self.udp_proxy_frame_socket.sendto(frame_recv2, target_host)
                    print('sent frame pt2') 
                    buffer.append(frame_recv2[54:])
                     
                    if frame_recv2[-2:] == b'\xff\xd9':
                        break
                self.frame_local = b''.join(buffer)#np.frombuffer(b''.join(buffer))
                '''
                try:
                    print(f'Sending {len(self.frame_local)} bytes')
                    self.udp_proxy_frame_socket.sendto(self.frame_local, target_host)
                except:
                    pass
                '''
                self.lock.release()


    def get_current_frame(self):
        self.lock.acquire()
        frame = self.frame_local
        self.lock.release()
        return frame



    # wrapper method for convenience to retrieve jpeg mage
    @classmethod
    def decode_jpeg(self, frame_buffer):
        return simplejpeg.decode_jpeg(frame_buffer, strict=False)


