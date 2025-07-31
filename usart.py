import serial
from time import sleep
import binascii

def str_to_hexStr(string):
    str_bin = string.encode('utf-8')
    return binascii.hexlify(str_bin).decode('utf-8')

ser = serial.Serial ("COM11", 921600)    #Open port with baud rate
print("running")
while True:
    print(str_to_hexStr(ser.read()))




