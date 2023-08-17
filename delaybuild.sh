#!/bin/bash

if [ -z $1 ]
then
    exit -1
fi
# First thing we do: Have a nap.
sleep 5m

# Check the game server is still alive.
if [[ "$(ps -q $1 -o comm=)" == "DreamDaemon" ]]
then
    # Server's still up, I guess! Launch the build script!
    ./buildfusilli.sh
fi

# Our work here is done.
