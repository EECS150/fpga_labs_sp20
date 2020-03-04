import os
import serial
import numpy as np
from matplotlib.image import imread
from PIL import Image

img_np = imread('imgs/mountain_lake_sunset.jpg')
height, width, _ = img_np.shape
img_char = np.zeros((height * width), dtype=np.uint8)

for y in range(height):
  for x in range(width):
    r = float(img_np[y][x][0] / 255)
    g = float(img_np[y][x][1] / 255)
    b = float(img_np[y][x][2] / 255)

    gs = 0.2989 * r + 0.5870 * g + 0.1140 * b
    gs = int(gs * 255)
    img_char[y * width + x] = gs

#im = Image.fromarray(img_char)
#im.save("new_img.jpeg")

# Windows
if os.name == 'nt':
    ser = serial.Serial()
    ser.baudrate = 115200
    ser.port = 'COM11' # CHANGE THIS COM PORT
    ser.open()
else:
    ser = serial.Serial('/dev/ttyUSB0')
    ser.baudrate = 115200

print('Sending img data over serial interface ...')
ser.write(bytearray(img_char))
print('Done')
