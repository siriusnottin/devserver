#!/bin/bash

add_to_local_hosts() {

  local server_name="$1"
  local ip="$2"
  local hosts="$3"

  if [ -z "$server_name" ] || [ -z "$ip" ] || [ -z "$hosts" ]; then
    error ${FUNCNAME[0]} ${LINENO} "Missing arguments" 1
  fi

  print_default_ip() {
    # prints an ip between brackets if it exists
    if [ ! -z "$ip" ]; then
      printf %s "($ip)"
    fi
  }

  print_command_get_ip() {
    sep
    message -i "Run the following command on the server to get its IP address: (copy it to your clipboard)"
    message -c "  hostname -I"
    sep
  }

  if [ -z "$ip" ]; then
    print_command_get_ip
    message -i "$server_name IP address: $(print_default_ip)"
    read -e -p "> " -r ip
  fi

  sep

  local tmp_hosts=$(mktemp)
  local edited=false

  # add begin comment
  local begin_comment=$(printf "\n## %s [%s]\n" "devserversetup begin" "$server_name")
  echo -e "$begin_comment" >$tmp_hosts

  # adds the hosts
  for host in "${hosts[@]}"; do
    message -i "Checking for host $host in /etc/hosts..."
    local host_txt=$(printf "%s\t%s\n" "$ip" "$host")
    if grep -qx "$host_txt" /etc/hosts; then
      message -w "Host $host already exists in /etc/hosts. Skipping..."
    else
      message -i "Adding $host to /etc/hosts..."
      printf "%s\n" "$host_txt" >>$tmp_hosts
      edited=true
    fi
  done

  # add end comment
  local end_comment=$(printf "## %s\n" "devserversetup end")
  echo -e "$end_comment" >>$tmp_hosts

  # if the content of tmp_hosts is not found in /etc/hosts, we add it
  if $edited; then
    message -i "Writing the new hosts file to /etc/hosts"
    message -i "This may require your password to be entered..."
    cat $tmp_hosts | sudo tee -a /etc/hosts >/dev/null || error ${FUNCNAME[0]} ${LINENO} "Failed to write to /etc/hosts" 1
    message -s "Successfully edited /etc/hosts"
  fi

  rm $tmp_hosts

  sep

}
