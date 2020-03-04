import os
import serial
import sys
# Windows
if os.name == 'nt':
    ser = serial.Serial()
    ser.baudrate = 115200
    ser.port = 'COM11' # CHANGE THIS COM PORT
    ser.open()
else:
    ser = serial.Serial('/dev/ttyUSB0')
    ser.baudrate = 115200

text_file = sys.argv[1]

with open(text_file, 'r') as file:
  text_tx = file.read().replace('\n', '\n\r')

input('Open a serial program in another terminal, then hit Enter')
ser.write(bytearray([ord(char) for char in text_tx]))
print('Done')
