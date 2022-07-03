#!/bin/bash

test_ssh_connection() {

  # Will test a server responsiveness by sshing to it (10 seconds max by default)

  local server_name="$1" username="$2" ip="$3" max_wait="$4"
  local timeout=${max_wait:-10}

  # checks the args
  if [ -z "$server_name" ] || [ -z "$username" ] || [ -z "$ip" ]; then
    script_error ${FUNCNAME[1]} ${LINENO} "Missing arguments" 1
  fi

  if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o ConnectTimeout=$timeout $username@$ip "echo 'SSH connection OK'" >/dev/null; then
    return 0
  else
    error "$server_name is not responding. Please check the the network connection." 1
  fi

}

remove_domain_from_known_hosts() {
  local host="$1"
  if ssh-keygen -R "$host" >/dev/null 2>&1 | grep -q "Host $host not found"; then
    sep
    message -i "Removing $server_name from known_hosts..."
    ssh-keygen -R $host
  fi
}
