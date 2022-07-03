#!/bin/bash

# Transforms long flags to short ones
# Ex. --long to -l
transform_long_flags() {
	for longflag in "$@"; do
		if [ "${longflag:0:2}" = "--" ]; then
			flag=${longflag:2}
			shortflag=-${flag:0:1}
			set -- "$@" "$shortflag"
		fi
		return 0
	done
}
