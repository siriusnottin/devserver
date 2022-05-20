#!/bin/sh

# ==============================================================================
# Mount the shares
# https://forums.unraid.net/topic/71600-unraid-vm-shares/?do=findComment&comment=658008
# ==============================================================================

echo "Mounting shares..."

read -e -p "Share name to mount: " -i "projects virtualbox" SHARES_NAME

for share in "${SHARES_NAME}[@]"
do
  if [ ! -d "${HOME}/${share[@]}" ]; then
    echo "Creating mount point for ${share}[@]"
    mkdir ${HOME}/${share[@]}
  fi

  echo "Adding ${share[@]} to fstab"
  echo -e "${share[@]}    ${HOME}/${share[@]}    9p    trans=virtio,version=9p2000.L,_netdev,rw 0 0" | sudo tee -a /etc/fstab

  echo "Mounting${share[@]}"
  sudo mount ${share[@]}
done

echo "All shares are now mounted"

# If multiple users
# and for aditionnal security: https://code.visualstudio.com/docs/remote/troubleshooting#_improving-security-on-multi-user-servers
# echo "AllowStreamLocalForwarding yes" | sudo tee -a /etc/ssh/sshd_config
# sudo systemctl restart sshd

# Software update
echo "Updating software..."
sudo apt update && sudo apt upgrade -y

# Install software
read -e -p "Software to install: " -i "tree neofetch zsh" SOFTWARE
echo "Installing software..."
sudo apt install -y ${SOFTWARE}

# Change shell
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  echo "Changing default shell to zsh..."
  chsh -s /usr/bin/zsh
  echo "Default shell changed"
  echo "Please login again to apply changes"
  read -p "Press enter to logout: " -n 1 -srp
  exit
fi

# ==============================================================================
# Znap! (https://github.com/marlonrichert/zsh-snap#installation)
# See also: https://pablo.tools/blog/computers/znap-zsh-plugin-manager/
# ==============================================================================

read -e -p "Znap install path: " -i "~/.zsh-plugins" ZNAP_INSTALL_FOLDER

if [ ! -d "${ZNAP_INSTALL_FOLDER}" ]; then
  echo "Creating folder for Znap..."
  mkdir -p ${ZNAP_INSTALL_FOLDER}
fi

echo "Checking if Znap is installed..."
if [ ! -d "${ZNAP_INSTALL_FOLDER}/zsh-snap" ]; then
  echo "Installing Znap..."
  git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git ${ZNAP_INSTALL_FOLDER}
fi
echo "Znap is installed here: \"${ZNAP_INSTALL_FOLDER}\""

echo "Creating .zshrc file..."
if [ -f "$HOME/.zshrc" ]; then
  echo "Backing up .zshrc file..."
  mv $HOME/.zshrc $HOME/.zshrc.setup_backup.$(date +%Y%m%d%H%M%S)
  echo "Backed up .zshrc file"
fi

# create a symbolic link to the zshrc file
echo "Creating symbolic link to .zshrc file..."
ln -s $HOME/devserversetup/.zshrc $HOME/.zshrc
echo "Your .zshrc file is now linked to this file"

znap restart

# echo "zstyle ':omz:update' mode reminder" >> ~/.zshrc

# ==============================================================================
# Homebrew (https://brew.sh/)
# ==============================================================================

echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Recommended:
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
sudo apt install -y build-essential
brew install gcc

# ==============================================================================
# Git & GitHub (https://github.com/cli/cli)
# ==============================================================================

# GitHub CLI =========================================================
echo "Installing the GitHub CLI"
brew install gh

echo "Loging into GitHub"
gh auth login

echo "Setting Git using the GitHub CLI"
gh auth setup-git

# Git ================================================================
# Default branch name
read -e -p "Default git branch name: [main]" -i "main" BRANCH_NAME
git config --global init.defaultBranch BRANCH_NAME

# User name
read -e -p "Default git user name: [${LOGNAME}]" -i "${LOGNAME}" USER_NAME
git config --global user.name $USER_NAME

echo "Go to https://github.com/settings/emails and add your email address"
read -p "Your GitHub email: " GITHUB_EMAIL
echo -p "Do you want to save this GitHub email: ${GITHUB_EMAIL}? (Y/n)" -n 1 -r REPLY
case $REPLY in
    [nN]*) ;;
    *) git config --global user.email "${GITHUB_EMAIL}" ;;
esac

# ==============================================================================
# Trellis
# ==============================================================================
echo "Installing Trellis and it's dependencies"
# Trellis (https://docs.roots.io/trellis/master/installation/#requirements)
# https://docs.roots.io/trellis/master/python/#ubuntu
sudo apt install -y python3 python-is-python3 python3-pip

# https://github.com/roots/trellis-cli#quick-install-macos-and-linux-via-homebrew
brew install roots/tap/trellis-cli

# https://virtualenv.pypa.io/en/latest/installation.html
# https://gist.github.com/frfahim/73c0fad6350332cef7a653bcd762f08d
sudo apt install -y python3-pip python3-venv

# VirtualBox (https://www.virtualbox.org/wiki/Linux_Downloads)
# See also: https://linuxize.com/post/how-to-install-virtualbox-on-ubuntu-20-04/
sudo apt install -y virtualbox

# Vagrant (https://www.vagrantup.com/downloads)
sudo apt install -y vagrant

trellis check # should be all green

# ==============================================================================
# NVM (https://github.com/nvm-sh/nvm#install--update-script)
# ==============================================================================
echo "Upgrading NVM"
nvm upgrade

echo "Checking if NVM is installed"
# check if nvm is installed if not just echo something
if [ ! -d "$HOME/.nvm" ]; then
  echo "NVM is not installed. Have you aliased your .zshrc?"
  echo "run \"znap restart\" after aliasing your .zshrc file."
fi

# Node
echo "Installing the latest stable node version"
nvm install node
node -v # should be: v18xx