#!/bin/bash

# Prints the help

sep -t "Usage"
sep
message -w "  $(basename $0) <command> [flag1] [<argument1>] [flag2] [<argument2>]"
sep
sep -t "Manage your Unraid vms"
sep
message -m "  vm      [-n|--new | -d|--delete | [-i|--infos <vmname>] [-h|--help]]"
sep
message -i "  Without any flags, it will show the $VM_DOMAIN vm infos or create it if it doesn't exist"
sep
sep -t "Setup or update the devserver vm"
sep
message -m "  setup|install|update  [--steps] <steps>"
sep
message -i "  Write only the --steps flag to list all the steps available"
sep
sep -t "Vagrant project"
sep
message -m "  vagrant [<project name or folder path>]"
sep
message -i "  Run this anywhere or directly inside a vagrant project folder to start working with it"
sep
message -i "  Will perform some addtional setup on your Vagrant project to support the latest version of Trellis"
message -i "  Read more on https://github.com/siriusnottin/devserversetup"
sep
sep -t "Help"
sep
message -m "  h|help                                                  Prints this help"
