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
