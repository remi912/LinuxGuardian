import os
import fileinput
import time
import sys
import paho.mqtt.client as mqtt
import json

THINGSBOARD_HOST = '192.70.36.95'
ACCESS_TOKEN = 'TEST_SCRIPT_TOKEN'

# Data capture and upload interval in seconds.
INTERVAL=10

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
            
	    # Exit condition
	    if 'Exit' == fileinput_line.rstrip():
                break
            
            # Debug
            # print(fileinput_line)
            # "IP 192.168.44.13:UP 23492:USERS 5:DISKUSE 6:READ 7.66:WRITE 17.54:MEMUSE 10:CPUUSE 1:TEMPCPU 62"
            
	        txt = fileinput_line
            table = txt.split(":")

            IP      = table[0].split(" ")[1]
            UP      = float(table[1].split(" ")[1])
            USERS   = float(table[2].split(" ")[1])
            DISKUSE = float(table[3].split(" ")[1])
            READ    = float(table[4].split(" ")[1])
            WRITE   = float(table[5].split(" ")[1])
            MEMUSE  = float(table[6].split(" ")[1])
            CPUUSE  = float(table[7].split(" ")[1])
            TEMPCPU = float(table[8].split(" ")[1])

            # Switch TOKEN

            if IP == '192.168.44.13':
                ACCESS_TOKEN = '2IKLbndQTZc6MHhkk90g'
            elif IP == '192.168.44.14':
                ACCESS_TOKEN = 'kBtLHp1hR7DR2u64xekC'
            elif IP == '192.168.44.15':
                ACCESS_TOKEN = 'HIfqPvTbUoqwyFhBN1mK'
            elif IP == '192.168.44.16':
                ACCESS_TOKEN = '9fS266S1i66DtSL5n3HG'
            elif IP == '192.168.44.17':
                ACCESS_TOKEN = 'rLQrOa1THMac7cITvdSw'
            elif IP == '192.168.44.22':
                ACCESS_TOKEN = 'zd33Or3GAVzThQFdYwdh'
            elif IP == '192.168.44.23':
                ACCESS_TOKEN = 'NxC0nqjInXcpaL8SpNKa'
            elif IP == '192.168.44.24':
                ACCESS_TOKEN = 'OPiZ73svjd3ObecFBQ2F'
            elif IP == '192.168.44.25':
                ACCESS_TOKEN = 'RItIDgHoF5DxAlAqtVDo'
            elif IP == '192.168.44.26':
                ACCESS_TOKEN = 'BhFRe2NNNbTpx0GlXcvJ'
            elif IP == '192.168.44.27':
                ACCESS_TOKEN = '6iqflnSTrvkDYyE1LLaR'
            elif IP == '192.168.44.28':
                ACCESS_TOKEN = '9MaRO9eZ4kN3qdjDmmlp'
            elif IP == '192.168.44.29':
                ACCESS_TOKEN = 'BGTsHlZ0eLGz7nAPgeoi'
            elif IP == '192.168.44.30':
                ACCESS_TOKEN = 'uzcWdD5OvtyuSIbzVeXo'
            elif IP == '192.168.44.31':
                ACCESS_TOKEN = 'PYmzBNAeRk5L3ST9Mr0G'
            elif IP == '192.168.44.32':
                ACCESS_TOKEN = '2F292r2McVD75tNatGmb'
            else:
                ACCESS_TOKEN = 'TEST_SCRIPT_TOKEN'

            print(u"IP: {:s}, UP: {:g}, USERS: {:g}, DISKUSE: {:g}, READ: {:g}, WRITE: {:g}, MEMUSE: {:g}, CPUUSE: {:g}, TEMPCPU: {:g}\u00b0C".format(IP, UP, USERS, DISKUSE, READ, WRITE, MEMUSE, CPUUSE, TEMPCPU))

            computer_stat['IP']      = IP
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
            
	    # Erase TOKEN and connection information
	    client.reinitialise()

        # Change TOKEN
        client.username_pw_set(ACCESS_TOKEN)
            
        # Reconnect
	    client.connect(THINGSBOARD_HOST, 1883, 60)

        next_reading += INTERVAL
        sleep_time = next_reading-time.time()
        if sleep_time > 0:
            time.sleep(sleep_time)
except KeyboardInterrupt:
    pass

client.loop_stop()
client.disconnect()

