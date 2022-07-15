#!/bin/bash

# =============================================================================
#                                Server Setup                                 #
# =============================================================================

action="$1"
case $OS in
ubuntu)
  machine_type="Server"
  ;;
macos)
  machine_type="Mac"
  ;;
*)
  script_error ${FUNCNAME[0]} ${LINENO} "Unknown OS" 1
  ;;
esac

message -i "$machine_type $action started..."
sep

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

source $SCRIPT_DIR/utils/script_step_exec_log.sh
source $SCRIPT_DIR/utils/install_app.sh
source $SCRIPT_DIR/steps/global_steps.sh
source $SCRIPT_DIR/steps/ubuntu_steps.sh
source $SCRIPT_DIR/steps/macos_steps.sh

# here we can disable or add new steps
# don't forget to add the step to the list of steps in /actions/print_steps.sh
SETUP_STEPS_AVAILABLE_UBUNTU=(
  timezone
  update_software
  shares
  projects
  default_shell
  znap
  zsh_config
  homebrew
  github
  git
  trellis
  ngrok
  php
  composer
  nvm
  node
  yarn
  additional_software
)

SETUP_STEPS_AVAILABLE_MACOS=(
  update_software
  xcode_dev_tools
  install_mac_apps
  code_remote_ssh
  projects
  default_shell
  znap
  zsh_config
  homebrew
  github
  git
  trellis
  ngrok
  composer
  nvm
  node
  yarn
  additional_software
)

UPDATE_STEPS_AVAILABLE_UBUNTU=(update_software_dist znap homebrew nvm node)
UPDATE_STEPS_AVAILABLE_MACOS=(update_software_dist znap homebrew nvm node)

# https://stackoverflow.com/questions/11180714/how-to-iterate-over-an-array-using-indirect-reference
array_name=$(echo "${action}_STEPS_AVAILABLE_${OS}" | tr '[:lower:]' '[:upper:]')
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
    eval step_"$step" # TODO: sanitize the step name
  done

  return 0
}

do_all_steps() {
  message -w "No steps specified, running all steps..."
  for step_fn in "${ACTION_STEPS_AVAILABLE[@]}"; do
    eval step_"$step_fn" # TODO: sanitize the step name
  done
}

[[ -n $USER_STEPS ]] && do_user_steps || do_all_steps
