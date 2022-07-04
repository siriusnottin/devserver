#!/bin/bash

install_app() {

	# Checks if a application is installed depending on the os, if it is not installed it will install it
	# Usage: install_app macos|ubuntu|brew [--cask] <app1> <app2> ...
	# @param $1 the os: ubuntu, macos or brew
	# @param $2 optional, if you want to specify to brew the --cask flag
	# @param $3 the package name, can be multiple packages separated by spaces

	# Available OS are: ubuntu (uses apt install) and macos (uses brew install)
	# to install a brew package on both ubuntu and macos you can set the os to brew.
	# The cask flag is not needed, but preferred for good performance and readability.

	local install_os="$1"
	[[ $2 == "--cask" ]] && local install_cask=true && shift
	shift

	for app in "$@"; do

		case $OS in
		macos | ubuntu)
			[[ $OS != $install_os ]] && error "Can't install $app on $OS." 1
			;;
		esac

		case $install_os in
		ubuntu)
			[ $cask ] && error "Can't install cask packages on ubuntu. Did you mean to install it on mac?" 1

			is_installed="dpkg -s $app | grep -c \"Status: install ok installed\""
			[[ $1 == "--no-install-recommends" ]] && local norec="$1" && shift

			install_cmd="sudo apt-get install $app -y -qq"
			[ -n "$norec" ] && install_cmd+=" $norec"
			;;
		macos | brew)
			is_installed="brew list"
			[ $cask ] && is_installed+=" --casks"
			is_installed+=" | grep -c $app"

			install_cmd="brew install"
			[ $cask ] && install_cmd+=" --cask"
			install_cmd+=" $app"
			;;
		*)
			error "Unsupported OS ($install_os). Available options: ubuntu, mac, or brew"
			;;
		esac
		shift

		message -i "Checking if $app is installed..."
		# Todo: sanitize eval before using it
		if eval "$is_installed $app" &>/dev/null; then
			message -w "$app is already installed. Skipping..."
		else
			message -w "$app is not installed. Installing..."
			eval $install_cmd
			message -s "$app installed"
		fi

	done

}
