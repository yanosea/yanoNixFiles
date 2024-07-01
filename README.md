<div align="center">

# yanoNixFiles

nixfiles is mine.

</div>

## NixOS

### Initialize

1. Install NixOS following [here](https://nixos.org/manual/nixos/stable/#sec-installation-manual).

2. First, update the system. (You have to add your user to sodoers.)

```sh
# update the system
sudo nix-channel --add  https://nixos.org/channels/nixos-24.05 nixos && sudo nix-channel --update && sudo nixos-rebuild switch
```

3. Enter nix-shell with necessary packages.

```sh
# enter nix-shell
nix-shell -p cargo cargo-make ghq git
```

4. Clone this repository and change the directory.

```sh
# clone this repository and change the directory
ghq get yanosea/yanoNixFiles && cd ghq/github.com/yanosea/yanoNixFiles
```

5. Execute apply task.

```sh
# execute apply task
cargo make yanoNixOS:apply
```

6. Reboot NixOS.

```sh
# reboot nixos
reboot
```

7. Setup rclone config.

```sh
# change to root 
sudo -i
# make the directory
mkdir -p /mnt/google_drive/yanosea
# enter nix-shell
nix-shell -p rclone
# setup rclone
rclone config
# make symlink of rclone config
ln -s /root/.config/rclone/rclone.conf /.rclone.conf
# exit nix-shell
exit
# exit root
exit
```

8. Execute initialize task.

```sh
# execute initialize task
cargo make yanoNixOS:init
```

9. Then, you got a new NixOS environment ;)

### Edit config and install new packages

1. Edit your config in yanoNixFiles repository.

```sh
# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# then, edit config files or pkglist
```

2. Execute apply task.
```sh
# execute apply task
cargo make yanoNixOS:apply
```

3. If there were no issues, commit, push the changes.

### Update

1. Just execute update task.

```sh
# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# execute update task
cargo make yanoNixOS:update
```

## WSL

### Initialize

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
sudo nix-channel --add  https://nixos.org/channels/nixos-24.05 nixos && sudo nix-channel --update && sudo nixos-rebuild switch
# change to root 
sudo -i
# add user yanosea and set password
useradd yanosea && passwd yanosea
```

6. Enter nix-shell with necessary packages.

```sh
#
# on nixos
#

# enter nix-shell
nix-shell -p cargo cargo-make ghq git
```

7. Clone this repository and change the directory.

```sh
#
# on nixos
#

# clone this repository and change the directory
ghq get yanosea/yanoNixFiles && cd ghq/github.com/yanosea/yanoNixFiles
```

8. Execute initialize task. After this step, WSL will be shut down.

```sh
#
# on nixos
#

# execute initialize task
cargo make yanoNixOSWsl:init
```

9. Terminate the WSL and restart it.

```sh
#
# on windows
#
# terminate the WSL
wsl --terminate NixOS
# start the WSL
wsl -d NixOS --cd ~
```

10. Change the directory. Then, execute initialize after task.

```sh
#
# on nixos
#

# clone this repository and change the directory
ghq get yanosea/yanoNixFiles && cd ghq/github.com/yanosea/yanoNixFiles
# setup rust
rustup default stable
# init the configuration
cargo make yanoNixOSWsl:init_after
```

11. Then, you got a new NixOS WSL environment ;)

### Edit config and install new packages

1. Edit your config in yanoNixFiles repository.

```sh
#
# on nixos
#

# change the diretory
cd ghq/github.com/yanosea/yanoNixFiles
# then, edit config files or pkglist
```

2. Execute apply task.

```sh
#
# on nixos
#

# execute apply task
cargo make yanoNixOSWsl:apply
```

3. If there were no issues, commit, push the changes.

### Update

1. Just execute update task.

```sh
#
# on nixos
#

# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# execute update task
cargo make yanoNixOSWsl:update
```

## MacOS

### Initialize

1. Install nix following [here](https://github.com/DeterminateSystems/nix-installer).

2. Install homebrew following [here](https://brew.sh/ja/).

3. Install cargo-make and ghq with homebrew.

```sh
# install necessary packages with brew
brew install cargo cargo-make ghq git
```

4. Clone this repository and change the directory.

```sh
# clone this repository and change the directory
ghq get yanosea/yanoNixFiles && cd ghq/github.com/yanosea/yanoNixFiles
```

5. Execute initialize task.

```sh
# execute initialize task
cargo make yanoMac:init
```

6. Uninstall cargo-make and ghq with homebrew.

```sh
# uninstall unnecessary packages with brew
brew uninstall cargo cargo-make ghq git
```

7. Then, you got a new MacOS × Nix environment ;)

### Edit config and install new packages

1. Edit your config in yanoNixFiles repository.

```sh
# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# then, edit config files or pkglist
```

2. Execute apply task.
```sh
# execute apply task
cargo make yanoMac:apply
```

3. If there were no issues, commit, push the changes.

### Update

1. Just execute update task.

```sh
# change the directory
cd ghq/github.com/yanosea/yanoNixFiles
# execute update task
cargo make yanoMac:update
```
