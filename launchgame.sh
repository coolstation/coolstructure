#!/bin/bash

LIVEDIR=/home/ss13/coolserv/live

for t in {1..12}
do
    if [ -z "$(ps -C DreamDaemon | grep DreamDaemon)" ]
    then
	# If this file exists, then DreamDaemon shuts down on world/Reboot(). It then requires
	# something external to start it back up again. Oh, hey, it us; the external something!
	touch ${LIVEDIR}/data/hard-reboot
        /home/ss13/byond/bin/DreamDaemon "${LIVEDIR}/coolstation.dmb" 8085 -trusted &
    fi
    sleep 5
done
