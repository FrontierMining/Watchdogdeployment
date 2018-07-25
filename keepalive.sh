#!/bin/bash

## REQUIRED packages: socat (apt-get install socat)

## If you are using OTHER unix system than SimpleMiningOS then you can manualy set values here:
srrEnabled="1"
srrSerial="000693"
slot="1"
ebSerial="100179" # if rig is connected to Extension Board then write here EB serial, if not then leave ebSerial=""
## Also please comment out values below that are usied only in simplemining OS.

if [ "$srrEnabled" -eq 1  ]; then
    echo "SRR Agent is ENABLED. Sending keepallive messages in order not to be killed by SRR."
else
    echo "SRR Agent is DISABLED so this script will exit in 120 seconds"
    sleep 120
    exit
fi


if [ ${#ebSerial} == 6 ]; then
    ## For Extension Board ports only
    ebSlot=`printf %02X $(( ${slot} - 1 ))`
    firstByte="FF"
    byteCount="000b"
    action="5c"
    mac="485053$srrSerial"
    checksum=`printf %02X $(( (0x${byteCount:0:2} + 0x${byteCount:2:2} + 0x$action + 0x${mac:0:2} + 0x${mac:2:2} + 0x${mac:4:2} + 0x${mac:6:2} + 0x${mac:8:2} + 0x${mac:10:2} + 0x${ebSerial:0:2} + 0x${ebSerial:2:2} + 0x${ebSerial:4:2} + 0x$ebSlot)%0x100  ))`
    packet2="$firstByte$byteCount$action$mac$ebSerial$ebSlot$checksum"

    while true
    do
        echo "Sending keepallive packet to EB:$ebSerial attached to SRR:$srrSerial on slot:$slot. Message:$packet2"
        echo -n "$packet2" | xxd -r -p |socat - UDP-DATAGRAM:255.255.255.255:1051,broadcast > /dev/null &
        sleep 2
    done

else
    ## For SRR ports only
    srrSlot=`printf %02X $(( ${slot} - 1 ))`
    firstByte="FF"
    byteCount="0008"
    action="55"
    mac="485053$srrSerial"
    checksum=`printf %02X $(( (0x${byteCount:0:2} + 0x${byteCount:2:2} + 0x$action + 0x${mac:0:2} + 0x${mac:2:2} + 0x${mac:4:2} + 0x${mac:6:2} + 0x${mac:8:2} + 0x${mac:10:2} + 0x$srrSlot)%0x100  ))`
    packet1="$firstByte$byteCount$action$mac$srrSlot$checksum"

    while true
    do
        echo "Sending keepallive packet to SRR:$srrSerial on slot:$slot. Message: $packet1"
        echo -n "$packet1" | xxd -r -p |socat - UDP-DATAGRAM:255.255.255.255:1051,broadcast > /dev/null &
        sleep 2
    done

fi
