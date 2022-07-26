#!/bin/bash

CODEBASE_DIR="/home/ss13/coolstation"
DMB_NAME="coolstation"

BYOND_DIR="/home/ss13/byond"
COOLSERV="/home/ss13/coolserv"

function dirswap {
    # Pointer to live is updated to the last build, so the server will
    # load the freshly-built code the next time it starts up.
    rm ${COOLSERV}/live
    ln -s ${OLDBILD} ${COOLSERV}/live

    # And the pointer to the build directory is updated to the other
    # dir.
    rm ${COOLSERV}/build
    ln -s ${OLDLIVE} ${COOLSERV}/build
}

if [[ -f ${COOLSERV}/build/daemon-in-the-dark ]]
then
    # Server has NOT had a round-end since the last time we built, is
    # still running from this directory, and is scratching 'No Kill I'
    # on the wall.

    # Swap directories so we're not stomping on the eggs^Wrunning
    # server.
    dirswap
fi

OLDLIVE=`readlink -f ${COOLSERV}/live`
OLDBILD=`readlink -f ${COOLSERV}/build`
echo "Building to ${OLDBILD}"

# Grab updated source
cd ${CODEBASE_DIR}
git pull --recurse-submodules

if [ $? -ne 0 ]; then
   # Either the git pull, or the git merge, failed. *sad-trombone*
   # Sadly, that's all we know. :(
   # There's no documentation for what other error codes there are, or what they mean.
   exit 1
fi

# Build da sauce!
${BYOND_DIR}/bin/DreamMaker ${DMB_NAME}

if [ $? -ne 0 ]; then
    # DreamMaker failed. Boo!
    exit 2
fi

# *shovelling sounds*
cp -r ${CODEBASE_DIR}/* ${OLDBILD}
cp ${BYOND_DIR}/server_conf/config.txt ${OLDBILD}/config/

# Oho ho ho
cd ${OLDBILD}/browserassets

# Mmhm!
npm install
if [ $? -ne 0 ]; then
    # NPM! You fail us! >:C
    exit 3
fi

grunt build-cdn --servertype="main"
if [ $? -ne 0 ]; then
    # Grunt had a whoopsie
    # 1: Fatal error
    # 2: Missing gruntfile
    # 3: Task error
    # 4: Template processing error
    # 5: Invalid shell auto-completion rules error
    # 6: Warning
    exit 4
fi

# Create a zip file of the rsc with the same name in the same directory, discard paths
zip -j ${OLDBILD}/${DMB_NAME}.rsc.zip ${OLDBILD}/${DMB_NAME}.rsc
if [ $? -ne 0 ]; then
    # zip had an oopsie
    exit 5
fi

# Fire the assets down the tube to the cdn
rsync -avz --delete --exclude ".htaccess" --exclude ".ftpquota" \
      ${OLDBILD}/browserassets/build/ coolstation.space:~/cdn.coolstation.space/

if [ $? -ne 0 ]; then
    # rsync went wrong :(
    exit 6
fi

# And the resource file too
rsync -avz --delete --exclude ".htaccess" --exclude ".ftpquota" \
      ${OLDBILD}/coolstation.rsc.zip  coolstation.space:~/cdn.coolstation.space/

if [ $? -ne 0 ]; then
    # Nooooo... so close!
    exit 7
fi

# Swap the directories so that the server will load our newly built code for the next round!
dirswap
