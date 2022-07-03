#!/bin/bash

# Printing functions

# Will print a custom message with the given color
message() {

	# Color variables
	local green='\e[0;32m'
	local blue='\e[0;34m'
	local yellow='\e[0;33m'
	local red='\e[0;31m'
	local cyan='\e[0;36m'
	local magenta='\e[0;35m'

	# Reset color
	local reset='\e[0m'

	if [ ! -z "${1// /}" ]; then
		case "$1" in
		-s | --success)
			printf "${green}%s${reset}\n" "$2"
			;;
		-i | --info)
			printf "${blue}%s${reset}\n" "$2"
			;;
		-w | --warning)
			printf "${yellow}%s${reset}\n" "$2"
			;;
		-e | --error)
			printf "${red}%s${reset}\n" "$2"
			;;
		-c | --cyan)
			printf "${cyan}%s${reset}\n" "$2"
			;;
		-m | --magenta)
			printf "${magenta}%s${reset}\n" "$2"
			;;
		*)
			printf "%s\n" "$1"
			;;
		esac
		shift $((OPTIND - 1))
	else
		trap 'echo -e "${red}Error:${reset} $*"' ERR
	fi
}

# Prints an error message and exits the script with an error code.
error() {
	# https://stackoverflow.com/a/185900/6751578
	local parent_function="$1"
	local parent_lineno="$2"
	local message="$3"
	local code="${4:-1}"
	if [[ -n "$message" ]]; then
		message -e "${parent_function} Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
	else
		message -e "${parent_function} Error on or near line ${parent_lineno}; exiting with status ${code}"
	fi
	exit "${code}"
}
