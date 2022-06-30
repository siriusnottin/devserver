#!/bin/bash

# =============================================================================
#                                 Server Setup 																#
# =============================================================================

# All the functions definitions for the server setup, divided by steps

source $SCRIPT_DIR/utils/package.sh

# Shares
# https://forums.unraid.net/topic/71600-unraid-vm-shares/?do=findComment&comment=658008
shares() {

	#############################################################################
	step "Shares"
	#############################################################################

	local credentials_file="/root/.cifs"
	printf "%s\n" "username=$VM_DOMAIN" "password=MWV.pcp*zxd@ujc2rge" | sudo tee $credentials_file >/dev/null || error ${FUNCNAME[0]} ${LINENO} "Could not write to $credentials_file" 1
	sudo chmod 600 $credentials_file || error ${FUNCNAME[0]} ${LINENO} "Could not change permissions on $credentials_file" 1

	apt_check cifs-utils

	read -e -p "Shares to mount: " -i "projects virtualbox" -a SHARES
	local edited=false
	message -i "Checking the shares..."
	for share in "${SHARES[@]}"; do

		# ----------- Share folder
		if [ ! -d "/mnt/$share" ]; then
			message -i "Creating mount point for $share"
			mkdir "/mnt/$share" || error ${FUNCNAME[0]} ${LINENO} "Could not create mount point for $share" 1
			edited=true
			message -s "Created mount point for $share"
		fi

		# ----------- Edit fstab
		local share_fstab="//$UNRAID_IP/$share	/mnt/$share	cifs	credentials=$credentials_file,rw,uid=nobody,gid=users,iocharset=utf8 0 0"

		add_share() {
			message -i "Adding $share to fstab"
			printf "%s\n" "$share_fstab" | sudo tee -a /etc/fstab >/dev/null || error ${FUNCNAME[0]} ${LINENO} "Could not add $share to fstab" 1
			edited=true
			message -s "$share added to fstab"
		}

		if grep -sq "$share" /etc/fstab; then
			if ! grep -sxq "$share_fstab" /etc/fstab; then
				# remove the line from the fstab
				message -w "Found exisiting $share share in fstab but it does not match the current configuration. Removing it..."
				sudo sed -i "/$share/d" /etc/fstab || error ${FUNCNAME[0]} ${LINENO} "Could not remove $share from fstab" 1
				add_share
				sudo umount "/mnt/$share" >/dev/null 2>&1
				edited=true
			fi
		else
			add_share
			edited=true
		fi

	done

	# ----------- Mount the shares
	for share in "${SHARES[@]}"; do
		if ! grep -qs "/$share " /proc/mounts; then # if share is not mounted
			message -i "Mounting the share $share"
			sudo mount "/mnt/$share" || error ${FUNCNAME[0]} ${LINENO} "Could not mount $share. Have you restarted the unraid server?" 1
			edited=true
			message -s "Mounted $share"
		fi
	done

	if [ "$edited" = false ]; then
		message -w "Shares already created and mounted. Skipping..."
	fi

}

projects() {

	#############################################################################
	step "Projects"
	#############################################################################

	message -i "Checking if projects folder exists..."
	if [ -d "/mnt/projects" ]; then
		message -w "Projects folder already exists. Skipping..."
	else
		message -i "Creating projects folder"
		mkdir "/$HOME/projects" || error ${FUNCNAME[0]} ${LINENO} "Could not create projects folder" 1
		message -s "Created projects folder"
	fi

}

# If multiple users
# for aditionnal security: https://code.visualstudio.com/docs/remote/troubleshooting#_improving-security-on-multi-user-servers
multiple_users() {

	#############################################################################
	step "Multiple users"
	#############################################################################

	printf "%s\n" "AllowStreamLocalForwarding yes" | sudo tee -a /etc/ssh/sshd_config
	systemctl restart sshd
}

update_software() {

	#############################################################################
	step "Software update"
	#############################################################################

	message -i "Updating the software"

	sudo apt-get update
	if ! $UPDATE; then
		sudo apt update
		sudo apt upgrade -y
	else
		sudo apt update
		sudo apt upgrade -y
		sudo apt dist-upgrade -y
		sudo apt autoremove -y
		sudo apt autoclean -y
		sudo apt clean -y
	fi

	if [ $? -eq 0 ]; then
		message -s "Software updated"
	else
		error ${FUNCNAME[0]} ${LINENO} "Could not update software" 1
	fi
}

default_shell() {

	#############################################################################
	step "Default shell"
	#############################################################################

	message -i "Checking the default shell"
	if [ "$SHELL" != "/usr/bin/zsh" ]; then

		apt_check zsh

		message -i "Changing default shell to zsh..."
		chsh -s /usr/bin/zsh
		message -s "Default shell changed"
		message -w "Please login again to apply changes (then restart the script to continue)"
		message -i "Exiting..."
		exit 0
	else
		message -w "Default shell is already zsh. Skipping..."
	fi
}

# Znap! (https://github.com/marlonrichert/zsh-snap#installation)
# See also: https://pablo.tools/blog/computers/znap-zsh-plugin-manager/
znap() {

	#############################################################################
	step "Znap!"
	#############################################################################

	if $UPDATE; then
		message -w "Please run the following command in the terminal:"
		message -c "znap pull"
		message -w "Then restart the script to continue"
		read -p "Press enter to continue..." -n1 -s
		sep
		return 0
	fi

	read -e -p "Znap path [~/.zsh-plugins]: " ZNAP_PATH
	ZNAP_PATH=${ZNAP_PATH:-"$HOME/.zsh-plugins"}
	message -i "Checking if Znap is already installed..."
	if [ ! -d "$ZNAP_PATH" ]; then
		message -i "Creating folder for Znap..."
		mkdir -p "$ZNAP_PATH"
		message -s "Folder for Znap created"
	fi
	if [ ! -d "$ZNAP_PATH/zsh-snap" ]; then
		message -i "Installing Znap..."
		git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git ${ZNAP_PATH}/zsh-snap
		message -s "Znap installed"
	else
		message -w "Znap is already installed. Skipping..."
	fi
}

zsh_config() {

	#############################################################################
	step "ZSH"
	#############################################################################

	create_zsh_config() {
		message -i "Creating zsh config file..."
		cp $DEVSERVER_DIR/.zshrc $HOME/.zshrc || error $LINENO "Failed to create zsh config file" 1
		message -s "zsh config file created"
		sep
		message -c "Please run 'source ~/.zshrc' to apply changes"
		sep
		message -i "Znap will be loaded automatically (including ohmyzsh and nvm)"
		sep
		message -w "After znap is loaded, you should always run 'znap restart' instead of sourceing the zsh config file directly!"
		sep
		message -i "Doing so could cause some issues or unexpected side effects"
		message -i "Read more about it here: https://github.com/marlonrichert/zsh-snap/blob/main/.zshrc"
		sep
		read -p "Press enter to continue..." -n1 -s
		# message -i "Applying zsh config file..."
		# source $HOME/.zshrc > /dev/null || error $LINENO "Failed to apply zsh config file" 1
		# message -s "zsh config file applied"
	}

	message -i "Checking if a zsh config file exists..."
	if [ -f "$HOME/.zshrc" ]; then
		# it's the same file, so we don't need to create it
		if cmp -s "$DEVSERVER_DIR/.zshrc" "$HOME/.zshrc"; then
			message -w "zsh config file already exists and is the same as the one in the repo. Skipping..."
		else # it's a different file, so we need to back it up and create the new one
			message -i "zsh config file already exists and is different from the one in the repo."
			message -i "Backing up .zshrc file..."
			BACKUP_FILE=".zshrc.before_devserversetup.$(date +%Y%m%d%H%M%S)"
			mv ${HOME}/.zshrc ${HOME}/${BACKUP_FILE}
			message -s "Your old zsh config file is now backed up! ($HOME/$BACKUP_FILE)"
			create_zsh_config
		fi
	else
		message -w "No zsh config file found."
		create_zsh_config
		sep
	fi
}

# Homebrew (https://brew.sh)
homebrew() {

	#############################################################################
	step "Homebrew"
	#############################################################################

	if [ "$UPDATE" = true ]; then
		message -i "Updating homebrew..."
		brew update >/dev/null || error $LINENO "Failed to update homebrew" 1
		message -s "Homebrew updated"

		message -i "Updating homebrew formulas and packages..."
		brew upgrade >/dev/null || error $LINENO "Failed to update homebrew formulas and packages" 1
		message -s "Homebrew formulas and packages updated"
		return 0
	fi

	message -i "Checking if Homebrew is already installed..."
	# https://stackoverflow.com/a/34389425/6751578
	if which brew >/dev/null; then
		message -w "Homebrew is already installed. Skipping..."
	else
		message -i "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error $LINENO "Failed to install homebrew" 1
		message -s "Homebrew installed"

		eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" >/dev/null || error $LINENO "Failed to set up shell environment" 1

		message -i "Installing Homebrew packages..."
		apt_check build-essential
		brew_check gcc
		message -s "Homebrew packages installed"
	fi
}

github() {

	#############################################################################
	step "GitHub"
	#############################################################################

	brew_check gh

	if [ "$UPDATE" = true ]; then
		exit 0
	fi

	message -i "Checking if you are already logged in to GitHub..."
	if gh auth status 2>&1 | grep -qi "You are not logged"; then
		printf "%s\n" "You are not logged into GitHub. Logging in..."
		gh auth login || error $LINENO "Failed to login to GitHub" 1
		message -s "Logged in to GitHub"
	else
		message -s "You are already logged into GitHub. Skipping..."
	fi

	message -i "Setting Git using the GitHub CLI"
	gh auth setup-git >/dev/null || error $LINENO "Failed to set Git using the GitHub CLI" 1
	message -s "Git set using the GitHub CLI"

}

git() {

	#############################################################################
	step "Git"
	#############################################################################

	# Default branch name
	read -e -p "Git branch name [main]: " GIT_BRANCH
	GIT_BRANCH=${GIT_BRANCH:-"main"}
	message -i "Setting default branch name..."
	git config --global init.defaultBranch "$GIT_BRANCH" && message -s "Default branch name set" || error $LINENO "Failed to set default branch name" 1

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
		git config --global user.name "$GIT_USER_NAME" || error $LINENO "Failed to set git user name" 1
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
			git config --global user.email $GIT_EMAIL || error $LINENO "Failed to set git email" 1
			message -s "Git email set. Skipping..."
		fi
	else
		message -w "Skipping GitHub email save"
	fi
}

trellis() {

	#############################################################################
	step "Trellis"
	#############################################################################

	# https://docs.roots.io/trellis/master/installation/#requirements)
	# https://docs.roots.io/trellis/master/python/#ubuntu
	message -i "Python"
	apt_check python3 python-is-python3 python3-pip
	message -s "Python installed"

	sep
	# https://github.com/roots/trellis-cli#quick-install-macos-and-linux-via-homebrew
	message -i "Trellis CLI"
	brew_check roots/tap/trellis-cli
	message -s "Trellis CLI installed"

	# https://virtualenv.pypa.io/en/latest/installation.html
	# https://gist.github.com/frfahim/73c0fad6350332cef7a653bcd762f08d
	sep
	message -i "Virtualenv"
	apt_check python3-pip python3-venv
	message -s "virtualenv installed"

	sep
	# VirtualBox (https://www.virtualbox.org/wiki/Linux_Downloads)
	# See also: https://linuxize.com/post/how-to-install-virtualbox-on-ubuntu-20-04/
	message -i "VirtualBox"
	apt_check virtualbox
	message -s "VirtualBox installed ($(vboxmanage --version))"
	message -i "Changing the default Virtualbox VM location"
	# vboxmanage list systemproperties | grep folder
	# vboxmanage setproperty machinefolder ${HOME}/virtualbox
	sep
	# Vagrant (https://www.vagrantup.com/downloads)
	message -i "Vagrant"
	apt_check vagrant
	message -s "Vagrant installed ($(vagrant -v))"
	message -i "Don't forget to run \"$SCRIPTNAME vagrant\" in your vagrant projects or anywhere else to successfully run vagrant"
}

nvm() {

	#############################################################################
	step "NVM"
	#############################################################################

	# NVM (https://github.com/nvm-sh/nvm#install--update-script)

	message -i "Checking if NVM is installed"
	if [ ! -d "$HOME/.nvm" ]; then
		message -w "NVM is not installed. Have you properly run the script?"
		message -w "Please, run the script again and wait for the \"znap restart\" instruction!"
	else
		message -w "NVM is already installed."

		if [ "$UPDATE" = true ]; then
			message -i "Updating NVM..."
			nvm upgrade || error $LINENO "Failed to update NVM" 1
			message -s "NVM Updated"
		fi

	fi
}

node() {

	#############################################################################
	step "Node"
	#############################################################################

	message -i "Checking if the latest stable Node version is installed..."
	if [ ! -d "$HOME/.nvm/versions/node/$(nvm version node)" ]; then
		message -i "The latest stable node version is not installed."
		message -i "Installing node $(nvm version node)"
		nvm install node
		message -s "Node $(nvm version node) installed"
	else
		message -w "Node is already installed. Skipping..."
	fi
}

additional_software() {

	#############################################################################
	step "Additional software"
	#############################################################################

	read -e -p "Additional software to install: " -i "tree neofetch progress" ADD_SOFTWARE
	apt_check ${ADD_SOFTWARE}
	message -s "Additional software installed"
}
