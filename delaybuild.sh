#!/bin/bash

SCRIPTHOLE=/home/ss13/coolstructure

if [ -z $1 ]
then
    echo "no PID given" > /home/ss13/delay_status
    exit -1
fi
# First thing we do: Have a nap.
sleep 5m

# Check the game server is still alive.
if [[ -n "$(ps -q $1 -o comm=)" ]]
then
    # Server's still up, I guess! Launch the build script!
    echo "launching build script at ${SCRIPTHOLE}, from ${PWD}" > /home/ss13/delay_status
    ${SCRIPTHOLE}/buildfusilli.sh
else
    echo "`date --iso-8601=seconds` - Couldn't find DreamDaemon at $1: '$(ps -q $1 -o comm=)'." > /home/ss13/delay_status
fi
# Our work here is done.
rm /home/ss13/delay_status
