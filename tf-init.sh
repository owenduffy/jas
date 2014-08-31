#!/bin/bash
#script to set TNC to KISS mode
#2014-08-30 Owen Duffy

PORT=/dev/ttyUSB0

stty -F $PORT raw ispeed 9600 ospeed 9600 cs8 -ignpar -cstopb -echo

runscript /home/aprs/JAS/tf-init.scr <$PORT >$PORT 

