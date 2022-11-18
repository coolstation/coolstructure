#!/bin/bash

CODEBASE_DIR="/home/ss13/webfucker/git-repo"

# Grab updated source
cd ${CODEBASE_DIR}
git pull --recurse-submodules

if [ $? -ne 0 ]; then
   # Either the git pull, or the git merge, failed. *sad-trombone*
   # Sadly, that's all we know. :(
   # There's no documentation for what other error codes there are, or what they mean.
   exit 1
fi

# Fire the assets down the tube to the cdn
rsync -avz --delete --exclude ".htaccess" --exclude ".ftpquota" \
      ${CODEBASE_DIR}/ coolstation.space:~/www

if [ $? -ne 0 ]; then
    # rsync went wrong :(
    exit 2
fi

