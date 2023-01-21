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

OLDLIVE=`readlink -f ${COOLSERV}/live`
OLDBILD=`readlink -f ${COOLSERV}/build`

if [[ -f ${OLDBILD}/daemon-in-the-dark ]]
then
    # Server has NOT had a round-end since the last time we built, is
    # still running from this directory, and is scratching 'No Kill I'
    # on the wall.

    # Swap directories so we're not stomping on the eggs^Wrunning
    # server.
    dirswap

    OLDLIVE=`readlink -f ${COOLSERV}/live`
    OLDBILD=`readlink -f ${COOLSERV}/build`
    if [[ -f ${OLDBILD}/daemon-in-the-dark ]]
    then
	# fuck *me* running, why are there two server lockfiles?
	exit 69
    fi
fi

echo "Building to ${OLDBILD}"

# Grab updated source
cd ${CODEBASE_DIR}
git pull --recurse-submodules &> ${COOLSERV}/buildlog.txt

if [ $? -ne 0 ]; then
   # Either the git pull, or the git merge, failed. *sad-trombone*
   # Sadly, that's all we know. :(
   # There's no documentation for what other error codes there are, or what they mean.
   exit 1
fi

# Change the build day & month, and all that, so we get nice snazzy holiday/event
# stuff. (e.g. Halloween, Xmas, etc.)

# match    V   this       V  & 1 or more nums - replace with matched bit in parens, plus the relevant day/month/hour/minute
sed -Ei "s/(BUILD_TIME_DAY) [[:digit:]]+/\1 `date +%-d`/" _std/__build.dm
sed -Ei "s/(BUILD_TIME_MONTH) [[:digit:]]+/\1 `date +%-m`/" _std/__build.dm
sed -Ei "s/(BUILD_TIME_HOUR) [[:digit:]]+/\1 `date +%-H`/" _std/__build.dm
sed -Ei "s/(BUILD_TIME_MINUTE) [[:digit:]]+/\1 `date +%-M`/" _std/__build.dm

# Build da sauce!
${BYOND_DIR}/bin/DreamMaker ${DMB_NAME} &> ${COOLSERV}/buildlog.txt

if [ $? -ne 0 ]; then
    # DreamMaker failed. Boo!
    exit 2
fi

# god, I'm getting sick of dealing with potential weird-ass race conditions.
# Try, one last goddamn time, to check ourselves before we wreck ourselves.
if [[ -f ${OLDBILD}/daemon-in-the-dark ]]
then
    exit 68
fi

# lockfile, stop the server from trying to do stuff with this dir.
touch ${OLDBILD}/coeding-sounds

# *shovelling sounds*
cp -r ${CODEBASE_DIR}/* ${OLDBILD}
cp ${BYOND_DIR}/server_conf/config.txt ${OLDBILD}/config/

# Oho ho ho
cd ${OLDBILD}/browserassets

# Mmhm!
npm install &> ${COOLSERV}/buildlog.txt
if [ $? -ne 0 ]; then
    # NPM! You fail us! >:C
    exit 3
fi

grunt build-cdn --servertype="main" &> ${COOLSERV}/buildlog.txt
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
zip -j ${OLDBILD}/${DMB_NAME}.rsc.zip ${OLDBILD}/${DMB_NAME}.rsc &> ${COOLSERV}/buildlog.txt
if [ $? -ne 0 ]; then
    # zip had an oopsie
    exit 5
fi

# Fire the assets down the tube to the cdn
rsync -avz --delete --exclude ".htaccess" --exclude ".ftpquota" \
      ${OLDBILD}/browserassets/build/ coolstation.space:~/cdn.coolstation.space/ &> ${COOLSERV}/buildlog.txt

if [ $? -ne 0 ]; then
    # rsync went wrong :(
    exit 6
fi

# And the resource file too
rsync -avz --delete --exclude ".htaccess" --exclude ".ftpquota" \
      ${OLDBILD}/coolstation.rsc.zip  coolstation.space:~/cdn.coolstation.space/ &> ${COOLSERV}/buildlog.txt

if [ $? -ne 0 ]; then
    # Nooooo... so close!
    exit 7
fi

# Clean up our lockfile
rm ${OLDBILD}/coeding-sounds

# Swap the directories so that the server will load our newly built code for the next round!
dirswap

# Clean up our mess.
rm ${COOLSERV}/buildlog.txt
