#!/bin/bash

for t in {1..12}
do
    if [ -z "$(ps -C DreamDaemon | grep DreamDaemon)" ]
    then
        /home/ss13/byond/bin/DreamDaemon /home/ss13/coolserv/live/coolstation.dmb 8085 -trusted &
    fi
    sleep 5
done
