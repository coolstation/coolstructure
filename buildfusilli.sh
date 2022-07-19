#!/bin/bash

CODEBASE_DIR="/home/ss13/coolstation"
DMB_NAME="coolstation"

BYOND_DIR="/home/ss13/byond"
COOLSERV="/home/ss13/coolserv"
DMB_DIR="${COOLSERV}/build"
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
cp -r ${CODEBASE_DIR}/* ${DMB_DIR}
cp ${BYOND_DIR}/server_conf/config.txt ${DMB_DIR}/config/

# Oho ho ho
cd ${DMB_DIR}/browserassets

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

zip ${DMB_DIR}/${DMB_NAME}.rsc.zip ${DMB_DIR}/${DMB_NAME}.rsc
if [ $? -ne 0 ]; then
    # zip had an oopsie
    exit 5
fi

# Fire the assets down the tube to the cdn
rsync -avz --delete --exclude ".htaccess" --exclude ".ftpquota" \
      ${DMB_DIR}/browserassets/build/ coolstation.space:~/cdn.coolstation.space/

if [ $? -ne 0 ]; then
    # rsync went wrong :(
    exit 6
fi

# And the resource file too
rsync -avz --delete --exclude ".htaccess" --exclude ".ftpquota" \
      ${DMB_DIR}/coolstation.rsc.zip  coolstation.space:~/cdn.coolstation.space/

if [ $? -ne 0 ]; then
    # Nooooo... so close!
    exit 7
fi


rm ${COOLSERV}/live
ln -s ${OLDBILD} ${COOLSERV}/live

rm ${COOLSERV}/build
ln -s ${OLDLIVE} ${COOLSERV}/build
