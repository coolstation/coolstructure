#!/bin/bash

SCRIPTHOLE=/home/ss13/coolstructure

if [ -z $1 ]
then
    exit -1
fi
# First thing we do: Have a nap.
sleep 5m

# Check the game server is still alive.
if [[ -n "$(ps -q $1 -o comm=)" ]]
then
    # Server's still up, I guess! Launch the build script!
    $(SCRIPTHOLE)/buildfusilli.sh
else
    echo "`date --iso-8601=seconds` - Couldn't find DreamDaemon at $1: '$(ps -q $1 -o comm=)'." > $(SCRIPTHOLE)/delay_fail
fi

# Our work here is done.
