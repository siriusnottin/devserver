#!/bin/bash

shift

update=false

update_project() {
  # if <= 2.2.19
  if [ "$(grep -c "< 2.2.19" Vagrantfile)" -eq 1 ]; then
    # https://discourse.roots.io/t/vagrant-2-2-19-support/22720/3
    message -i "Updating the project to accept the latest version of Vagrant..."
    sed -i "s|< 2.2.19|<= 2.2.19|g" Vagrantfile || error ${FUNCNAME[0]} ${LINENO} "Failed to update Vagrantfile" 1
    message -s "Project updated"
    update=true
  fi
}

update_plugins() {
  if [ "$(uname -s)" == "Linux" ]; then
    if [ "$(uname -v | grep -c "Ubuntu")" -eq 1 ]; then
      # https://www.vagrantup.com/docs/cli/plugin#local-1
      vagrant plugin install --local vagrant-libvirt || error ${FUNCNAME[0]} ${LINENO} "Failed to update vagrant-libvirt" 1
      update=true
    fi
  fi
}

show_vagrant_box_private_key_path() {
  # /Users/sirius/Sites/wordpress.test/trellis/.vagrant/machines/default/virtualbox/private_key
  message -i "The private key path is: "
  message -c "$(vagrant ssh-config | grep IdentityFile | awk '{print $2}')"
  sep
}

do_vagrant_setup() {
  local project="$1"
  local path="$2"

  # do the setup
  cd "$path" >/dev/null || error ${FUNCNAME[0]} ${LINENO} "Failed to change to $path" 1
  update_project
  update_plugins
  show_vagrant_box_private_key_path
  cd - >/dev/null || error ${FUNCNAME[0]} ${LINENO} "Failed to change to $PWD" 1
  if $update; then
    message -s "✅ Project $project setup"
  fi

}

# check from where we are called. if we are called from the vagrant project, we do the setup
if [ -d trellis ] && [ -d site ]; then
  # we are in a project using vagrant, but not yet in the vagrant project
  project_path="$(pwd)/trellis"
  project_name="$(basename $(dirname $project_path))"
  do_vagrant_setup "$project_name" "$project_path"
elif [ -d trellis ]; then
  # we're already in a vagrant project
  project_path=$(pwd)
  project_name=$(basename $(dirname $project_path))
  do_vagrant_setup "$project_name" "$project_path"
else

  # if we;re not in a vagrant project, we retrieve all the vagrant projects and ask the user to select one to setup

  read -r -p "Projects folder: [$HOME/projects] " projects_folder
  projects_folder=${projects_folder:-$HOME/projects}
  projects_folder=$(echo $projects_folder | tr '[:upper:]' '[:lower:]')
  if [ ! -d "$projects_folder" ]; then
    error ${FUNCNAME[0]} ${LINENO} "Projects folder $projects_folder does not exist" 1
  fi

  # retrieve all the vagrant projects
  projects=$(find $projects_folder -maxdepth 2 -type d -name "trellis*" -print)
  for project in $projects; do
    # get the project name 1 level up
    projects_name+=($(basename $(dirname $project)))
  done

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
      do_vagrant_setup "$project" "$projects_folder/$project/trellis"
      break
    fi
  done

fi
