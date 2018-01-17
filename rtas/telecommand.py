import serial
import time
import sys

device = '/dev/ttyACM0'
if len(sys.argv) > 1:
	device = sys.argv[1]
ser = serial.Serial(device,9600)
ser.write(';abcdefghhj;')
time.sleep(8)
ser.write(';aaaaaaa	aa;')
time.sleep(5)
ser.write(';aaaaaaa	aa;')
time.sleep(5)
ser.write(';abcdefghhj;')
time.sleep(10)
ser.write(';abcdefghhj;')
time.sleep(6)
ser.write(';abcdefghhj;')
time.sleep(10)
ser.write(';abcdefghhj;')
time.sleep(5)
ser.write(';aaaaaaa	aa;')
time.sleep(7)
ser.write(';abcdefghhj;')
time.sleep(4)
ser.write(';abcdefghhj;')





