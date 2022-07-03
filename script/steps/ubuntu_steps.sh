#!/bin/bash

step_timezone() {
  message -i "Setting timezone..."
  sudo timedatectl set-timezone Europe/Paris
}

step_shares() {

  #############################################################################
  step "Shares"
  #############################################################################

  # https://forums.unraid.net/topic/71600-unraid-vm-shares/?do=findComment&comment=658008

  local credentials_file="/root/.cifs"
  printf "%s\n" "username=$VM_DOMAIN" "password=MWV.pcp*zxd@ujc2rge" | sudo tee $credentials_file >/dev/null || script_error ${FUNCNAME[0]} ${LINENO} "Could not write to $credentials_file" 1
  sudo chmod 600 $credentials_file || script_error ${FUNCNAME[0]} ${LINENO} "Could not change permissions on $credentials_file" 1

  apt_check cifs-utils

  read -e -p "Shares to mount: " -i "projects virtualbox" -a SHARES
  local edited=false
  message -i "Checking the shares..."
  for share in "${SHARES[@]}"; do

    # ----------- Share folder
    if [ ! -d "/mnt/$share" ]; then
      message -i "Creating mount point for $share"
      sudo mkdir "/mnt/$share" || script_error ${FUNCNAME[0]} ${LINENO} "Could not create mount point for $share" 1
      edited=true
      message -s "Created mount point for $share"
    fi

    # ----------- Edit fstab
    local share_fstab="//$UNRAID_IP/$share	/mnt/$share	cifs	credentials=$credentials_file,rw,uid=nobody,gid=users,iocharset=utf8 0 0"

    add_share() {
      message -i "Adding $share to fstab"
      printf "%s\n" "$share_fstab" | sudo tee -a /etc/fstab >/dev/null || script_error ${FUNCNAME[0]} ${LINENO} "Could not add $share to fstab" 1
      edited=true
      message -s "$share added to fstab"
    }

    if grep -sq "$share" /etc/fstab; then
      if ! grep -sxq "$share_fstab" /etc/fstab; then
        # remove the line from the fstab
        message -w "Found exisiting $share share in fstab but it does not match the current configuration. Removing it..."
        sudo sed -i "/$share/d" /etc/fstab || script_error ${FUNCNAME[0]} ${LINENO} "Could not remove $share from fstab" 1
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
      sudo mount "/mnt/$share" || script_error ${FUNCNAME[0]} ${LINENO} "Could not mount $share." 1
      edited=true
      message -s "Mounted $share"
    fi
  done

  if [ "$edited" = false ]; then
    message -w "Shares already created and mounted. Skipping..."
  fi

}

step_multiple_users() {

  #############################################################################
  step "Multiple users"
  #############################################################################

  # for aditionnal security:
  # https://code.visualstudio.com/docs/remote/troubleshooting#_improving-security-on-multi-user-servers

  printf "%s\n" "AllowStreamLocalForwarding yes" | sudo tee -a /etc/ssh/sshd_config
  systemctl restart sshd
}

step_php() {

  script_log_step_execution_now

  #############################################################################
  step "PHP"
  #############################################################################

  message -i "Installing PHP..."
  apt_check software-properties-common ca-certificates apt-transport-https
  message -i "Adding PHP repository..."
  sudo add-apt-repository ppa:ondrej/php -y >/dev/null || script_error ${FUNCNAME[0]} $LINENO "Failed to add PHP repository" 1
  message -i "Updating package list..."
  sudo apt update >/dev/null || script_error ${FUNCNAME[0]} $LINENO "Failed to update package list" 1
  message -i "Upgrading packages..."
  sudo apt upgrade -y >/dev/null || script_error ${FUNCNAME[0]} $LINENO "Failed to upgrade packages" 1
  apt_check php8.0 php8.0-cli php8.0-simplexml

}
