#!/bin/bash

# =============================================================================
#                                Server Setup                                 #
# =============================================================================

action="$1"

message -i "Server $action started..."
sep

ACTION=$(echo $action | tr '[:lower:]' '[:upper:]')

shift

while [ $# -gt 0 ]; do
  case $1 in
  --step | --steps)
    shift
    # message -w "Steps: $*"
    if [ $# -gt 0 ]; then # if there are steps to process
      USER_STEPS=("$@")
      break
    else
      source $SCRIPT_DIR/actions/print_steps.sh
      exit 0 # we exit here to not execute the steps later
    fi
    ;;
  *)
    error "Unknown command: $1"
    sep
    source $SCRIPT_DIR/actions/print_help.sh
    exit 1
    ;;
  esac
  shift
done

# we load the steps to be executed
source $SCRIPT_DIR/utils/script_step_exec_log.sh
source $SCRIPT_DIR/utils/server_setup_fn.sh

# here we can disable or add new steps
# don't forget to add the step to the list of steps in /actions/print_steps.sh
SETUP_STEPS_AVAILABLE=(
  timezone
  update_software
  shares
  projects
  # multiple_users
  default_shell
  znap
  zsh_config
  homebrew
  github
  git
  trellis
  php
  composer
  nvm
  node
  additional_software
)

UPDATE_STEPS_AVAILABLE=(update_software_dist znap homebrew nvm nod)

# https://stackoverflow.com/questions/11180714/how-to-iterate-over-an-array-using-indirect-reference
array_name="${ACTION}_STEPS_AVAILABLE"
ACTION_STEPS_AVAILABLE="${array_name}[*]"
ACTION_STEPS_AVAILABLE=(${!ACTION_STEPS_AVAILABLE})

do_user_steps() {
  # checks if the steps are valid
  for step in "${USER_STEPS[@]}"; do
    if [ -z "${step// /}" ]; then
      error "Step cannot be empty"
      sep
      source $SCRIPT_DIR/actions/print_help.sh >&2
      exit 1
    elif [[ "${ACTION_STEPS_AVAILABLE[*]}" =~ "$step" ]]; then
      USER_STEPS_OK+=("$step")
    else
      error "Step $step is not available to $action" 1
    fi
  done

  # once we have the valid steps, we execute them
  for step in "${USER_STEPS_OK[@]}"; do
    eval step_"$step"
  done

  return 0
}

do_all_steps() {
  message -w "No steps specified, running all steps..."
  for step_fn in "${ACTION_STEPS_AVAILABLE[@]}"; do
    eval step_"$step_fn"
  done
}

[[ -n $USER_STEPS ]] && do_user_steps || do_all_steps
