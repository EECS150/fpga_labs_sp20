import numpy as np
from scipy.io import wavfile
import sys

fs = 44100
# Do Re Mi Fa So La Ti Do
#list_notes = [(440, 1), (493.88, 1), (554.37, 1), (587.33, 1), (659.25, 1), (740, 1), (830.60, 1), (880, 1)]

frequency = float(sys.argv[1])
duration = float(sys.argv[2])
num_samples = int(sys.argv[3])
samples = np.arange(duration * fs) / fs
signal = np.sin(2 * np.pi * frequency * samples)

signal = signal * 32767
signal = np.int16(signal)
wavfile.write(str("tone.wav"), fs, signal)

mif_file = open('tone_%s_data_bin.mif' % (int(frequency)), 'w')
for i in range(0, num_samples):
  if (i >= fs):
    mif_file.write("%s\n" % (np.binary_repr(0, 16)))
  else:
    mif_file.write("%s\n" % (np.binary_repr(signal[i], 16)))
mif_file.close()
