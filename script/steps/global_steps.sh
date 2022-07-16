#!/bin/bash

# =============================================================================
#                                 Server Setup 																#
# =============================================================================

# All the functions definitions for the server setup, divided by steps

step_projects() {

	#############################################################################
	step "Projects"
	#############################################################################

	message -i "Checking if projects folder exists..."
	if [ -d "$HOME/projects" ]; then
		message -w "Projects folder already exists. Skipping..."
	else
		message -i "Creating projects folder"
		mkdir "/$HOME/projects" || script_error ${FUNCNAME[0]} ${LINENO} "Could not create projects folder" 1
		message -s "Created projects folder"
	fi

}

step_update_softwares() {
	message -i "Updating softwares..."
	case $OS in
	ubuntu)
		sudo apt update || script_error ${FUNCNAME[0]} ${LINENO} "Could not update softwares" 1
		sudo apt upgrade -y || script_error ${FUNCNAME[0]} ${LINENO} "Could not upgrade softwares" 1
		;;
	macos)
		sudo softwareupdate -i -r || script_error ${FUNCNAME[0]} ${LINENO} "Could not update softwares" 1
		;;
	esac
	brew update || script_error ${FUNCNAME[0]} ${LINENO} "Could not update brew softwares" 1
	brew upgrade || script_error ${FUNCNAME[0]} ${LINENO} "Could not upgrade brew softwares" 1
	message -s "Softwares updated"
}

step_update_softwares_cleanup() {

	#############################################################################
	step "Software update"
	#############################################################################

	step_update_software
	message -i "Cleaning up..."
	case $OS in
	ubuntu)
		sudo apt dist-upgrade -y
		sudo apt autoremove -y
		sudo apt autoclean -y
		sudo apt clean -y
		[[ $? -ne 0 ]] && script_error ${FUNCNAME[0]} ${LINENO} "Could not clean up" 1
		;;
	macos)
		brew cleanup || script_error ${FUNCNAME[0]} ${LINENO} "Could not cleanup" 1
		sudo softwareupdate -i -a || script_error ${FUNCNAME[0]} ${LINENO} "Could not update all softwares" 1
		;;
	esac

	message -s "Software updated"
	message -w "Rebooting now..."
	script_log_step_execution_now
	sudo shutdown -r now

}

step_default_shell() {

	#############################################################################
	step "Default shell"
	#############################################################################

	message -i "Checking the default shell"
	if [ "$SHELL" != "/usr/bin/zsh" ]; then

		install_app $OS zsh

		message -i "Changing default shell to zsh..."
		chsh -s $(which zsh) || script_error ${FUNCNAME[0]} ${LINENO} "Could not change default shell to zsh" 1
		message -s "Default shell changed"
		message -i "Starting zsh..."
		script_log_step_execution_now
		exec zsh -l "source $HOME/.zshrc"
	else
		message -w "Default shell is already zsh. Skipping..."
	fi
}

step_znap() {

	#############################################################################
	step "Znap!"
	#############################################################################

	# https://github.com/marlonrichert/zsh-snap#installation
	# See also: https://pablo.tools/blog/computers/znap-zsh-plugin-manager/

	if [[ $action == "update" ]]; then
		message -i "To update Znap! Execute the following command:"
		sep
		message -c "znap pull"
		sep
		read -p "Press enter to continue..." -n1 -s
		script_log_step_execution_now
		exit 0
	fi

	read -e -p "Znap folder [~/.zsh-plugins]: " ZNAP_PARENT_FOLDER
	ZNAP_PARENT_FOLDER="${ZNAP_PARENT_FOLDER/#\~/$HOME}"
	ZNAP_PARENT_FOLDER=${ZNAP_PARENT_FOLDER:-"$HOME/.zsh-plugins"}
	message -i "Checking if Znap is already installed..."
	if [ ! -d "$ZNAP_PARENT_FOLDER" ]; then
		message -i "Creating folder for Znap..."
		mkdir -p "$ZNAP_PARENT_FOLDER"
		message -s "Folder for Znap created"
	fi

	ZNAP_PATH="$ZNAP_PARENT_FOLDER/zsh-snap"
	if [ ! -d "$ZNAP_PATH" ]; then
		message -i "Installing Znap..."
		git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git $ZNAP_PATH || script_error ${FUNCNAME[0]} ${LINENO} "Could not install Znap" 1
		message -s "Znap installed"

		message -i "Reloading zsh..."
		script_log_step_execution_now
		exec zsh -l "source $HOME/.zshrc"
	else
		message -w "Znap is already installed. Skipping..."
	fi
}

step_zsh_config() {

	#############################################################################
	step "ZSH"
	#############################################################################

	create_zsh_config() {
		message -i "Creating zsh config file..."
		cp $PARENT_SCRIPT_DIR/.zshrc-$OS $HOME/.zshrc || script_error ${FUNCNAME[0]} $LINENO "Failed to create zsh config file" 1
		message -s "zsh config file created"
		sep
		message -c "Please wait for zsh to reload..."
		sep
		message -i "Znap will be loaded automatically (including ohmyzsh and nvm)"
		sep
		message -w "After that, you should always run 'znap restart' instead of sourceing the zsh config file directly!"
		sep
		message -i "Doing so could cause some issues or unexpected side effects"
		message -i "Read more about it here: https://github.com/marlonrichert/zsh-snap/blob/main/.zshrc"
		sep
		read -p "Press enter to continue..." -n1 -s
		message -i "Applying zsh config file..."
		script_log_step_execution_now
		source $HOME/.zshrc >/dev/null || error ${FUNCNAME[0]} $LINENO "Failed to apply zsh config file" 1
		message -s "zsh config file applied"
	}

	message -i "Checking if a zsh config file exists..."
	if [ -f "$HOME/.zshrc" ]; then
		# it's the same file, so we don't need to create it
		if cmp -s "$PARENT_SCRIPT_DIR/.zshrc-$OS" "$HOME/.zshrc"; then
			message -w "zsh config file already exists and is the same as the one in the repo. Skipping..."
		else # it's a different file, so we need to back it up and create the new one
			message -i "zsh config file already exists and is different from the one in the repo."
			message -i "Backing up .zshrc file..."
			BACKUP_FILE=".zshrc.before_devserver.$(date +%Y%m%d%H%M%S)"
			mv ${HOME}/.zshrc ${HOME}/${BACKUP_FILE} || script_error ${FUNCNAME[0]} $LINENO "Failed to backup .zshrc file" 1
			message -s "Your old zsh config file is now backed up! ($HOME/$BACKUP_FILE)"
			create_zsh_config
		fi
	else
		message -w "No zsh config file found."
		create_zsh_config
		sep
	fi
}

step_homebrew() {

	#############################################################################
	step "Homebrew" # (https://brew.sh)
	#############################################################################

	script_log_step_execution_now

	if [[ $action == "update" ]]; then
		message -i "Updating homebrew..."
		brew update >/dev/null || script_error ${FUNCNAME[0]} $LINENO "Failed to update homebrew" 1
		message -s "Homebrew updated"

		message -i "Updating homebrew formulas and packages..."
		brew upgrade >/dev/null || script_error ${FUNCNAME[0]} $LINENO "Failed to update homebrew formulas and packages" 1
		message -s "Homebrew formulas and packages updated"
		return 0
	fi

	message -i "Checking if Homebrew is already installed..."
	# https://stackoverflow.com/a/34389425/6751578
	if which brew >/dev/null; then
		message -w "Homebrew is already installed. Skipping..."
	else
		message -i "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || script_error ${FUNCNAME[0]} $LINENO "Failed to install homebrew" 1
		message -s "Homebrew installed"

		case $OS in
		macos)
			znap eval brew-shellenv 'brew shellenv'
			;;
		linux)
			znap eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" >/dev/null
			;;
		esac

		message -i "Installing Homebrew packages..."
		install_app ubuntu build-essential
		install_app macos gcc
		message -s "Homebrew packages installed"
	fi
}

step_github() {

	#############################################################################
	step "GitHub"
	#############################################################################

	install_app brew gh

	message -i "Checking if you are already logged in to GitHub..."
	if gh auth status 2>&1 | grep -qi "You are not logged"; then
		printf "%s\n" "You are not logged into GitHub. Logging in..."
		gh auth login || script_error ${FUNCNAME[0]} $LINENO "Failed to login to GitHub" 1
		message -s "Logged in to GitHub"
	else
		message -s "You are already logged into GitHub. Skipping..."
	fi

	message -i "Setting Git using the GitHub CLI"
	gh auth setup-git >/dev/null || script_error ${FUNCNAME[0]} $LINENO "Failed to set Git using the GitHub CLI" 1
	message -s "Git set using the GitHub CLI"

}

step_git() {

	#############################################################################
	step "Git"
	#############################################################################

	# Default branch name
	read -e -p "Git branch name [main]: " GIT_BRANCH
	GIT_BRANCH=${GIT_BRANCH:-"main"}
	message -i "Setting default branch name..."
	git config --global init.defaultBranch "$GIT_BRANCH" || script_error ${FUNCNAME[0]} $LINENO "Failed to set default branch name" 1
	message -s "Default branch name set"

	# User name
	get_user_full_name() {
		if git config --global --get user.name; then
			return 0
		elif getent passwd "$(whoami)" | cut -d ':' -f 5; then
			return 0
		fi
	}

	read -e -p "Git user name: " -i "$(get_user_full_name)" GIT_USER_NAME

	if [[ $(git config --global --get user.name) = "$GIT_USER_NAME" ]]; then
		message -w "Git user name already set. Skipping..."
	else
		message -i "Setting up git user name"
		git config --global user.name "$GIT_USER_NAME" || script_error ${FUNCNAME[0]} $LINENO "Failed to set git user name" 1
		message -s "Git user name set"
	fi

	# Email
	message -i "Go to https://github.com/settings/emails and copy your email address you wanna use for git"
	read -e -p "Git default email: " -i "$(git config --global --get user.email)" GIT_EMAIL
	read -e -p "Do you want to save it to your global git configuration? (y/N)" -n 1 -r -s REPLY
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		if [[ $(git config --global --get user.email) = "$GIT_EMAIL" ]]; then
			message -i "Git email already set. Skipping..."
		else
			message -i "Setting git email..."
			git config --global user.email $GIT_EMAIL || script_error ${FUNCNAME[0]} $LINENO "Failed to set git email" 1
			message -s "Git email set."
		fi
	else
		message -w "Skipping GitHub email save"
	fi
}

step_trellis() {

	#############################################################################
	step "Trellis"
	#############################################################################

	# https://docs.roots.io/trellis/master/installation/#requirements)

	sep
	# https://github.com/roots/trellis-cli#quick-install-macos-and-linux-via-homebrew
	message -i "Trellis CLI"
	install_app brew roots/tap/trellis-cli
	message -s "Trellis CLI installed"

	# https://virtualenv.pypa.io/en/latest/installation.html
	# https://gist.github.com/frfahim/73c0fad6350332cef7a653bcd762f08d
	sep
	message -i "Virtualenv"
	install_app ubuntu python3-venv || install_app macos pyenv
	message -s "virtualenv installed"

	sep
	# https://docs.roots.io/trellis/master/python/#ubuntu
	message -i "Python"
	install_app ubuntu python3 python-is-python3 python3-pip
	if [[ $OS == "macos" ]]; then
		pyenv global $(pyenv install --list | head -n 1) || script_error ${FUNCNAME[0]} $LINENO "Failed to set pyenv global" 1
		pyenv rehash || script_error ${FUNCNAME[0]} $LINENO "Failed to rehash pyenv" 1
		python3 -m ensurepip || script_error ${FUNCNAME[0]} $LINENO "Failed to install python3 pip" 1
	fi
	message -s "Python installed"

	sep
	# VirtualBox (https://www.virtualbox.org/wiki/Linux_Downloads)
	# See also: https://linuxize.com/post/how-to-install-virtualbox-on-ubuntu-20-04/
	message -i "VirtualBox"
	install_app brew virtualbox
	message -s "VirtualBox installed ($(vboxmanage --version))"
	message -i "Changing the default Virtualbox VM location"
	# vboxmanage list systemproperties | grep folder
	# vboxmanage setproperty machinefolder ${HOME}/virtualbox
	sep
	# Vagrant (https://www.vagrantup.com/downloads)
	message -i "Vagrant"
	install_app brew vagrant && install_app ubuntu ruby-dev
	message -s "Vagrant installed ($(vagrant -v))"
	message -i "Don't forget to run \"$SCRIPTNAME vagrant\" in your vagrant projects or anywhere else to successfully run vagrant"
}

step_ngrok() {

	#############################################################################
	step "ngrok"
	#############################################################################

	if [[ $OS == "ubuntu" ]]; then
		curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
		echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
		sudo apt update
		install_app ubuntu ngrok
		exit 0
	fi
	install_app macos ngrok/ngrok/ngrok
	message -i "Configuring ngrok..."
	ngrok config add-authtoken $NGROK_TOKEN || script_error ${FUNCNAME[0]} $LINENO "Failed to configure ngrok" 1
	message -s "ngrok configured"
}

step_composer() {

	#############################################################################
	step "Composer"
	#############################################################################

	# https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
	composer_install_script() {
		local EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
		php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
		local ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

		if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
			rm composer-setup.php
			error ${FUNCNAME[0]} $LINENO "Invalid installer checksum" 1
		fi

		php composer-setup.php --quiet
		RESULT=$?
		rm composer-setup.php
		sudo mv composer.phar /usr/local/bin/composer
		return $RESULT
	}
	message -i "Installing Composer..."
	composer_install_script || script_error ${FUNCNAME[0]} $LINENO "Failed to install Composer" 1
	message -s "Composer installed"
}

step_nvm() {

	#############################################################################
	step "NVM"
	#############################################################################

	# NVM (https://github.com/nvm-sh/nvm#install--update-script)
	if [[ $action = "update" ]]; then
		message -i "To update nvm, run the following command:"
		sep
		message -i "nvm upgrade"
		sep
		read -p "Press enter to continue..." -n1 -s
		script_log_step_execution_now
		exit 0
	fi

	message -i "Checking if NVM is installed"
	if [[ $(command -v nvm) = "nvm" ]]; then
		message -w "NVM is not installed. It shoudl have been installed automatically by zsh-nvm."
		step_znap
		script_log_step_execution_now
		exec zsh -l "source $HOME/.zshrc"
		step_nvm
	else
		message -w "NVM is already installed."
	fi
}

step_node() {

	source $NVM_DIR/nvm.sh

	#############################################################################
	step "Node [$(nvm version node)]"
	#############################################################################

	script_log_step_execution_now

	message -i "Checking if the latest stable version of Node (LTS) is installed..."
	if [ ! -d "$HOME/.nvm/versions/node/$(nvm version node)" ]; then
		message -i "The latest stable node version is not installed."
		message -i "Installing node $(nvm version node)"
		nvm install node
		message -s "Node $(nvm version node) installed"
	else
		message -w "Node is already installed and up to date."
	fi
}

step_yarn() {

	#############################################################################
	step "Yarn"
	#############################################################################

	message -i "Installing Yarn..."
	npm install -g yarn
	message -s "Yarn installed"
}

step_additional_software() {

	#############################################################################
	step "Additional software"
	#############################################################################

	read -e -p "Additional software to install: " -i "tree neofetch progress gsed" ADD_SOFTWARE
	install_app $OS ${ADD_SOFTWARE}
	message -s "Additional software installed"
}
