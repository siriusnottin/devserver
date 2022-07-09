#!/bin/bash

# =============================================================================
#                                   New VM                                    #
# =============================================================================

source $SCRIPT_DIR/utils/hosts.sh

###############################################################################
step "$VM_DOMAIN VM"
###############################################################################

source $SCRIPT_DIR/utils/vm.sh
source $SCRIPT_DIR/utils/ssh.sh

shift

# test if the vm exists with no output
# if no args
if [ -z "$1" ]; then

  if vm_exists "$VM_DOMAIN" >/dev/null; then

    print_vm_infos "$VM_DOMAIN" "$VM_USERNAME"

  else

    message -c "$VM_DOMAIN vm not found. Creating..."
    create_vm "$VM_DOMAIN" "$VM_NAME" "$VM_USERNAME"

  fi

fi

print_vm_help() {
  sep
  sep -t "Usage:"
  message -w "  $SCRIPTNAME vm [flags] [<args>]"
  sep
  sep -t "Options:"
  message -m "  [-n|--new <vmdomain> <username> | -d|--delete <vmdomain> | [-i|--infos <vmdomain>] [--disk <action>] [-h|--help]]"
  sep
  message -i "  Without any flags, it will show the $VM_DOMAIN vm infos or create it if it doesn't exist"
  sep
  sep -t "New VM"
  message -w "  (not yet implemented)"
  message -m "  -n|--new <vmdomain> <username>                        Create a new vm"
  sep
  message -c " Options:"
  message -c "  [--name <VM Name>]"
  message -c "  [--cpu <1-4>]"
  message -c "  [--ram <2G-4G..16G>]"
  message -c "  [--disk <40G>]"
  message -c "  [--network <br0|virbr0>]"
  message -c "  [--ssh <your public key path>]"
  sep
  sep -t "Delete VM"
  message -m "  -d|--delete <vmname>                                       Delete a vm"
  sep
  sep -t "VM Infos"
  message -m "  -i|--infos <vmname>                       Gets and Prints the vm infos"
  sep
  sep -t "VM Disk"
  message -m "  --disk [resize|show]              Prints (or resize) the vm disk infos"
  sep
  sep -t "Help"
  message -m "  -h|--help                                             Prints this help"
}

for arg in "$@"; do
  case $arg in
  -h | --help)
    print_vm_help
    break
    ;;
  -i | --info | --infos)
    shift
    print_vm_infos "$1" "$VM_USERNAME"
    break
    ;;
  -n | --new)
    message -w "Not implemented yet"
    # TODO: implement the new vm command
    # shift
    # if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    #   error "Missing arguments"
    #   sep
    #   print_vm_help
    #   exit 1
    # fi
    # create_vm "$1" "$2" "$3"
    break
    ;;
  -d | --delete)
    shift
    if [ -z "$1" ]; then
      error "Error: Missing VM name"
      sep
      print_vm_help
      exit 1
    fi
    delete_vm "$1"
    break
    ;;
  -c | --create)
    create_vm "$VM_DOMAIN" "$VM_NAME" "$VM_USERNAME"
    break
    ;;
  --disk)
    shift
    source $SCRIPT_DIR/actions/manage_disk.sh
    break
    ;;
  *)
    error "Unknown argument $arg"
    sep
    print_vm_help
    exit 1
    ;;
  esac
done
