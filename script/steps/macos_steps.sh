#!/bin/bash

step_xcode_dev_tools() {

  ###################################################################
  step "Xcode Dev Tools"
  ###################################################################

  message -i "Checking if Xcode Dev Tools is already installed..."
  if xcode-select --print-path &>/dev/null; then
    message -w "Xcode Dev Tools is already installed. Skipping..."
  else
    message -i "Xcode Dev Tools is not installed."
    message -i "Installing Xcode Dev Tools..."
    xcode-select --install || error "Failed to install Xcode Dev Tools"
    message -s "Xcode Dev Tools installed."
  fi

}

step_check_mac_apps() {

  ###################################################################
  step "Check Mac Apps"
  ###################################################################

  message -i "Checking for installed Mac apps..."
  sep

  local excluded_publishers=(Adobe)

  for app_folder in /Applications/*; do

    app_name=$(basename "$app_folder" | sed 's/\.app//')
    if [[ $app_name == *.app ]]; then
      app_path = "$app_folder"
    fi
    app_path=$(find -L "$app_folder" -type d -name "*.app" | head -n 1)
    app_publisher=$(
      mdls -name "kMDItemCFBundleIdentifier" "$app_path" |
        sed 's/kMDItemCFBundleIdentifier = //' |
        sed 's/"//g' |
        awk -F. '{print $2}' |
        sed 's/[^a-zA-Z0-9]//g' |
        awk '{print toupper(substr($1,1,1)) substr($1,2)}'
    )
    mac_apps+=("$app_name")

    local reason
    if [[ -z $app_path ]]; then
      reason="nopath"
      macapps_inerror+=("$app_name ($reason)")
    elif [[ ${excluded_publishers[*]} =~ $app_publisher ]]; then
      reason="excluded"
      excluded_macapps+=("$app_name ($reason)")
    fi

    # clean the app name to search with brew
    app_name_clean=$(echo $app_name | sed 's/[^a-zA-Z0-9 ]//g' | sed 's/ /-/g' | tr '[:upper:]' '[:lower:]')
    macapps_tocheck+=("$app_name_clean")
    # if the app name had any spaces that were replaced with "-" (a dash),
    # then both the name and the name with dashes will be saved to be check with brew.
    # So for example the app "Google Chrome" will be searched with both "google-chrome" and "googlechrome"
    [[ $app_name_clean =~ "-" ]] && macapps_tocheck+=("$(echo $app_name_clean | sed 's/-//g')")

  done

  message -s "Found ${#mac_apps[@]} Mac apps."
  message -c "${#excluded_macapps[@]} excluded (${excluded_macapps[*]})"
  message -e "${#macapps_inerror[@]} in error. It can be from an incomplete uninstallation or a broken app. (${macapps_inerror[*]})"
  sep

  message -i "Checking if the app is available to install with Homebrew..."
  local casks=$(mktemp /tmp/brew_casks.XXXXXX) || script_error ${FUNCNAME[0]} $LINENO "Failed to create temp file" 1
  brew search --casks --desc '' >"$casks" || script_error ${FUNCNAME[0]} $LINENO "Failed to search for casks" 1
  for app in "${macapps_tocheck[@]}"; do
    if grep -qi "$app" "$casks"; then
      mac_apps_brew+=($app)
    # brew install --cask "$app" || error "Failed to install $app" 1
    else
      mac_apps_not_brew+=($app)
    fi
  done
  rm "$casks" || script_error ${FUNCNAME[0]} $LINENO "Failed to remove temp file" 1

  message -s "${#mac_apps_brew[@]}/${#mac_apps[@]} Mac apps are available to install with Homebrew."
  sep

  message -e "These apps are not available to install with Homebrew:"
  sep
  for app in "${mac_apps_not_brew[@]}"; do
    message -e "$app"
  done

}

step_install_mac_apps() {

  ###################################################################
  step "Mac Apps"
  ###################################################################

  export HOMEBREW_NO_AUTO_UPDATE=1

  local qlplugins=(
    qlcolorcode
    qlstephen
    qlmarkdown
    quicklook-json
    qlprettypatch
    betterzip
    quicklook-csv
    quicklook-xml
    quicklook-yaml
    quicklook-icns
    webpquicklook
    suspicious-package
  )

  local apps=(
    google-chrome
    chrome-cli
    iterm2
    visual-studio-code
    bartender
    homeassistant-cli
  )

  sep -l "Installing Mac Apps"
  sep
  install_app macos --cask "${apps[*]}"
  sep

  sep -l "Installing Quick Look Plugins"
  sep
  install_app macos --cask "${qlplugins[*]}"
  sep

  export HOMEBREW_NO_AUTO_UPDATE=0

}
