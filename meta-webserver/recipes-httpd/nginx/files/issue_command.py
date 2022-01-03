#!/usr/bin/env python3

"""
send commands to python daemon through IPyC.
"""

import json
import sys

assert len(sys.argv) >= 2, "wrong syntax: call {sys.argv[0]} <comando> <param-0> [<param-1> <param-2> ...]"

############ ASYNCIO ################
import asyncio
from ipyc import AsyncIPyCClient

"""
convert from hex string to long(s)
and eventually split data when
number are too big (i.e. rfid 13 hex digits)
"""
## def convert_and_append(lst, numstr):
##     num = int(numstr, 16)
## 
##     nbytes = int((len(numstr) + 1) / 2) # number of bytes in input
##     nlongs = int((nbytes + 3) / 4)      # number of longs in input
##     fmt = 'L' * nlongs                  # format of data
## 
##     for i in range(nlongs):
##         lst.append(num & 0xffffffff)
##         num >>= 32

async def issue_command():
    client = AsyncIPyCClient()  # Create a client
    link = await client.connect()  # Connect to the host
    # command = dict(command_id=9000, command_param="")
    # command = dict(command_id=int(sys.argv[1]), command_param=int(sys.argv[2]))
    command_id=int(sys.argv[1])
    command_params = list()
    for par in sys.argv[2:]:
        # length = len(par) >> 1 # 2 chars are 1 byte
        # convert_and_append(command_params, par)
        # for i in range(length >> 2): # 
        command_params.append(int(par, 16))

    print(f"command_params={command_params}")

    command = dict(command_id=command_id, command_params=command_params)
    # print(type(command), command)
    await link.send(json.dumps(command), 'utf-8')  # Send a string
    response = await link.receive()
    print(f"response: {response}")
    # await link.send('{"command_id": 9000, "command_param":""}')
    await client.close()  # Close the connection

loop = asyncio.get_event_loop()
loop.run_until_complete(issue_command())

############ WHITOUT ASYNCIO ################

## from ipyc import IPyCClient, IPyCSerialization
## 
## command = dict(command_id=int(sys.argv[1]), command_params=list(map(int, sys.argv[2:])))
## command = json.dumps(command, ensure_ascii=False).encode('utf-8')
## print(type(command), command)
## custom_object = command # CustomObject(42, 3.1415926535897932, "Lorem ipsum dolor sit amet", {'s', 'e', 't'})
## # IPyCSerialization.add_custom_serialization(CustomObject, CustomObject.serialize)
## 
## client = IPyCClient()
## link = client.connect()
## link.send(custom_object, 'utf-8')
## response = link.receive()
## print(f"response: {response}")
## client.close()

