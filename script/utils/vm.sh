#!/bin/bash

# See the official Unraid documentation for more information:
# https://wiki.unraid.net/UnRAID_6_4/VM_Management

# checks if a vm exists
vm_exists() {

  local vm_domain="$1"

  # checks if a vm is passed as an argument
  if [ -z "$vm_domain" ]; then
    script_error ${FUNCNAME[1]} $LINENO "No vm name passed as an argument"
    return 1
  fi

  if ssh root@$UNRAID_IP "virsh list --all --name | grep \"$vm_domain\"" >/dev/null; then
    return 0
  else
    script_error ${FUNCNAME[1]} $LINENO "vm $vm_domain does not exist."
    return 1
  fi

}

get_vm_network_interface_infos() {
  if ssh root@$UNRAID_IP "virsh domiflist \"$1\" | sed -n '3p'"; then
    return 0
  else
    script_error ${FUNCNAME[1]} $LINENO "Could not get the network interface infos for $1"
    return 1
  fi
}

get_vm_virsh_net_dhcp_leases_default() {
  if ssh root@$UNRAID_IP "virsh net-dhcp-leases default | grep \"$1\""; then
    return 0
  else
    script_error ${FUNCNAME[1]} $LINENO "No lease found for $1"
    return 1
  fi
}

get_vm_network_bridge_src() {
  if get_vm_network_interface_infos "$1" >/dev/null; then
    get_vm_network_interface_infos "$1" | awk '{print $3}'
  else
    return 1
  fi
}

# gets the mac address of a vm
get_vm_mac() {

  local vm_domain="$1"

  # checks if a vm is passed as an argument and if it exists
  if [ -z "$vm_domain" ]; then
    script_error ${FUNCNAME[1]} $LINENO "No vm name passed as an argument"
    return 1
  elif ! vm_exists "$vm_domain"; then
    return 1
  fi

  get_vm_net_mac_address_virsh() {
    if get_vm_virsh_net_dhcp_leases_default "$1" >/dev/null; then
      printf "%s\n" "$(get_vm_virsh_net_dhcp_leases_default \"$1\" | awk '{print $3}')"
    else
      script_error ${FUNCNAME[1]} $LINENO "No mac address found for $1"
      return 1
    fi
  }

  get_vm_net_mac_address_xml() { # gets it from the xml configuration of the vm (as failsafe)
    local vm_xml_tmp=$(mktemp)
    ssh root@$UNRAID_IP "virsh dumpxml \"$1\"" | tee -a $vm_xml_tmp >/dev/null
    xmllint --nowarning --xpath "string(/domain/devices/interface/mac/@address)" $vm_xml_tmp
    rm $vm_xml_tmp
  }

  # test both methods and return the first one that works
  if [ "$(get_vm_network_bridge_src $1)" == "virbr0" ]; then
    printf "%s\n" "$(get_vm_net_mac_address_virsh \"$1\")"
  else
    printf "%s\n" "$(get_vm_net_mac_address_xml \"$1\")"
  fi

}

# gets the ip of a vm
get_vm_ip() {

  local vm_domain="$1" network_conf_ip_range="$2"

  # checks if a vm is passed as an argument and if it exists
  if [ -z "$vm_domain" ]; then
    script_error ${FUNCNAME[1]} $LINENO "No vm name passed as an argument"
    return 1
  elif ! vm_exists "$vm_domain"; then
    return 1
  elif [ -z "$network_conf_ip_range" ]; then
    script_error ${FUNCNAME[1]} $LINENO "No network configuration passed as an argument"
    return 1
  fi

  local VM_MAC=$(get_vm_mac "$vm_domain")
  local VM_NET=$(get_vm_network_bridge_src "$vm_domain")

  if [ "$VM_NET" = "virbr0" ]; then
    # private network bridge: network is managed by the vm engine libvirt
    get_vm_virsh_net_dhcp_leases_default "$1" | awk '{print $5}' | sed 's/\/24//'
  elif [ "$VM_NET" = "br0" ]; then
    # we're on a public bridge managed by unRAID
    if sudo nmap -sP -n "$network_conf_ip_range" | grep -i -B 2 "$VM_MAC" | sed -n '1p' | awk '{print $5}'; then
      return 0
    else
      script_error ${FUNCNAME[1]} $LINENO "Error scanning the network. Have you installed nmap?"
      return 1
    fi
  else
    script_error ${FUNCNAME[1]} $LINENO "Unknown network bridge: $VM_NET"
    return 1
  fi

}

# checks the state of the vm
get_vm_state() {

  local vm_domain="$1"

  # checks if a vm is passed as an argument and if it exists
  if [ -z "$vm_domain" ]; then
    script_error ${FUNCNAME[1]} $LINENO "No vm name passed as an argument"
    return 1
  elif ! vm_exists "$vm_domain"; then
    return 1
  fi

  ssh root@$UNRAID_IP "virsh domstate \"$vm_domain\""

}

# checks if a vm is running
is_vm_running() {

  local vm_domain="$1"

  # checks if a vm is passed as an argument and if it exists
  if [ -z "$vm_domain" ]; then
    script_error ${FUNCNAME[1]} $LINENO "No vm name passed as an argument"
    return 1
  elif ! vm_exists "$vm_domain"; then
    return 1
  fi

  if [ "$(get_vm_state \"$vm_domain\")" == "running" ]; then
    return 0
  else
    message -i "vm $vm_domain is not running"
    return 1
  fi

}

start_vm() {

  local vm_domain="$1"

  # checks if a vm is passed as an argument and if it exists
  if [ -z "$vm_domain" ]; then
    script_error ${FUNCNAME[1]} $LINENO "No vm name passed as an argument"
    return 1
  elif ! vm_exists "$vm_domain"; then
    return 1
  fi

  if ! is_vm_running "$vm_domain"; then
    ssh root@$UNRAID_IP "virsh start \"$vm_domain\""
    return 0
  fi

}

# Will retrieve the vm info and expose them as variables
# Returns: vm_description, vm_net_bridge_src, vm_mac, vm_ip
get_vm_infos() {

  local vm_domain="$1"

  # checks if a vm is passed as an argument and if it exists
  if [ -z "$vm_domain" ]; then
    script_error ${FUNCNAME[1]} $LINENO "No vm name passed as an argument"
    return 1
  elif ! vm_exists "$vm_domain"; then
    return 1
  fi

  message -i "Retrieving the vm $vm_domain infos..."
  message -i "We may need to ask for your password in order to scan the network..."

  get_vm_description() {
    local desc=$(ssh root@$UNRAID_IP "virsh desc \"$vm_domain\"")
    printf "%s\n" "$desc"
  }

  vm_description() {
    if get_vm_description | grep -qix "No description for domain: \"$vm_domain\""; then
      message -w "N/A"
    else
      get_vm_description
    fi
  }

  vm_description=$(vm_description)
  vm_net_bridge_src=$(get_vm_network_bridge_src $vm_domain)
  vm_net_bridge_src_type() {
    if [ "$vm_net_bridge_src" == "virbr0" ]; then
      script_error ${FUNCNAME[1]} $LINENO "private"
    elif [ "$vm_net_bridge_src" == "br0" ]; then
      message -s "public"
    fi
  }
  vm_mac=$(get_vm_mac $vm_domain)
  vm_ip=$(get_vm_ip "$vm_domain" "$NETWORK_CONFIG_IP_RANGE")
  if [ -z "$vm_ip" ]; then
    message -i "The vm seems to have no ip address. Have you started it yet?"
  fi

  message -s "Successfully retrieved the vm $vm_domain infos"

}

# Prints the vm infos for the user
# You should first get the vm info as variables using the get_vm_infos function.
# It will do all of it for you but you must call it before!
print_vm_infos() {

  local vm_domain="$1" vm_username="$2"

  if get_vm_infos "$vm_domain"; then
    sep
    message -i "Useful infos:"
    sep
    message -c "  Name: $vm_description"
    message -c "  Domain: $vm_domain"
    message -c "  Network: $vm_net_bridge_src $(vm_net_bridge_src_type)"
    message -c "  Mac Addr: $vm_mac"
    message -c "  IP: $vm_ip"
    message -c "  Username: $vm_username"
    sep
    message -i "You can also ssh to the vm using both its name and IP address, like this:"
    message -c "  ssh $vm_username@$vm_domain"
  fi

}

# creates a vm
create_vm() {

  local vm_domain="$1" vm_name="$2" vm_username="$3" max_wait="$4"

  max_wait=${max_wait:-10}

  # checks the args
  if [ -z "$vm_domain" ] || [ -z "$vm_name" ] || [ -z "$vm_username" ]; then
    script_error ${FUNCNAME[1]} $LINENO "Missing args"
    return 1
  fi

  # if the vm already exists, we don't create it
  ! vm_exists "$vm_domain" || script_error ${FUNCNAME[1]} $LINENO "The vm $vm_domain already exists" >/dev/null

  message -i "Creating the vm $vm_domain..."

  sep

  message -i "Copying the vm config file to unraid... (/tmp/devserver.xml)"
  if scp $PARENT_SCRIPT_DIR/devserver.xml root@$UNRAID_IP:/tmp/devserver.xml >/dev/null; then
    : # ok
  else
    script_error ${FUNCNAME[1]} $LINENO "Failed to copy the vm config file"
    return 1
  fi

  message -i "Creating the $vm_domain vm..."
  if ssh root@$UNRAID_IP 'virsh define /tmp/devserver.xml' >/dev/null; then
    : # ok
  else
    script_error ${FUNCNAME[1]} $LINENO "Failed to create the vm"
    return 1
  fi

  message -i "Deleting the vm config file..."
  if ssh root@$UNRAID_IP 'rm -v /tmp/devserver.xml' >/dev/null; then
    : # ok
  else
    script_error ${FUNCNAME[1]} $LINENO "Failed to delete the vm config file"
    return 1
  fi

  message -s "vm $vm_domain created"

  message -i "Starting the vm $vm_domain..."
  if ssh root@$UNRAID_IP "virsh start $vm_domain"; then
    : # ok
  else
    script_error ${FUNCNAME[1]} $LINENO "Failed to start the vm"
    return 1
  fi

  # while the vm is not ready, we wait
  message -i "Waiting for the vm $vm_domain to be ready..."
  sleep 8
  local vm_ready=0
  while [ $vm_ready -eq 0 ]; do
    if is_vm_running "$vm_domain" /dev/null 2>&1; then
      vm_ready=1
    else
      sleep 5
    fi
  done
  message -s "vm $vm_domain is now running"

  get_vm_infos "$vm_domain"
  if [ -z "$vm_ip" ]; then
    script_error ${FUNCNAME[1]} $LINENO "Failed to get the vm ip"
    return 1
  fi

  message -i "Testing the ssh connection to the vm..."
  if test_ssh_connection "$vm_domain" "$vm_username" "$vm_ip" "$max_wait" /dev/null 2>&1; then
    message -w "✅ The $vm_domain vm is now fully ready"
  else
    script_error ${FUNCNAME[1]} $LINENO "The $vm_domain vm is installed but it is not responding. Please check the vm status and the network connection."
  fi

  # local setup for the vm
  add_to_local_hosts "$vm_name vm" "$vm_ip" "$vm_domain"

  message -s "The vm $vm_domain is now ready to use."

  print_vm_infos "$vm_domain" "$vm_username"

}

# stops a vm
stop_vm() {

  local vm_domain="$1"
  local stop_action="$2"
  stop_action=${stop_action:-"destroy"}
  local timeout=5

  # checks if a vm is passed as an argument and if it exists
  if [ -z "$vm_domain" ]; then
    script_error ${FUNCNAME[1]} $LINENO "No vm name passed as an argument"
    return 1
  elif ! vm_exists "$vm_domain"; then
    return 1
  fi

  if is_vm_running "$vm_domain"; then
    message -i "Stopping the $vm_domain vm..."
    ssh root@$UNRAID_IP "virsh \"$stop_action\" \"$vm_domain\"" >/dev/null
    local vm_stopped=false
    local i=0
    while [ $i -lt $timeout ] && [[ $vm_stopped == false ]]; do
      if [[ "$(get_vm_state \"$vm_domain\")" = "shut off" ]]; then
        message -s "$vm_domain vm stopped"
        vm_stopped=true
        break
      elif [ $i -eq $timeout ]; then
        script_error ${FUNCNAME[1]} $LINENO "$vm_domain vm could not be stopped in time. Retrying..."
        stop_vm "$vm_domain"
        break
      fi
      i=$((i + 1))
      sleep 1
    done
  fi
}

# deletes a vm
delete_vm() {

  local vm_domain="$1"

  # checks if a vm is passed as an argument and if it exists
  if [ -z "$vm_domain" ]; then
    script_error ${FUNCNAME[1]} $LINENO "No vm name passed as an argument"
    return 1
  elif ! vm_exists "$vm_domain" /dev/null 2>&1; then
    script_error ${FUNCNAME[1]} $LINENO "Can't delete the $vm_domain vm because it doesn't exist"
    return 1
  else

    if is_vm_running "$vm_domain" /dev/null 2>&1; then
      stop_vm "$vm_domain"
    fi

    if vm_exists "$vm_domain" /dev/null 2>&1; then
      # if the vm still exists, we can delete it
      message -i "Deleting the $vm_domain vm..."
      if ssh root@$UNRAID_IP "virsh undefine --domain \"$vm_domain\"" >/dev/null; then
        message -s "Deleted"
      else
        script_error ${FUNCNAME[1]} $LINENO "Failed to delete the $vm_domain vm"
        return 1
      fi
    else
      script_error ${FUNCNAME[1]} $LINENO "Can't delete the $vm_domain vm because it doesn't exist"
      return 1
    fi

  fi

}
