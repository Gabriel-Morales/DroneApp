#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
pip install Pillow
pip3 install numpy 
pip3 install simplejpeg==1.7.2
apt-get install bluez bluez-firmware libbluetooth-dev libbluetooth3 -y
apt-get install build-essential cmake pkg-config libjpeg-dev libtiff5-dev libjasper-dev libpng-dev libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libx264-dev libfontconfig1-dev libcairo2-dev libgdk-pixbuf2.0-dev libpango1.0-dev libgtk2.0-dev libgtk-3-dev libatlas-base-dev gfortran libhdf5-dev libhdf5-serial-dev libhdf5-103 python3-pyqt5 python3-dev

apt-get install libavcodec-dev libavformat-dev libswscale-dev -y
apt-get install libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev -y
apt-get install libglib2.0-dev

apt-get install libgtk2.0-dev -y
apt-get install libgtk-3-dev -y
apt-get install libpng-dev -y
apt-get install libjpeg-dev -y
apt-get install libopenexr-dev -y
apt-get install libtiff-dev -y
apt-get install libwebp-dev -y

apt-get install git -y
apt install python3-opencv -y
apt install python3-flask -y
apt install screen -y

#pip3 install opencv-python

###
# If you encounter bluetooth errors, do the following
# 	- Edit: /lib/systemd/system/bluetooth.service 
#		- Change the line 'ExecStart=/usr/lib/bluetooth/bluetoothd' to 'ExecStart=/usr/lib/bluetooth/bluetoothd -C'
#		- Run 'sudo sdptool add SP'.
# 	- Run 'sudo systemctl daemon-reload'
# 	- Run 'sudo systemctl restart bluetooth'
#	- Then finally to put the device into advert mode, you need to run 'sudo hciconfig hci0 piscan'
#	- Equivalently, you need to run 'sudo hciconfig hci0 noscan' to disable the advert mode.
# Run the python script in sudo.
###
