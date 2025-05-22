<div align="center">

# ❄️ yanoNixFiles

dotfile is mine.

</div>

## ⚠️ WARNING

- This is my personal dotfiles using nix or nixos.
- This flake depends on other package managers such as homebrews.
  - Also, the configuration for each tool use Nix as little as possible.
  - This is to facilitate the porting of dotfiles even if I stop using Nix in the future.

## ❄️ NixOS

### 🌠 Initialize

1. Install NixOS following [here](https://nixos.org/manual/nixos/stable/#sec-installation-manual). Example installation steps are below.

```sh
# create a gpt partition table on the disk
parted /dev/sda -- mklabel gpt
# create a root partition
# it starts from 512MB of the disk and ends at the part excluding 64gb from the end of the disk
parted /dev/sda -- mkpart root ext4 512MB -64GB
# create a swap partition
# it occupies the part of 64gb from the end of the disk
parted /dev/sda -- mkpart swap linux-swap -64GB 100%
# create an esp partition
# it occupies the part from 1MB to 512mb of the disk
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
# set the esp flag on the esp partition
parted /dev/sda -- set 3 esp on
# create an ext4 filesystem on /dev/sda1 and label it as 'nixos'
mkfs.ext4 -L nixos /dev/sda1
# set up a linux swap area on /dev/sda2 and label it as 'swap'
mkswap -L swap /dev/sda2
# create a fat32 filesystem on /dev/sda3 and label it as 'boot'
mkfs.fat -F 32 -n boot /dev/sda3
# mount the 'nixos' partition to the /mnt directory
mount /dev/disk/by-label/nixos /mnt
# create a new directory /mnt/boot and mount the 'boot' partition to the /mnt/boot directory with umask set to 077
mkdir -p /mnt/boot  && mount -o umask=077 /dev/disk/by-label/boot /mnt/boot
# enable the swap partition
swapon /dev/sda2
# generate a nixos configuration file for the system
nixos-generate-config --root /mnt
# install NixOS on the system
nixos-install
# reboot the system
reboot
# login as root
# create a new user 'yanosea' with a home directory
useradd  -m yanosea
# set or change password for user 'yanosea'
passwd yanosea
# add user 'yanosea' sudoers
visudo
# add below
yanosea ALL=(ALL:ALL) SETENV:ALL
# exit from root and login as yanosea
exit
```

2. First, update the system. (You have to add your user to sudoers.)

```sh
# update the system
sudo nix-channel --add  https://nixos.org/channels/nixos-24.11 nixos && sudo nix-channel --update && sudo nixos-rebuild switch
# you may have to add your user to sudoers again
```

3. Enter nix-shell with necessary packages.

```sh
# enter nix-shell
nix-shell -p git ghq home-manager
```

4. Clone this repository and change the directory.

```sh
# clone this repository and change the directory
ghq get yanosea/yanoNixFiles && cd ghq/github.com/yanosea/yanoNixFiles
```

5. Execute init task.

```sh
# execute init task
make nix.init
```

6. Reboot NixOS.

```sh
# reboot nixos
reboot
```

7. Then, you got a new NixOS environment ;)

### 🔧 Edit config and install new packages

1. Edit your config in yanoNixFiles repository.

```sh
# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# then, edit config files or pkglist
```

2. Execute install task.

```sh
# execute install task
make nix.install
```

3. If there were no issues, commit, push the changes.

### ✨ Update

1. Just execute update task.

```sh
# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# execute update task
make nix.update
```

## 🪟 WSL

### 🌠 Initialize

1. Download nixos-wsl.tar.gz from [the latest release](https://github.com/nix-community/NixOS-WSL/releases/latest).

2. Make the directory and move the downloaded file to the directory. Then, change the directory.

```sh
#
# on windows
#

# make the directory and move the downloaded file
mkdir -p .\.local\share\wsl\nixos && mv .\Downloads\nixos-wsl.tar.gz .\.local\share\wsl\nixos
```

3. Import the tarball.

```sh
#
# on windows
#

# if you already have NixOS WSL env, unregister it
wsl --unregister NixOS
# change directory and import the tarball
cd .local\share\wsl\nixos && wsl --import NixOS . nixos-wsl.tar.gz --version 2
```

4. Start the WSL.

```sh
#
# on windows
#

# start the WSL
wsl -d NixOS --cd ~
```

5. First, update the system. Then, add user yanosea.

```sh
#
# on nixos
#

# update the system
sudo nix-channel --add  https://nixos.org/channels/nixos-24.11 nixos && sudo nix-channel --update && sudo nixos-rebuild switch
# change to root
sudo -i
# add user yanosea and set password
useradd yanosea && passwd yanosea
# edit sudoers
visudo
# add below
yanosea ALL=(ALL:ALL) SETENV:ALL
# create home directory of yanosea and change ownership
mkdir -p /home/yanosea && chown yanosea /home/yanosea && chgrp users /home/yanosea
# switch to yanosea
su - yanosea
```

6. Enter nix-shell with necessary packages.

```sh
#
# on nixos
#

# enter nix-shell
nix-shell -p git ghq home-manager
```

7. Clone this repository and change the directory.

```sh
#
# on nixos
#

# clone this repository and change the directory
ghq get yanosea/yanoNixFiles && cd ghq/github.com/yanosea/yanoNixFiles
```

8. Execute initialize task. After this step, exit from WSL.

```sh
#
# on nixos
#

# execute initialize task
make wsl.init
# exit from WSL (you have to type this many times)
exit
```

9. Terminate WSL and restart it.

```sh
#
# on windows
#
# terminate the WSL
wsl --terminate NixOS
# start the WSL
wsl -d NixOS --cd ~
```

10. Then, you got a new NixOS WSL environment ;)

### 🔧 Edit config and install new packages

1. Edit your config in yanoNixFiles repository.

```sh
#
# on nixos
#

# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# then, edit config files or pkglist
```

2. Execute install task.

```sh
#
# on nixos
#

# execute install task
make wsl.install
```

3. If there were no issues, commit, push the changes.

### ✨ Update

1. Just execute update task.

```sh
#
# on nixos
#

# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# execute update task
make wsl.update
```

## 🍎 Darwin

### 🌠 Initialize

1. Install nix following [here](https://github.com/DeterminateSystems/nix-installer).

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

2. Install nix-darwin following [here](https://github.com/LnL7/nix-darwin).

3. Install homebrew following [here](https://brew.sh/ja/).

4. First, update the system. (You have to add your user to sudoers.)

```sh
# update the system
sudo nix-channel --add  https://nixos.org/channels/nixos-24.11 nixos && sudo nix-channel --update && sudo darwin-rebuild switch
```

5. Enter nix-shell with necessary packages.

```sh
# enter nix-shell
nix-shell -p git ghq home-manager
```

6. Clone this repository and change the directory.

```sh
# clone this repository and change the directory
ghq get yanosea/yanoNixFiles && cd ghq/github.com/yanosea/yanoNixFiles
```

7. Execute initialize task.

```sh
# execute initialize task
make mac.init
# or
make macbook.init
```

8. Edit /etc/shells and chsh. After this step, exit from the shell.

```sh
# edit /etc/shells
vim /etc/shells
# add below
# /Users/yanosea/.nix-profile/bin/zsh
# chsh
chsh -s /Users/yanosea/.nix-profile/bin/zsh
# exit from the shell (you have to type this many times)
exit
```

9. Install command line developer tool.

```sh
# install command line developer tool
xcode-select --install
```

10. Then, you got a new Darwin × Nix environment ;)

### 🔧 Edit config and install new packages

1. Edit your config in yanoNixFiles repository.

```sh
# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# then, edit config files or pkglist
```

2. Execute install task.

```sh
# execute apply task
make mac.install
# or
make macbook.install
```

3. If there were no issues, commit, push the changes.

### ✨ Update

1. Just execute update task.

```sh
# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# execute update task
make mac.update
# or
make macbook.update
```

## 📚 Refferences

I appreciate a lot to all the following articles and repositories🙏

### ❄️ nix

#### 📄 articles

- [❄ NixOSで最強のLinuxデスクトップを作ろう](https://zenn.dev/asa1984/articles/nixos-is-the-best)
- [NixOSとHyprlandで最強のLinuxデスクトップ環境を作る](https://zenn.dev/asa1984/scraps/e4d8b9947d8351)
- [📦 Nixでlinuxとmacの環境を管理してみる](https://blog.ymgyt.io/entry/declarative-environment-management-with-nix/)

#### 🗂 repos

- [asa1984/dotfiles](https://github.com/asa1984/dotfiles)
- [ymgyt/mynix](https://github.com/ymgyt/mynix)
