#!/bin/bash

# Checks if a brew formulae is installed, if not, install it
# https://apple.stackexchange.com/a/284381/342481
brew_check() {
	message -i "Checking if $1 is installed..."
	if brew list $1 &>/dev/null; then
		message -w "$1 is already installed. Skipping..."
	else
		message -w "$1 is not installed. Installing..."
		brew install "$1"
		message -s "$1 installed"
	fi
}

# Checks if a package is installed, if not, install it
apt_check() {
	for package in "$@"; do
		message -i "Checking if $package is installed..."
		if dpkg -s $package &>/dev/null; then
			message -w "$package is already installed. Skipping..."
		else
			message -w "$package is not installed. Installing..."
			sudo apt install $package -y -qq
			message -s "$package installed"
		fi
	done
}
