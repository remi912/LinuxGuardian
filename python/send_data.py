import os
import fileinput
import time
import sys
import paho.mqtt.client as mqtt
import json

THINGSBOARD_HOST = '192.168.44.12'
ACCESS_TOKEN = 'TEST_SCRIPT_TOKEN'

# Data capture and upload interval in seconds.
INTERVAL=2

computer_stat = {'IP': 0, 'UP': 0, 'USERS': 0, 'DISKUSE': 0, 'READ': 0, 'WRITE': 0, 'MEMUSE': 0, 'CPUUSE': 0, 'TEMPCPU': 0}

next_reading = time.time() 

client = mqtt.Client()

# Set access token
client.username_pw_set(ACCESS_TOKEN)

# Connect to ThingsBoard using default MQTT port and 60 seconds keepalive interval
client.connect(THINGSBOARD_HOST, 1883, 60)

client.loop_start()

try:
    while True:

        for fileinput_line in fileinput.input():
            if 'Exit' == fileinput_line.rstrip():
                break
            #print(fileinput_line)
            # "IP 192.168.44.13:UP 23492:USERS 5:DISKUSE 6:READ 7.66:WRITE 17.54:MEMUSE 10:CPUUSE 1:TEMPCPU 62"
            txt = fileinput_line
            table = txt.split(":")
            # print(table)
            # print(table[0].split(" ")[1]) # IP address
            # print(table[1].split(" ")[1]) # UP
            # print(table[2].split(" ")[1]) # USERS
            # print(table[3].split(" ")[1]) # DISKUSE
            # print(table[4].split(" ")[1]) # READ
            # print(table[5].split(" ")[1]) # WRITE
            # print(table[6].split(" ")[1]) # MEMUSE
            # print(table[7].split(" ")[1]) # CPUUSE
            #print(table[8].split(" ")[1]) # TEMPCPU

            IP      = table[0].split(" ")[1]
            UP      = float(table[1].split(" ")[1])
            USERS   = float(table[2].split(" ")[1])
            DISKUSE = float(table[3].split(" ")[1])
            READ    = float(table[4].split(" ")[1])
            WRITE   = float(table[5].split(" ")[1])
            MEMUSE  = float(table[6].split(" ")[1])
            CPUUSE  = float(table[7].split(" ")[1])
            TEMPCPU = float(table[8].split(" ")[1])

            print(u"IP: {:s}, UP: {:g}, USERS: {:g}, DISKUSE: {:g}, READ: {:g}, WRITE: {:g}, MEMUSE: {:g}, CPUUSE: {:g}, TEMPCPU: {:g}\u00b0C".format(IP, UP, USERS, DISKUSE, READ, WRITE, MEMUSE, CPUUSE, TEMPCPU))

            computer_stat['UP']      = UP
            computer_stat['USERS']   = USERS
            computer_stat['DISKUSE'] = DISKUSE
            computer_stat['READ']    = READ
            computer_stat['WRITE']   = WRITE
            computer_stat['MEMUSE']  = MEMUSE
            computer_stat['CPUUSE']  = CPUUSE
            computer_stat['TEMPCPU'] = TEMPCPU

            # Sending computer_stat data to ThingsBoard
            client.publish('v1/devices/me/telemetry', json.dumps(computer_stat), 1)

        next_reading += INTERVAL
        sleep_time = next_reading-time.time()
        if sleep_time > 0:
            time.sleep(sleep_time)
except KeyboardInterrupt:
    pass

client.loop_stop()
client.disconnect()