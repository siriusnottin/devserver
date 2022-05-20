# My dev server setup

My setup for my development environment in a virtual machine. **It's still a work in progress**. The vm is running on my home lab with Unraid.

I use this repo to share my setup and what I learned along the way. Also in case I need to restart from scratch :)

## TOC

- [My dev server setup](#my-dev-server-setup)
  - [TOC](#toc)
  - [Usefull commands](#usefull-commands)
    - [Manage VMs](#manage-vms)
    - [Allocate more space](#allocate-more-space)
  - [VM Specs](#vm-specs)
  - [VM Setup](#vm-setup)
  - [Local Setup](#local-setup)
    - [Local hosts](#local-hosts)
    - [VS Code](#vs-code)
    - [iTerm2 + tmux = ❤️](#iterm2--tmux--️)
  - [Todo](#todo)
  - [Reflexion on the setup](#reflexion-on-the-setup)
    - [The VM and Unraid setup](#the-vm-and-unraid-setup)
    - [Files syncronization](#files-syncronization)

## Usefull commands

### Manage VMs

```bash
virsh list --all
virsh start <vmname>
virsh shutdown <vmname>
```

### Allocate more space

```bash
qemu-img info <image>
qemu-img resize <image> <size>G
```

## VM Specs

The settings that I use to setup my VM. If a setting is not listed here, it's the default value.

- OS: [Ubuntu Server 22.04 LTS](https://ubuntu.com/download/server)
- 4 CPUs (Host passthrough)
- 4Go RAM
- BIOS: SeaBIOS
- vDisk size: 10G (my files are on a share bellow)
- Shares
  - `/projects`: all my local git repos.
  - `/virtualbox`: my virtualbox machines.
- Network bridge: br0 (so the vm is like a physical computer on my network.)

[XML file for the vm](/devserver_ubuntu.xml) • [Unraid setup]() • [Unraid share setup]()

## VM Setup

**Make sure to set a fixed IP address for the VM.**

On the vm first boot:

1. Keep all default settings. Set or Note the IP address depending on your network configuration.
2. Setup the server name, user and password.
3. Add ssh key to the vm. ([Maybe create a new one?](https://code.visualstudio.com/docs/remote/troubleshooting#_improving-your-security-with-a-dedicated-key))

Now
ssh into the vm ([see local setup](#local-hosts)) and clone this repo and execute the script:

```bash
ssh devserver
git clone https://github.com/siriusnottin/devserversetup.git
cd devserversetup
./setup.sh
```

## Local Setup

### Local hosts

Setup script for the local machine:
  
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/siriusnottin/devserversetup/main/local_setup.sh)"
```

### VS Code

See the official documentation : [VS Code remote overview](https://code.visualstudio.com/docs/remote/remote-overview)

1. Install the [Remote Development extension pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack).
2. Well, I don't have [multiple users on the vm](https://code.visualstudio.com/docs/remote/ssh#_ssh-host-setup), but we never know. On the local VS Code settings, set this to true:

```json
"remote.SSH.remoteServerListenOnSocket": true
```

✅ **At this point, you should be able to connect VS Code.**

### iTerm2 + tmux = ❤️

I just followed the [iTerm2 documentation](https://iterm2.com/documentation-tmux-integration.html).

My setup is the same as their example (for now):

1. local tmux profile: `/usr/local/bin/tmux -CC new -A -s main`
2. devserver tmux profile: `ssh -t devserver 'tmux -CC new -A -s main'`

## Todo

- [X] Make a script. (not tested yet! wait for the next install)
- [ ] Use [Starship theme](https://github.com/starship/starship): I did not succeded setting up this theme with znap.

## Reflexion on the setup

### The VM and Unraid setup

Well, it's all a WIP and woul love to try Proxmox or something else later to compare.

Also, I am still testing out the ram and cpu settings. (see the [VS Code requirements](https://code.visualstudio.com/docs/remote/ssh#_system-requirements))

### Files syncronization

I don't know yet if I should use `rsync` instead of an `unraid share` mounted on the vm, see the [remote development tips and tricks](https://code.visualstudio.com/docs/remote/troubleshooting#_using-rsync-to-maintain-a-local-copy-of-your-source-code) from the VS Code documentation.

For me in the absolute, it's ideal to use the unraid share so I can setup the smallest size for the vDisk and let the rest be dynamic ; for now I am experiencing some performance issues with Git…

**Quick links:** [Home Lab project](https://nottin.me/lab) • [Renovation project](https://siriusrenove.fr) • [Website](https://nottin.me) • [Twitter](https://twitter.com/siriusnottin)
