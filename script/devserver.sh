#!/bin/bash

# =============================================================================
#                                Main Script                                  #
# =============================================================================

SCRIPTNAME="$(basename $0)"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PARENT_SCRIPT_DIR=$(dirname $SCRIPT_DIR)

NETWORK_CONFIG_IP_RANGE="192.168.0.10-50" # or "192.168.0.1/24" to scan every ip in the subnet

# Loads the utilities functions
source $SCRIPT_DIR/utils/print/print.sh
source $SCRIPT_DIR/utils/print/print_sep.sh

UNRAID_NAME="Unraid Server"
UNRAID_DOMAIN="unraid"
UNRAID_IP="192.168.0.23"
UNRAID_HOSTS=("unraid" "licorne")

VM_NAME="Dev Server"
VM_DOMAIN="devserver"
VM_USERNAME="sirius"
VM_LAST_UPDATE="2022-06-09"

# detect on which system we are running (ubuntu or mac)
if [ -f /etc/os-release ]; then
	source /etc/os-release
	OS=$ID
	OS_NAME=$NAME
	OS_VERSION=$VERSION_ID
elif [ -f /usr/bin/sw_vers ]; then
	OS="mac"
	OS_NAME="Mac OS X"
	OS_VERSION=$(sw_vers -productVersion)
else
	script_error ${FUNCNAME[0]} ${LINENO} "Could not detect OS" 1
fi

! [[ $OS == "ubuntu" || $OS == "mac" ]] && error "Unsupported OS ($OS_NAME). Only Ubuntu and Mac OS X are supported." 1

# Checks the args
if [ $# -eq 0 ]; then
	error "No arguments supplied!"
	sep
	source $SCRIPT_DIR/actions/print_help.sh >&2
	exit 1
fi

# Process the args
while [ $# -gt 0 ]; do
	case $1 in
	vm)
		source $SCRIPT_DIR/actions/vm.sh
		break
		;;
	setup | update)
		source $SCRIPT_DIR/actions/server_setup.sh
		break
		;;
	local)
		source $SCRIPT_DIR/actions/local_setup.sh
		break
		;;
	steps)
		source $SCRIPT_DIR/actions/print_steps.sh
		break
		;;
	vagrant)
		source $SCRIPT_DIR/actions/vagrant.sh
		break
		;;
	h | help | -h | --help)
		source $SCRIPT_DIR/actions/print_help.sh
		break
		;;
	*)
		error "Unknown command: $1" 1
		;;
	esac
	shift
done
