# My dev server setup

My setup for my development environment in a virtual machine. It's still a work in progress. The vm is running on my home lab with unraid. [See the specs here]().

I use this repo to share my setup and what I learned along the way. Also in case I need to restart from scratch :)

## TOC

- [My dev server setup](#my-dev-server-setup)
  - [TOC](#toc)
  - [Usefull commands](#usefull-commands)
    - [Manage VMs](#manage-vms)
    - [Allocate more space](#allocate-more-space)
  - [VM Specs](#vm-specs)
  - [VM Setup](#vm-setup)
  - [Software install and setup](#software-install-and-setup)
  - [Local Setup](#local-setup)
    - [Local hosts](#local-hosts)
    - [VS Code](#vs-code)
    - [iTerm2 + tmux = ❤️](#iterm2--tmux--️)
  - [Reflexion on the setup](#reflexion-on-the-setup)
    - [The VM and Unraid setup](#the-vm-and-unraid-setup)
    - [Files syncronization](#files-syncronization)
    - [VirtualBox](#virtualbox)

## Usefull commands

<details>

<summary>Show usefull commands</summary>

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

</details>

## VM Specs

The settings that I use to setup my VM. If a setting is not listed here, it's the default value.

- OS: Ubuntu Server 22.04 LTS
- 2 CPUs (Host passthrough)
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

1. Setup the server name, user and password. (and a **fixed IP**, regarding your network setup.)
2. Add ssh key to the vm. ([Maybe create a new one?](https://code.visualstudio.com/docs/remote/troubleshooting#_improving-your-security-with-a-dedicated-key))
3. Mount the shares: ([edit the fstab file](https://forums.unraid.net/topic/71600-unraid-vm-shares/?do=findComment&comment=658008))

```bash
mkdir {/home/sirius/projects,/home/sirius/virtualbox}
sudo echo -e "projects \t /home/sirius/projects \t 9p \t trans=virtio,version=9p2000.L,_netdev,rw 0 0" >> /etc/fstab
sudo echo -e "virtualbox \t /home/sirius/virtualbox \t 9p \t trans=virtio,version=9p2000.L,_netdev,rw 0 0" >> /etc/fstab
sudo mount -a
```

If multiple users, [for aditionnal security](https://code.visualstudio.com/docs/remote/troubleshooting#_improving-security-on-multi-user-servers):

```bash
sudo echo "AllowStreamLocalForwarding yes" >> /etc/ssh/sshd_config
sudo systemctl restart sshd
```

✅ **After following the [local setup](#local-setup), you should be able to connect to the vm with VS Code remotely.**

👀 Continue reading for additional software setup.

## Software install and setup

```bash
# Software update
sudo apt-get update && sudo apt-get upgrade -y

# Tree
sudo apt-get install tree

# Homebrew (https://brew.sh/)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/sirius/.bash_profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
sudo apt-get install build-essential
brew install gcc

# GitHub CLI (https://github.com/cli/cli)
brew install gh

gh auth login
gh auth setup-git
```

Todo: More software to install.

- zsh
- sync my dotfiles
- trellis
- vagrant

## Local Setup

### Local hosts

Also for sake of convenience:

On my **local machine** I configure the hosts file for easy access to the vm:

```bash
sudo echo -e "192.168.0.18\tdevserver" >> /etc/hosts
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

I can't believe I didn't use tmux before, it's a life saver and so easy to use!

## Reflexion on the setup

### The VM and Unraid setup

Well, it's all a WIP and woul love to try Proxmox or something else later to compare.

Also, I was a bit generous with the ram and cpu settings. (see the [VS Code requirements](https://code.visualstudio.com/docs/remote/ssh#_system-requirements))

### Files syncronization

I don't know yet if I should use `rsync` instead of an `unraid share` mounted on the vm, see the [remote development tips and tricks](https://code.visualstudio.com/docs/remote/troubleshooting#_using-rsync-to-maintain-a-local-copy-of-your-source-code) from the VS Code documentation.

For me in the absolute, it's ideal to use the unraid share so I can setup the smallest size for the vDisk and let the rest be dynamic (it's hard to resize the partitions 😅); for now I am experiencing some performance issues with Git… Any ideas regarding that? [Please comment on the Discussions section]()!

### VirtualBox

I have not succeeded installing/using virtualbox for the moment.

**Quick links** [Home Lab project](https://nottin.me/lab) • [Renovation project](https://siriusrenove.fr) • [Website](https://nottin.me) • [Twitter](https://twitter.com/siriusnottin)
