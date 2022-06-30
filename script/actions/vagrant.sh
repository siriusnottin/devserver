#!/bin/bash

shift

update_project() {
  message -i "Updating the project to accept the latest version of Vagrant..."
  # https://discourse.roots.io/t/vagrant-2-2-19-support/22720/2
  sed -i "s|< 2.2.19|<= 2.2.19|g" Vagrantfile || error ${FUNCNAME[0]} ${LINENO} "Failed to update Vagrantfile" 1
  message -s "Project updated"
}

update_plugins() {
  # Update vagrant-libvirt plugin
  # https://www.vagrantup.com/docs/cli/plugin#local-1
  vagrant plugin install --local vagrant-libvirt || error ${FUNCNAME[0]} ${LINENO} "Failed to update vagrant-libvirt" 1
}

do_vagrant_setup() {
  local project="$1"
  local path="$2"

  # do the setup
  sep
  message -m "Setting up the project $project"
  cd "$path" || error ${FUNCNAME[0]} ${LINENO} "Failed to change to $path" 1
  update_project
  update_plugins
  cd - || error ${FUNCNAME[0]} ${LINENO} "Failed to change to $PWD" 1
  message -s "✅ Project $project setup"
}

# retrieve all the vagrant projects
projects=$(find ~/projects -maxdepth 2 -type d -name "trellis*" -print)
for project in $projects; do
  # get the project name 1 level up
  projects_name+=($(basename $(dirname $project)))
done

# checks if a project is passed as an argument and if it is valid
if [ ! -z "$1" ] && [[ "${projects_name[*]}" =~ "$1" ]]; then
  do_vagrant_setup "$1" "${HOME}/projects/$1/trellis"
  exit 0
fi

# check from where we are called. if we are called from the vagrant project, we do the setup
if [ -d trellis ] && [ -d site ]; then
  # we are in a project using vagrant, but not yet in the vagrant project
  project_path="$(pwd)/trellis"
  project_name="$(basename $(dirname $project_path))"
  do_vagrant_setup "$project_name" "$project_path"
  cd -
elif [ -f Vagrantfile ] || [ -d trellis ]; then
  # we're already in a vagrant project
  project_path=$(pwd)
  project_name=$(basename $(dirname $project_path))
  do_vagrant_setup "$project_name" "$project_path"

else

  # if we;re not in a vagrant project, we retrieve all the vagrant projects and ask the user to select one to setup

  if [ ! -d ~/projects ]; then
    message -e "The ~/projects directory does not exist. Could not search for vagrant projects."
    exit 1
  fi

  if [ -z "${projects}" ]; then
    message -e "No vagrant projects found in $HOME/projects"
    exit 1
  fi

  # ask the user to select a project
  message -i "Please choose a project to setup (q to quit)"
  select project in "${projects_name[@]}"; do
    if [ "$project" == "q" ]; then
      exit 0
    elif [ -z "$project" ]; then
      error ${FUNCNAME[0]} ${LINENO} "No project selected" 1
    else
      do_vagrant_setup "$project" "${HOME}/projects/$project/trellis"
      break
    fi
  done

fi
