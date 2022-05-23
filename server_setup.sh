#!/bin/bash

# =============================================================================
# Utility functions
# =============================================================================

# Coloring functions
success() {
  # Will print in green
  echo -e "\e[32m$1\e[0m"
}
info () {
  # Will print in magenta color
  echo -e "\e[35m$1\e[0m"
}
warning() {
  # Will print in cyan color
  echo -e "\e[36m$1\e[0m"
}

step () {
  # Will print a step of the installation
  echo "=============================================================================="
  info "$1"
  echo "=============================================================================="
}

brew_check() {
  # Checks if a brew formulae is installed, if not, install it
  # https://apple.stackexchange.com/a/284381/342481
  info "Checking if $1 is installed"
  if brew list $1 &>/dev/null; then
    warning "$1 is already installed. Skipping..."
  else
    warning "$1 is not installed. Installing..."
    brew install $1
    success "$1 installed"
  fi
}

# ==============================================================================
# Shares
# See: https://forums.unraid.net/topic/71600-unraid-vm-shares/?do=findComment&comment=658008
# ==============================================================================

step "Shares"

read -e -p "Share name to mount: " -i "projects virtualbox" -a SHARES_NAME
info "Checking if share is already mounted..."
for share in "${SHARES_NAME[@]}"
do
  if [ ! -d "${HOME}/${share}" ]; then
    info "Creating mount point for ${share}"
    mkdir ${HOME}/${share}
    success "Created mount point for ${share}"
  fi

  if ! grep -qs "/${share}" /etc/fstab; then
    info "Adding ${share} to fstab"
    echo -e "//192.168.0.23/${share}	${HOME}/${share}	cifs	credentials=/home/sirius/.smb_credentials,auto,user,uid=$(id -u),gid=$(id -g),forceuid,forcegid,exec,rw,sync,atime	0 0" | sudo tee -a /etc/fstab
    success "$share added to fstab"
  fi

  if ! grep -q "/${share} " /proc/mounts; then
    info "Mounting the share ${share}"
    sudo mount ${share}
    success "Mounted ${share}"
  fi
done

success "Shares mounted"

# If multiple users
# and for aditionnal security: https://code.visualstudio.com/docs/remote/troubleshooting#_improving-security-on-multi-user-servers
# echo "AllowStreamLocalForwarding yes" | sudo tee -a /etc/ssh/sshd_config
# systemctl restart sshd

# ==============================================================================
# Software update
# ==============================================================================
step "Updating software"
sudo apt update && sudo apt upgrade -y
success "Software updated"

# ==============================================================================
# Shell
# ==============================================================================
step "Default shell"

if [ "$SHELL" != "/usr/bin/zsh" ]; then
  info "Installing zsh..."
  sudo apt install -y zsh
  success "Installed zsh"
  
  info "Changing default shell to zsh..."
  chsh -s /usr/bin/zsh
  success "Default shell changed"
  warning "Please login again to apply changes (then restart the script to continue)"
  info "Exiting..."
  exit 0
  else
    warning "Default shell is already zsh. Skipping..."
fi

# ==============================================================================
# Znap! (https://github.com/marlonrichert/zsh-snap#installation)
# See also: https://pablo.tools/blog/computers/znap-zsh-plugin-manager/
# ==============================================================================

step "Znap!"

read -e -p "Znap path: " -i "/.zsh-plugins" ZNAP_PATH
info "Checking if Znap is already installed..."
if [ ! -d "$HOME/${ZNAP_PATH}" ]; then
  info "Creating folder for Znap..."
  mkdir -p "$HOME/${ZNAP_PATH}"
  success "Folder for Znap created"
fi
if [ ! -d "$HOME/${ZNAP_PATH}/zsh-snap" ]; then
    info "Installing Znap..."
    git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git $HOME/${ZNAP_PATH}/zsh-snap
    success "Znap installed"
else
  warning "Znap is already installed. Skipping..."
fi

info "Checking if a zsh config file exists..."
create_zsh_config() {
  info "Creating zsh config file..."
  cp .zshrc $HOME/.zshrc
  success "zsh config file created"
  info "Applying zsh config file..."
  source $HOME/.zshrc
  success "zsh config file applied"
}
if [ -f "$HOME/.zshrc" ]; then
  # it's the same file, so we don't need to create it
  if cmp -s ".zshrc" "$HOME/.zshrc"; then
      warning "zsh config file already exists and is the same as the one in the repo. Skipping..."
  else # it's a different file, so we need to back it up and create the new one
    info "zsh config file already exists and is different from the one in the repo."
    info "Backing up .zshrc file..."
    BACKUP_FILE=".zshrc.devserversetup.bk.$(date +%Y%m%d%H%M%S)"
    mv $HOME/.zshrc $HOME/${BACKUP_FILE}
    success "Your old zsh config file is now backed up ($HOME/${BACKUP_FILE})"
    create_zsh_config
  fi
  # Todo: Fix this!
  # info "Reloading zsh..."
  # znap restart
  # success "Reloaded zsh"
  info "Please restart your shell now using \"znap restart\""
  read -e -p "Already done? [Y/n]" -n 1 -s -r REPLY
  # if [[ $REPLY =~ ^[nN]$ ]]; then
    
  # fi

else
  warning "No zsh config file found."
  create_zsh_config
fi

# echo "zstyle ':omz:update' mode reminder" >> ~/.zshrc

# ==============================================================================
# Homebrew
# https://brew.sh
# ==============================================================================

step "Homebrew"

info "Checking if Homebrew is already installed..."
# https://stackoverflow.com/a/34389425/6751578
which brew
if [[ $? != 0 ]]; then
    info  "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    success "Homebrew installed"
else
    read -e -p "Homebrew is already installed. Would you like to update it? [y/N] " -n 1 -r -s REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Updating Homebrew..."
        brew update
        success "Homebrew updated"
    else
        warning "Skipping Homebrew update"
    fi
fi

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

info "Installing Homebrew packages..."
sudo apt install -y build-essential
brew_check gcc
success "Homebrew packages installed"

# ==============================================================================
# Git & GitHub (https://github.com/cli/cli)
# ==============================================================================

# step "Git & GitHub"

# # GitHub CLI =========================================================
brew_check gh
info "Checking if you are already logged in to GitHub..."
# if [[ $(git config --global --get init.defaultBranch) = "${GIT_BRANCH}" ]]; then
if gh auth status | grep 'You are not logged' > /dev/null; then
  gh auth login
else 
  success "You are already logged in"
fi

info "Setting Git using the GitHub CLI"
gh auth setup-git
success "Git set using the GitHub CLI"

# Git ================================================================
# Default branch name
read -e -p "Default git branch name [main]: " GIT_BRANCH
GIT_BRANCH=${GIT_BRANCH:-main}
if [[ $(git config --global --get init.defaultBranch) = "${GIT_BRANCH}" ]]; then
  info "Default branch name already set. Skipping..."
else
  info "Setting default branch name..."
  git config --global init.defaultBranch "${GIT_BRANCH}"
  success "Default branch name set."
fi

# User name
read -e -p "Default git user name: " -i "$(git config --global --get user.name)" GIT_USER_NAME
if [[ $(git config --global --get user.name) = "${GIT_USER_NAME}" ]]; then
  warning "Git user name already set. Skipping..."
else
  info "Setting git user name"
  git config --global user.name "${GIT_USER_NAME}"
  success "Git user name set"
fi

# Email
info "Go to https://github.com/settings/emails and copy your email address you wanna use for git"
read -e -p "Git default email: " -i "$(git config --global --get user.email)" GIT_EMAIL
read -e -p "Do you want to save it to your global git configuration? (y/N)" -n 1 -r -s REPLY
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if [[ $(git config --global --get user.email) = "${GIT_EMAIL}" ]]; then
    info "Git email already set. Skipping..."
  else
    info "Setting git email..."
    git config --global user.email $GIT_EMAIL
    success "Git email set. Skipping..."
  fi
else
  warning "Skipping GitHub email save"
fi

# ==============================================================================
# Trellis
# ==============================================================================

step "Installing Trellis"

# Trellis (https://docs.roots.io/trellis/master/installation/#requirements)
# https://docs.roots.io/trellis/master/python/#ubuntu
info "Installing Python..."
sudo apt install -y python3 python-is-python3 python3-pip
success "Python installed"

# https://github.com/roots/trellis-cli#quick-install-macos-and-linux-via-homebrew
info "Installing Trellis CLI..."
brew_check roots/tap/trellis-cli
success "Trellis CLI installed"

# https://virtualenv.pypa.io/en/latest/installation.html
# https://gist.github.com/frfahim/73c0fad6350332cef7a653bcd762f08d
info "Installing virtualenv"
sudo apt install -y python3-pip python3-venv
success "virtualenv installed"

# VirtualBox (https://www.virtualbox.org/wiki/Linux_Downloads)
# See also: https://linuxize.com/post/how-to-install-virtualbox-on-ubuntu-20-04/
info "Installing VirtualBox"
sudo apt install -y virtualbox
success "VirtualBox installed ($(vboxmanage --version))"

# Vagrant (https://www.vagrantup.com/downloads)
info "Installing Vagrant"
sudo apt install -y vagrant
success "Vagrant installed ($(vagrant -v))"

# Update vagrant-libvirt plugin
# https://www.vagrantup.com/docs/cli/plugin#local-1
info "Updating the vagrant-libvirt to the latest version"
vagrant plugin install --local vagrant-libvirt
success "vagrant-libvirt updated"

# ==============================================================================
# NVM (https://github.com/nvm-sh/nvm#install--update-script)
# ==============================================================================
info "Checking if NVM is installed"
if [ ! -d "$HOME/.nvm" ]; then
  warning "NVM is not installed. Have you properly run the script?"
  warning "Please, run the script again and wait for the \"znap restart\" instruction!"
else
  warning "NVM is already installed."
  read -e -p "Do you want to update NVM? [Y/n] " -n 1 -r -s REPLY
  if [[ $REPLY =~ ^[nN]$ ]]; then
    warning "Skipping NVM update"
  else
    # Todo: Fix this!
    # info "Updating NVM..."
    # nvm upgrade
    # success "NVM Updated"
    info "Please run \"nvm upgrade\" manually"

  fi
fi

# Node
info "Checking if the latest stable node version is installed"
if [ ! -d "$HOME/.nvm/versions/node/v$(nvm version node)" ]; then
  info "The latest stable node version is not installed."
  info "Installing node v$(nvm version node)"
  nvm install node
  success "Node installed"
else
  warning "The latest stable node version is already installed. Skipping..."
fi

# ==============================================================================
# Other software
# ==============================================================================
read -e -p "Other software to install: " -i "tree neofetch" MISC_SOFTWARE
info "Installing $MISC_SOFTWARE now..."
sudo apt install -y ${MISC_SOFTWARE}
success "Software installed"

step "Success! All done!"