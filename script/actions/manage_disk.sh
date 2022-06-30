#!/bin/bash

# =============================================================================
#                                Disk Resize                                  #
# =============================================================================

# Extend the disk partition to max size
# https://askubuntu.com/a/1400759/979591

show_space() {
  # Shows the space used by the server without the name
  df -h | grep -E '^/dev/'
  sep
  sudo vgdisplay
}

# checks if the disk is already resized
is_disk_resized() {
  # checks without returning the command output
  if ! sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv >/dev/null 2>&1; then
    return 1
  fi
}

resize_disk() {
  if is_disk_resized; then
    message -i "Extending the partition to max size"
    sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
    show_space
    message -s "Partition extended"
    message -s "Disk resized"
  else
    message -w "The disk is already resized. Skipping..."
  fi
}

while [ $# -gt 0 ]; do
  case $1 in
  resize)
    resize_disk
    ;;
  show | info | infos)
    show_space
    ;;
  *)
    show_space
    sep
    message -i "To resize the disk, use the resize command"
    sep
    ;;
  esac
  shift
done
