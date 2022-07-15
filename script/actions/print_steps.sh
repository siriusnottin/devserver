#!/bin/bash

# Prints the steps the script can run

steps_file="$SCRIPT_DIR/steps/README.md"
# get all lines between "##"
cat "$steps_file" | grep -E "^##" | sed "s/^###//" | sed "s/^/  /"
