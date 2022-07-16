# Steps available in the script

The list of all steps available in the script.

**Usage:**

```bash
devserver setup # Launch the install for the current system
devserver update # Update all software on the current system

devserver setup --step <step> # Launch specific step
devserver setup --steps <step> # Launch multiple steps
# Note the s is optional, you can use --steps or --step

devserver setup --steps # Shows the list of steps
```

## Global Steps

The steps will execute on both MacOS and Ubuntu.

### update_software (setup, update)

Update all software on the current system.

### projects (setup)

Create a project folder in the user home directory.

### update_software_dist (on-demand)

Update the system.

### default_shell (setup)

Set the default shell to Zsh.

### znap (setup, update)

Install Znap.

### zsh_config (setup)

Check if the zsh config file is up to date. (Will also install **Oh my zsh** and **nvm**)

### homebrew (setup, update)

Install Homebrew.

### github (setup)

Install GitHub CLI, start the login process, and setup Git.

### git (setup)

- Set the default git branch to the user's choice (default: main).
- Set the default git user name and email to the user's choice.

### trellis (setup)

Install Trellis.

### ngrok (setup)

Install ngrok.

### composer (setup)

Install Composer.

### nvm (setup, update)

Install NVM.

### node (setup, update)

### yarn (setup)

### additional_software (setup)

---

## MacOS

### xcode_dev_tools (setup)

Install Xcode Dev Tools.

### check_mac_apps (on-demand)

- Get all your installed MacOS apps.
- Sort out the apps that were incorrectly uninstalled or can't be executed.
- Filter out the apps that can't be installed using Homebrew.

### install_mac_apps (setup)

Install apps predifined in the script.

### code_remote_ssh (setup)

Install the Vs Code Remote SSH extension.

---

## Ubuntu

### timezone (setup)

Set the timezone to Europe/Paris.

### shares (setup)

Setup, configure and mount the shares:

Default are: (you will be asked to choose the share you want to create)

- projects
- virtualbox

### php (setup)

Install PHP 8+ (preconfigured to work with Trellis).
