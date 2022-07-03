#!/bin/bash

last_exit_fn_log="$SCRIPT_DIR/logs/last_exit_fn.log"

script_log_step_execution_now() {
  printf "%s\t%s\n" "${FUNCNAME[1]//_step/}" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" >>$last_exit_fn_log || script_error ${FUNCNAME[0]} ${LINENO} "Could not write last exit function to file" 1
}

step_last_exec_time_elapsed_min() {
  # if the step was executed, we return the time elapsed since last execution
  # arg1: step name
  # return: time elapsed in minutes
  if [ ! -f $last_exit_fn_log ]; then
    script_error ${FUNCNAME[0]} ${LINENO} "File $last_exit_fn_log does not exist" 1
  elif [ -z "$1" ]; then
    script_error ${FUNCNAME[0]} ${LINENO} "Step name cannot be empty" 1
  fi

  local step_last_exit_time="$(grep "$1" $last_exit_fn_log | tail -1 | awk '{print $2}')"
  local step_last_exit_time="$(date -d "$step_last_exit_time" +%s)"

  [ -z ${step_last_exit_time// /} ] && exit 0

  local now=$(date -u +%s)

  # time diff in minutes
  local time_diff="$(((now - step_last_exit_time) / 60))"

  printf "%d" "$time_diff"
}

step_was_executed_time() {
  # arg1: step name
  # arg2: time in minutes
  # returns 0 if the step was executed in the last $arg2 minutes
  # returns 1 otherwise
  [ -n $1 ] && script_error ${FUNCNAME[0]} ${LINENO} "Step name cannot be empty" 1
  local time_elapsed=$(step_last_exec_time_elapsed_min $1)
  local max_time=${2:-10}
  [[ -n $time_elapsed || $time_elapsed -gt max_time ]] || message -w "Step $1 was already run on the past $max_time minutes. Skipping..."
}
