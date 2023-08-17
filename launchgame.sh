#!/bin/bash

LIVEDIR=/home/ss13/coolserv/live
LOCKFILE=${LIVEDIR}/daemon-in-the-dark

for t in {1..12}
do
    if [ -z "$(ps -C DreamDaemon | grep DreamDaemon)" ]
    then
	if [[ -f ${LIVEDIR}/coeding-sounds ]]
	then
	    # We should never get here, but this means we're trying to
	    # start in a directory that the build process is running
	    # on.
	    sleep 5
	    continue # skip to the next go-around
	fi

	# If this file exists, then DreamDaemon shuts down on world/Reboot(). It then requires
	# something external to start it back up again. Oh, hey, it us; the external something!
	touch ${LIVEDIR}/data/hard-reboot

	# If this file exists, the fusilli build script will not overwrite this directory.
	touch ${LOCKFILE}

	# Launch the game server in background.
	# Yes, I really actually meant in the background this time!
        /home/ss13/byond/bin/DreamDaemon "${LIVEDIR}/coolstation.dmb" 8085 -trusted &

	# Grab the background process' PID
	DD_PID=$!

	# Put the lime in the coconut
	echo ${DD_PID} > ${LOCKFILE}

	# A little delayed build action, maybe
	./delaybuild.sh ${DD_PID} &

	# Bring the server process back out of the background, and
	# wait for it to serve its time.
	wait ${DD_PID}

	# Clean up after ourselves, since we're not using this directory any more
	rm ${LOCKFILE}
    fi
    sleep 5
done
