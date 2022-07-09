#!/bin/bash

source $SCRIPT_DIR/utils/which_os.sh # Will exit if OS is not supported

# local setup
[[ ! -d ~/.devserver ]] && ln -s ~/.devserver/script/devserver.sh /usr/local/bin/devserver
devserver setup local

# server setup
ssh devserver -t "git clone https://github.com/siriusnottin/devserver.git ~/.devserver && sudo ln -s ~/.devserver/script/devserver.sh /usr/local/bin/devserver"
