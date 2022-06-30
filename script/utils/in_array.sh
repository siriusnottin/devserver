#!/bin/bash

in_array() {
  local haystack=("$@")
  local needle=$1
  shift
  for i in "${haystack[@]}"; do
    if [ "$i" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}
