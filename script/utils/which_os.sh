#!/bin/bash

# detect on which system we are running (ubuntu or macos)
if [ -f /etc/os-release ]; then
  source /etc/os-release
  OS=$ID
  OS_NAME=$NAME
  OS_VERSION=$VERSION_ID
elif [ -f /usr/bin/sw_vers ]; then
  OS="macos"
  OS_NAME="Mac OS X"
  OS_VERSION=$(sw_vers -productVersion)
else
  script_error ${FUNCNAME[0]} ${LINENO} "Could not detect OS" 1
fi

SUPPORTED_OS=(ubuntu macos)

! [[ "${SUPPORTED_OS[*]}" =~ "$OS" ]] && error "OS not supported. Supported OS: ${SUPPORTED_OS[*]}"
