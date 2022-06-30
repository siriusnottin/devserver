#!/bin/bash

# =============================================================================
#                                Server Setup                                 #
# =============================================================================

if [ "$1" = "setup" ] || [ "$1" = "install" ]; then
  UPDATE=false
  message -i "Server setup started..."
  sep
  shift
elif [ "$1" = "update" ]; then
  UPDATE=true
  message -i "Server update started..."
  sep
  shift
else
  error ${FUNCNAME[0]} ${LINENO} "No arguments supplied! Use the help command to see the usage" 1
fi

USER_STEPS=()
while [ $# -gt 0 ]; do
  case $1 in
  --step | --steps)
    shift
    # message -w "Steps: $*"
    if [ $# -gt 0 ]; then
      if [ -z "${1// /}" ]; then
        error ${FUNCNAME[0]} ${LINENO} "No step specified" 1
      fi
      # put all rest of the args in an array
      # message -w "Adding steps: $* (#$#)"
      USER_STEPS=("$@")
    else
      source $SCRIPT_DIR/actions/print_steps.sh
      exit 0
    fi
    ;;
  -h | --help)
    source $SCRIPT_DIR/help.sh
    exit 0
    ;;
  *)
    message -e "Unknown command: $1"
    sep
    source $SCRIPT_DIR/help.sh
    exit 1
    ;;
  esac
  shift
done

# we load the steps to be executed
source $SCRIPT_DIR/utils/server_setup_fn.sh

# here we can diable or add new steps
# don't forget to add the step to the list of steps in /actions/print_steps.sh
STEPS_AVAILABLE=(
  "update_software"
  "shares"
  "projects"
  # "multiple_users"
  "default_shell"
  "znap"
  "zsh_config"
  "homebrew"
  "github"
  # "git"
  "trellis"
  "php"
  "composer"
  # "nvm"
  # "node"
  "additional_software"
)

UPDATE_STEPS_AVAILABLE=(
  "update_software_dist"
  "znap"
  "homebrew"
  # "nvm"
  # "node"
)

if [ ! -z "${USER_STEPS}" ]; then

  USER_STEPS_OK=()

  # checks if the steps are valid
  check_step() {
    local step="$1" steps_available=("$2") action="$3"
    # message -c "Checking step: $step"
    if [ -z "${1// /}" ]; then
      error ${FUNCNAME[0]} ${LINENO} "Step cannot be empty" 1
    elif [[ "${steps_available[*]}" =~ "$step" ]]; then
      # message -s "Step $step is valid"
      USER_STEPS_OK+=("$step")
    else
      error ${FUNCNAME[0]} ${LINENO} "Step $step is not available to $action" 1
    fi
  }

  for step_fn in "${USER_STEPS[@]}"; do
    if $UPDATE; then
      check_step "$step_fn" "${UPDATE_STEPS_AVAILABLE[*]}" "update"
    else
      check_step "$step_fn" "${STEPS_AVAILABLE[*]}" "setup"
    fi
  done

  # once we have the valid steps, we execute them
  for step_fn in "${USER_STEPS_OK[@]}"; do
    # message -i "Executing step $step_fn"
    $step_fn
  done

else

  # no steps specified, runs all the steps available
  message -w "No steps specified, running all steps..."
  if $UPDATE; then
    for step_fn in "${UPDATE_STEPS_AVAILABLE[@]}"; do
      $step_fn
    done
  else
    for step_fn in "${STEPS_AVAILABLE[@]}"; do
      $step_fn
    done
  fi

fi
