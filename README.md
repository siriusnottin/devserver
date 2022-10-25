# My dev server setup

A script to create and manage my virtual machine on Unraid or my Mac. Feel free to check it out and contribute if you can!

I also use this repo to share my setup and what I learned along the way. Also in case I need to restart from scratch :)

**Currently this repo is a work in progress.**

## Requirements

- MacOS or Ubuntu 22.04
- Shell: Bash v4.4+ or Zsh v5.8+

**Note:** Zsh will automatically be installed and selected as your default shell by the script if you launch the setup.

## What the script can do

- Create or delete a new VM from a [template](devserver.xml)
- ~~Create a new VM with custom settings (name, memory, etc)~~ (not implemented yet, help is welcome)
- Get the infos of a VM (name, IP, etc)
- Allocate more disk space to a VM (and resize the vdisk automatically)
- Setup local hosts (no need to manually get the vm IP)
- Install or update predefined software and settings ([see the full list here](script/steps/))
- Custom setup for Trellis

Do `devserver help` once the script is installed to get more detailed information.

## Usefull commands

Because they are new to me and I forget them, I will list them here:

### Manage VMs

```bash
virsh list --all
virsh start <vmname>
virsh shutdown <vmname>
```

### Show the total allocated/used space for the vm

```bash
ssh -t unraid "qemu-img info <vmname>" # shows the total allocated space for the vm
ssh -t <vmname> "devserver vm --disk info" # shows the total used space by the vm

# If the vm doesn't use all the allocated space, you can resize it with:
ssh -t <vmname> "devserver vm --disk resize"
```

**Note:** normally you don't need to do all of this because the script will do the check for you, and will resize the disk to use all the space if needed.

So, if you just changed the size of the vm and want it to effectively use all the space, you can just run the last command shown above.

## VM Specs

The settings that I use to setup my VM. If a setting is not listed here, it's the default value.

- OS: [Ubuntu Server 22.04 LTS](https://ubuntu.com/download/server)
- 4 CPUs (Host passthrough)
- 4Go RAM
- BIOS: SeaBIOS
- vDisk size: 40G (my files are on a share bellow)
- Shares (setup by the script)
  - `/mnt/projects`: all my git repos.
  - `/mnt/virtualbox`: my virtualbox machines.
- Network bridge: br0 (so the vm is like a physical computer on my network.)
  But it can also work if the network interface is managed by the VM engine.

[XML file for the vm](/devserver_ubuntu.xml) • [Unraid setup]() • [Unraid share setup]()

## VM Setup

On the vm first boot:

1. Keep all default settings.
2. Setup the server name, user and password.
3. Add ssh key to the vm. ([Maybe create a new one?](https://code.visualstudio.com/docs/remote/troubleshooting#_improving-your-security-with-a-dedicated-key))

## Script Installation

On your local machine:
```bash
git clone https://github.com/siriusnottin/devserver.git ~/.devserver && bash ~/.devserver/script/script_setup.sh
```

This command will clone the repo and install the script both locally and remotely.

### VS Code

See the official documentation : [VS Code remote overview](https://code.visualstudio.com/docs/remote/remote-overview)

1. Install the [Remote Development extension pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack).
2. If you have [multiple users on the vm](https://code.visualstudio.com/docs/remote/ssh#_ssh-host-setup). On the local VS Code settings, set this to true:

```json
"remote.SSH.remoteServerListenOnSocket": true
```

✅ **At this point, you should be able to connect VS Code.**

### iTerm2 + tmux = ❤️

I just followed the [iTerm2 documentation](https://iterm2.com/documentation-tmux-integration.html).

My setup is the same as their example (for now):

- local: local tmux profile: `tmux -CC new -A -s main`
- devserver: devserver tmux profile: `ssh -t devserver 'tmux -CC new -A -s main'`

### Export variables for hass-cli

[home-assistant-ecosystem/home-assistant-cli: Command-line tool for Home Assistant](https://github.com/home-assistant-ecosystem/home-assistant-cli)

[1Password CLI](https://developer.1password.com/docs/cli) is required.

```bash
# op item get 'Home Assistant' --vault Personal --fields label=local_ip # doesn't work…

# first export the HA local URL to the variable for the cli to use
export HASS_SERVER="$(op item get 'Home Assistant' --vault Personal | grep 'local_ip' | awk '{print $2}')"

# then export and inject the personal token, also for the cli!
export HASS_TOKEN_REF="op://Personal/Home Assistant/hass_cli_token"
export HASS_TOKEN="$(op run --no-masking -- printenv HASS_TOKEN_REF)"
```

Test it with:

```bash
$ hass-cli state list | head -n 2 >/dev/null && echo ok || echo failed
ok
```

```bash
  # Toggle my workspace speaker
  hass-cli service call homeassistant.toggle --arguments entity_id=switch.enceinte_bureau_salon >/dev/null
```

## Todo

- [X] Make a script.
- [X] Use [Starship theme](https://github.com/starship/starship): I did not succeded setting up this theme with znap.
- [X] Fix the commands that can't be executed from this script. ([Issue #1](https://github.com/siriusnottin/devserver/issues/1))
- [ ] Add a command to create a new vm.
- [ ] List all my mac apps to install them using brew.
- [ ] GitHub action to check the steps.
- [ ] Refactor.

## Reflexion on the setup

### The VM and Unraid setup

Well, it's all a WIP and woul love to try Proxmox or something else later to compare.

Also, I am still testing out the ram and cpu settings. (see the [VS Code requirements](https://code.visualstudio.com/docs/remote/ssh#_system-requirements))

### Files syncronization

I don't know yet if I should use `rsync` instead of an `unraid share` mounted on the vm, see the [remote development tips and tricks](https://code.visualstudio.com/docs/remote/troubleshooting#_using-rsync-to-maintain-a-local-copy-of-your-source-code) from the VS Code documentation.

For me in the absolute, it's ideal to use the unraid share so I can setup the smallest size for the vDisk and let the rest be dynamic ; for now I am experiencing some performance issues with Git…

**Quick links:** [Home Lab project](https://siriusrenove.fr/lab) • [Renovation project](https://siriusrenove.fr) • [Website](https://nottin.me) • [Twitter](https://twitter.com/siriusnottin)
