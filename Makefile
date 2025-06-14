# initialize variables
IS_WINDOWS := 0
IS_DARWIN := 0
IS_MAC := 0
IS_MACBOOK := 0
IS_NIXOS := 0
IS_NIXOS_WSL := 0
# check if windows
ifeq ($(OS),Windows_NT)
	IS_WINDOWS := 1
	SHELL := pwsh.exe
else
	SHELL := /usr/bin/env bash
	# detect other platforms
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Darwin)
		IS_DARWIN := 1
		# detect if macbook (portable) or mac (desktop)
		IS_MACBOOK := $(shell [ "$$(sysctl -n hw.model | grep -i "MacBook")" != "" ] && echo 1 || echo 0)
		ifeq ($(IS_MACBOOK),0)
			IS_MAC := 1
		endif
	else
		# check if nixos or wsl
		# first check if it's wsl
		IS_WSL := $(shell [ -f /proc/sys/fs/binfmt_misc/WSLInterop ] || grep -q "microsoft\|WSL" /proc/version 2>/dev/null && echo 1 || echo 0)
		# then check if it's nixos (directory exists)
		IS_NIXOS_CHECK := $(shell [ -d /etc/nixos ] && echo 1 || echo 0)
		# if it's both WSL and nixos, then it's nixos on wsl
		ifeq ($(IS_WSL)$(IS_NIXOS_CHECK),11)
			IS_NIXOS_WSL := 1
		# if it's just nixos, but not wsl
		else ifeq ($(IS_NIXOS_CHECK),1)
			IS_NIXOS := 1
		endif
	endif
endif
# define colors
ifeq ($(IS_WINDOWS),1)
	COLOR_TITLE := -ForegroundColor Magenta
	COLOR_HEADER := -ForegroundColor Yellow
	COLOR_CMD := -ForegroundColor Cyan
	COLOR_DONE := -ForegroundColor Green
	COLOR_ERROR := -ForegroundColor Red
else
	COLOR_RESET  := $(shell tput sgr0)
	COLOR_TITLE  := $(shell tput setaf 5) # magenta
	COLOR_HEADER := $(shell tput setaf 3) # yellow
	COLOR_CMD    := $(shell tput setaf 6) # cyan
	COLOR_DONE   := $(shell tput setaf 2) # green
	COLOR_ERROR  := $(shell tput setaf 1) # red
endif
# shows help message defaultly
.DEFAULT_GOAL := help

# do not show directory name in command output
MAKEFLAGS += --no-print-directory

# not show command all
.SILENT:

# ignore errors all
.IGNORE:

#
# nixos
#
.PHONY: nixos.update nixos.apply.system nixos.apply.home

# initialize nixos (these are notes for the initial environment construction)
# nixos.init:
# ifeq ($(IS_NIXOS),1)
# 	@echo ""
# 	@echo "$(COLOR_TITLE)initialize nixos...$(COLOR_RESET)"
# 	@echo ""
# 	make nixos.apply.system
# 	@echo ""
# 	make nixos.apply.home
# 	@echo ""
# 	@echo "$(COLOR_HEADER)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_HEADER)initialize rclone...$(COLOR_RESET)"
# 	@echo ""
# 	sudo mkdir -p /mnt/google_drive/yanosea
# 	sudo rclone config
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary symbolic links...$(COLOR_RESET)"
# 	@echo ""
# 	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/nixos/clipboard-history $$HOME/.local/bin/clipboard-history
# 	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/nixos/ime $$HOME/.local/bin/ime
# 	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/nixos/check-recording $$HOME/.local/bin/check-recording
# 	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/common/installGitEmojiPrefixTemplate $$HOME/.local/bin/installGitEmojiPrefixTemplate
# 	sudo ln -s /root/.config/rclone/rclone.conf /.rclone.conf
# 	ln -s /mnt/google_drive/yanosea $$HOME/google_drive
# 	ln -s $$HOME/google_drive/credentials $$XDG_DATA_HOME/credentials
# 	ln -s $$XDG_DATA_HOME/credentials/github-copilot/apps.json $$XDG_CONFIG_HOME/github-copilot/apps.json
# 	ln -s $$XDG_DATA_HOME/credentials/wakatime/.wakatime.cfg $$XDG_CONFIG_HOME/wakatime/.wakatime.cfg
# 	ln -s $$XDG_CONFIG_HOME/vim $$HOME/.vim
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# 	@echo ""
# 	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"
# 	@echo ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for nixos...$(COLOR_RESET)"
# 	@echo ""
# endif

# update nixos packages and apply configurations
nixos.update:
ifeq ($(IS_NIXOS),1)
	@echo "$(COLOR_TITLE)update nixos...$(COLOR_RESET)"
	@echo ""
	make nixos.apply.system
	@echo ""
	make nixos.apply.home
	@echo ""
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for nixos...$(COLOR_RESET)"
endif

# apply system configuration
nixos.apply.system:
ifeq ($(IS_NIXOS),1)
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo nixos-rebuild switch --flake .#yanoNixOs
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for nixos...$(COLOR_RESET)"
endif

# apply home configuration
nixos.apply.home:
ifeq ($(IS_NIXOS),1)
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	home-manager switch --flake .#yanosea@yanoNixOs
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for nixos...$(COLOR_RESET)"
endif

#
# nixos wsl
#
.PHONY: nixoswsl.update nixoswsl.apply.system nixoswsl.apply.home

# initialize nixos wsl (these are notes for the initial environment construction)
# nixoswsl.init:
# ifeq ($(IS_NIXOS_WSL),1)
# 	@echo ""
# 	@echo "$(COLOR_TITLE)initialize nixos wsl...$(COLOR_RESET)"
# 	@echo ""
# 	make nixoswsl.apply.system
# 	@echo ""
# 	make nixoswsl.apply.home
# 	@echo ""
# 	@echo "$(COLOR_HEADER)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary symbolic links...$(COLOR_RESET)"
# 	@echo ""
# 	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/common/installGitEmojiPrefixTemplate $$HOME/.local/bin/installGitEmojiPrefixTemplate
# 	ln -s <GOOGLE_DRIVE_PATH> $$HOME/google_drive
# 	ln -s $$HOME/google_drive/credentials $$XDG_DATA_HOME/credentials
# 	ln -s $$XDG_DATA_HOME/credentials/github-copilot/apps.json $$XDG_CONFIG_HOME/github-copilot/apps.json
# 	ln -s $$XDG_DATA_HOME/credentials/wakatime/.wakatime.cfg $$XDG_CONFIG_HOME/wakatime/.wakatime.cfg
# 	ln -s $$XDG_CONFIG_HOME/vim $$HOME/.vim
# 	ln -s <WINDOWS_HOME_PATH> $$HOME/windows_home
# 	ln -s <WINDOWS_WIN32YANK_PATH> $$HOME/.local/bin/win32yank.exe
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# 	@echo ""
# 	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"
# 	@echo ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for nixos wsl...$(COLOR_RESET)"
# 	@echo ""
# endif

# update nixos wsl packages and apply configurations
nixoswsl.update:
ifeq ($(IS_NIXOS_WSL),1)
	@echo "$(COLOR_TITLE)update nixos wsl...$(COLOR_RESET)"
	@echo ""
	make nixoswsl.apply.system
	@echo ""
	make nixoswsl.apply.home
	@echo ""
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for nixos wsl...$(COLOR_RESET)"
endif

# apply system configuration
nixoswsl.apply.system:
ifeq ($(IS_NIXOS_WSL),1)
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo nixos-rebuild switch --flake .#yanoNixOsWsl
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for nixos wsl...$(COLOR_RESET)"
endif

# apply home configuration
nixoswsl.apply.home:
ifeq ($(IS_NIXOS_WSL),1)
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	home-manager switch --flake .#yanosea@yanoNixOsWsl
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for nixos wsl...$(COLOR_RESET)"
endif

#
# mac
#
.PHONY: mac.update mac.apply.system mac.apply.home

# initialize mac (these are notes for the initial environment construction)
mac.init:
# ifeq ($(IS_MAC),1)
# 	@echo ""
# 	@echo "$(COLOR_TITLE)initialize mac...$(COLOR_RESET)"
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install homebrew...$(COLOR_RESET)"
# 	@echo ""
# 	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# 	@echo ""
# 	make mac.apply.system
# 	@echo ""
# 	make mac.apply.home
# 	@echo ""
# 	@echo "$(COLOR_HEADER)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary symbolic links...$(COLOR_RESET)"
# 	@echo ""
# 	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/common/installGitEmojiPrefixTemplate $$HOME/.local/bin/installGitEmojiPrefixTemplate
# 	ln -s <GOOGLE_DRIVE_PATH> $$HOME/google_drive
# 	ln -s $$HOME/google_drive/credentials $$XDG_DATA_HOME/credentials
# 	ln -s $$XDG_DATA_HOME/credentials/github-copilot/apps.json $$XDG_CONFIG_HOME/github-copilot/apps.json
# 	ln -s $$XDG_DATA_HOME/credentials/wakatime/.wakatime.cfg $$XDG_CONFIG_HOME/wakatime/.wakatime.cfg
# 	ln -s $$XDG_CONFIG_HOME/vim $$HOME/.vim
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# 	@echo ""
# 	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"
# 	@echo ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for mac...$(COLOR_RESET)"
# 	@echo ""
# endif

# update mac packages and apply configurations
mac.update:
ifeq ($(IS_MAC),1)
	@echo "$(COLOR_TITLE)update mac...$(COLOR_RESET)"
	@echo ""
	make mac.apply.system
	@echo ""
	make mac.apply.home
	@echo ""
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for mac...$(COLOR_RESET)"
endif

# apply mac system configuration
mac.apply.system:
ifeq ($(IS_MAC),1)
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo darwin-rebuild switch --flake .#yanoMac
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for mac...$(COLOR_RESET)"
endif

# apply mac home configuration
mac.apply.home:
ifeq ($(IS_MAC),1)
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	rm -fr ~/.config/karabiner/karabiner.json
	home-manager switch --flake .#yanosea@yanoMac
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for mac...$(COLOR_RESET)"
endif

#
# macbook
#
.PHONY: macbook.update macbook.apply.system macbook.apply.home

# initialize macbook (these are notes for the initial environment construction)
# macbook.init:
# ifeq ($(IS_MACBOOK),1)
# 	@echo ""
# 	@echo "$(COLOR_TITLE)initialize macbook...$(COLOR_RESET)"
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install homebrew...$(COLOR_RESET)"
# 	@echo ""
# 	/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# 	@echo ""
# 	make macbook.apply.system
# 	@echo ""
# 	make macbook.apply.home
# 	@echo ""
# 	@echo "$(COLOR_HEADER)load zsh configuration...$(COLOR_RESET)"
# 	@echo ""
# 	source $$HOME/.config/zsh/.zshenv && source $$HOME/.config/zsh/.zshrc
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary directories...$(COLOR_RESET)"
# 	@echo ""
# 	mkdir -p $$HOME/.local/bin
# 	mkdir -p $$XDG_DATA_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/skk
# 	mkdir -p $$XDG_STATE_HOME/zsh
# 	mkdir -p $$XDG_CONFIG_HOME/github-copilot
# 	mkdir -p $$XDG_CONFIG_HOME/wakatime
# 	@echo ""
# 	@echo "$(COLOR_HEADER)make necessary symbolic links...$(COLOR_RESET)"
# 	@echo ""
# 	ln -s $$HOME/ghq/github.com/yanosea/yanoNixFiles/scripts/utils/common/installGitEmojiPrefixTemplate $$HOME/.local/bin/installGitEmojiPrefixTemplate
# 	ln -s <GOOGLE_DRIVE_PATH> $$HOME/google_drive
# 	ln -s $$HOME/google_drive/credentials $$XDG_DATA_HOME/credentials
# 	ln -s $$XDG_DATA_HOME/credentials/github-copilot/apps.json $$XDG_CONFIG_HOME/github-copilot/apps.json
# 	ln -s $$XDG_DATA_HOME/credentials/wakatime/.wakatime.cfg $$XDG_CONFIG_HOME/wakatime/.wakatime.cfg
# 	ln -s $$XDG_CONFIG_HOME/vim $$HOME/.vim
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install skk dictionaries...$(COLOR_RESET)"
# 	@echo ""
# 	jisyo d
# 	@echo ""
# 	@echo "$(COLOR_HEADER)install vimplug...$(COLOR_RESET)"
# 	@echo ""
# 	curl -fLo $$HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# 	@echo ""
# 	@echo "$(COLOR_DONE)initialize done!$(COLOR_RESET)"
# 	@echo ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for macbook...$(COLOR_RESET)"
# 	@echo ""
# endif

# update macbook packages and apply configurations
macbook.update:
ifeq ($(IS_MACBOOK),1)
	@echo "$(COLOR_TITLE)update macbook...$(COLOR_RESET)"
	@echo ""
	make macbook.apply.system
	@echo ""
	make macbook.apply.home
	@echo ""
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for macbook...$(COLOR_RESET)"
endif

# apply macbook system configuration
macbook.apply.system:
ifeq ($(IS_MACBOOK),1)
	@echo "$(COLOR_TITLE)apply system configuration...$(COLOR_RESET)"
	@echo ""
	sudo darwin-rebuild switch --flake .#yanoMacBook
	@echo ""
	@echo "$(COLOR_DONE)apply system configuration done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for macbook...$(COLOR_RESET)"
endif

# apply macbook home configuration
macbook.apply.home:
ifeq ($(IS_MACBOOK),1)
	@echo "$(COLOR_TITLE)apply home configuration...$(COLOR_RESET)"
	@echo ""
	rm -fr ~/.config/karabiner/karabiner.json
	home-manager switch --flake .#yanosea@yanoMacBook
	@echo "$(COLOR_DONE)apply home configuration done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for macbook...$(COLOR_RESET)"
endif

#
# windows
#
.PHONY: windows.update windows.update.wingetpkglist

# initialize windows (these are notes for the initial environment construction)
# windows.init:
# ifeq ($(IS_WINDOWS),1)
# 	@Write-Host ""
# 	@Write-Host "initialize windows..." $(COLOR_TITLE)
# 	@Write-Host ""
# 	@Write-Host "install pwsh..." $(COLOR_HEADER)
# 	@Write-Host ""
# 	winget install Microsoft.PowerShell
# 	@Write-Host ""
# 	@Write-Host "install git..." $(COLOR_HEADER)
# 	@Write-Host ""
# 	winget install git
# 	@Write-Host ""
# 	@Write-Host "install scoop..." $(COLOR_HEADER)
# 	@Write-Host ""
# 	Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# 	Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
# 	@Write-Host ""
# 	@Write-Host "install ghq..." $(COLOR_HEADER)
# 	@Write-Host ""
# 	scoop install ghq
# 	@Write-Host ""
# 	@Write-Host "install winget packages..." $(COLOR_HEADER)
# 	@Write-Host ""
# 	winget import "$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json"
# 	@Write-Host ""
# 	@Write-Host "initialize windows done!" $(COLOR_DONE)
# 	@Write-Host ""
# else
# 	@echo ""
# 	@echo "$(COLOR_ERROR)this target is only for windows...$(COLOR_RESET)"
# 	@echo ""
# endif

# update windows
windows.update:
ifeq ($(IS_WINDOWS),1)
	@Write-Host "update windows..." $(COLOR_TITLE)
	@Write-Host ""
	winget upgrade --silent --all
	@Write-Host ""
	@Write-Host "update scoop..." $(COLOR_HEADER)
	@Write-Host ""
	scoop update
	@Write-Host ""
	@Write-Host "install new packages..." $(COLOR_HEADER)
	@Write-Host ""
	winget import "$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json"
	@Write-Host ""
	@Write-Host "update winget package list..." $(COLOR_TITLE)
	@Write-Host ""
	winget export -o "$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json"
	Get-Content -Path "$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json" | jq '.Sources[].Packages |= sort_by(.PackageIdentifier | ascii_downcase)' | Set-Content -Path "$$HOME\ghq\github.com\yanosea\yanoNixFiles\pkglist\winget\pkglist.json"
	@Write-Host ""
	@Write-Host "update done!" $(COLOR_DONE)
else
	@echo "$(COLOR_ERROR)this target is only for windows...$(COLOR_RESET)"
endif

#
# nix
#
.PHONY: nix.check nix.clean nix.format nix.gc.all nix.gc.system nix.gc.user nix.update all clean test

# nix check flake
nix.check:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)check flake...$(COLOR_RESET)"
	@echo ""
	nix flake check
	@echo ""
	@echo "$(COLOR_DONE)check done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
endif

# nix clean result directory
nix.clean:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)clean result directory...$(COLOR_RESET)"
	@echo ""
	rm -fr result
	@echo ""
	@echo "$(COLOR_DONE)clean done!$(COLOR_RESET)"
	@echo ""
else
	@echo ""
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
endif

# nix format files
nix.format:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)format files...$(COLOR_RESET)"
	@echo ""
	nix fmt
	@echo ""
	@echo "$(COLOR_DONE)format done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
endif

# nix garbage collection (all)
nix.gc.all:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)garbage collection (all)...$(COLOR_RESET)"
	@echo ""
	sudo nix-collect-garbage --delete-old
	nix-collect-garbage --delete-old
	@echo ""
	@echo "$(COLOR_DONE)garbage collection (all) done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
endif

# nix garbage collection (system)
nix.gc.system:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)garbage collection (system)...$(COLOR_RESET)"
	@echo ""
	sudo -i nix profile wipe-history
	sudo -i nix store gc
	@echo ""
	@echo "$(COLOR_DONE)garbage collection (system) done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
endif

# nix garbage collection (user)
nix.gc.user:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)garbage collection (user)...$(COLOR_RESET)"
	@echo ""
	nix profile wipe-history
	nix store gc
	@echo ""
	@echo "$(COLOR_DONE)garbage collection (user) done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
endif

# nix update flake.lock
nix.update:
ifeq ($(IS_WINDOWS),0)
	@echo "$(COLOR_TITLE)update flake.lock...$(COLOR_RESET)"
	@echo ""
	nix flake update
	@echo ""
	@echo "$(COLOR_DONE)update done!$(COLOR_RESET)"
else
	@echo "$(COLOR_ERROR)this target is only for non-windows...$(COLOR_RESET)"
endif

# required phony targets for standards
all: help
clean: nix.clean
test: nix.check

# help
.PHONY: help
help:
ifeq ($(IS_NIXOS),1)
	@echo "$(COLOR_TITLE)available targets:$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)  [for nixos]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)nixos.update$(COLOR_RESET)        - update whole yanoNixOs (settings, packages)"
	@echo "    $(COLOR_CMD)nixos.apply.system$(COLOR_RESET)  - apply yanoNixOs system configuration"
	@echo "    $(COLOR_CMD)nixos.apply.home$(COLOR_RESET)    - apply yanoNixOs home configuration"
	@echo ""
	@echo "$(COLOR_HEADER)  [for nix]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)nix.check$(COLOR_RESET)           - check configuration"
	@echo "    $(COLOR_CMD)nix.clean$(COLOR_RESET)           - remove result directory"
	@echo "    $(COLOR_CMD)nix.format$(COLOR_RESET)          - run treefmt"
	@echo "    $(COLOR_CMD)nix.gc.all$(COLOR_RESET)          - run nix garbage collection (all)"
	@echo "    $(COLOR_CMD)nix.gc.system$(COLOR_RESET)       - run nix garbage collection (system)"
	@echo "    $(COLOR_CMD)nix.gc.user$(COLOR_RESET)         - run nix garbage collection (user)"
	@echo "    $(COLOR_CMD)nix.update$(COLOR_RESET)          - update flake.lock file"
endif
ifeq ($(IS_NIXOS_WSL),1)
	@echo "$(COLOR_TITLE)available targets:$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)  [for nixos wsl]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)nixoswsl.update$(COLOR_RESET)        - update whole yanoNixOsWsl (settings, packages)"
	@echo "    $(COLOR_CMD)nixoswsl.apply.system$(COLOR_RESET)  - apply yanoNixOsWsl system configuration"
	@echo "    $(COLOR_CMD)nixoswsl.apply.home$(COLOR_RESET)    - apply yanoNixOsWsl home configuration"
	@echo ""
	@echo "$(COLOR_HEADER)  [for nix]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)nix.check$(COLOR_RESET)              - check configuration"
	@echo "    $(COLOR_CMD)nix.clean$(COLOR_RESET)              - remove result directory"
	@echo "    $(COLOR_CMD)nix.format$(COLOR_RESET)             - run treefmt"
	@echo "    $(COLOR_CMD)nix.gc.all$(COLOR_RESET)             - run nix garbage collection (all)"
	@echo "    $(COLOR_CMD)nix.gc.system$(COLOR_RESET)          - run nix garbage collection (system)"
	@echo "    $(COLOR_CMD)nix.gc.user$(COLOR_RESET)            - run nix garbage collection (user)"
	@echo "    $(COLOR_CMD)nix.update$(COLOR_RESET)             - update flake.lock file"
endif
ifeq ($(IS_MAC),1)
	@echo "$(COLOR_TITLE)available targets:$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)  [for mac]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)mac.update$(COLOR_RESET)        - update whole yanoMac (settings, packages)"
	@echo "    $(COLOR_CMD)mac.apply.system$(COLOR_RESET)  - apply yanoMac system configuration"
	@echo "    $(COLOR_CMD)mac.apply.home$(COLOR_RESET)    - apply yanoMac home configuration"
	@echo ""
	@echo "$(COLOR_HEADER)  [for nix]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)nix.check$(COLOR_RESET)         - check configuration"
	@echo "    $(COLOR_CMD)nix.clean$(COLOR_RESET)         - remove result directory"
	@echo "    $(COLOR_CMD)nix.format$(COLOR_RESET)        - run treefmt"
	@echo "    $(COLOR_CMD)nix.gc.all$(COLOR_RESET)        - run nix garbage collection (all)"
	@echo "    $(COLOR_CMD)nix.gc.system$(COLOR_RESET)     - run nix garbage collection (system)"
	@echo "    $(COLOR_CMD)nix.gc.user$(COLOR_RESET)       - run nix garbage collection (user)"
	@echo "    $(COLOR_CMD)nix.update$(COLOR_RESET)        - update flake.lock file"
endif
ifeq ($(IS_MACBOOK),1)
	@echo "$(COLOR_TITLE)available targets:$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_HEADER)  [for macbook]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)macbook.update$(COLOR_RESET)        - update whole yanoMacBook (settings, packages)"
	@echo "    $(COLOR_CMD)macbook.apply.system$(COLOR_RESET)  - apply yanoMacBook system configuration"
	@echo "    $(COLOR_CMD)macbook.apply.home$(COLOR_RESET)    - apply yanoMacBook home configuration"
	@echo ""
	@echo "$(COLOR_HEADER)  [for nix]$(COLOR_RESET)"
	@echo "    $(COLOR_CMD)nix.check$(COLOR_RESET)             - check configuration"
	@echo "    $(COLOR_CMD)nix.clean$(COLOR_RESET)             - remove result directory"
	@echo "    $(COLOR_CMD)nix.format$(COLOR_RESET)            - run treefmt"
	@echo "    $(COLOR_CMD)nix.gc.all$(COLOR_RESET)            - run nix garbage collection (all)"
	@echo "    $(COLOR_CMD)nix.gc.system$(COLOR_RESET)         - run nix garbage collection (system)"
	@echo "    $(COLOR_CMD)nix.gc.user$(COLOR_RESET)           - run nix garbage collection (user)"
	@echo "    $(COLOR_CMD)nix.update$(COLOR_RESET)            - update flake.lock file"
endif
ifeq ($(IS_WINDOWS),1)
	@Write-Host "available targets:" $(COLOR_TITLE)
	@Write-Host ""
	@Write-Host "[for windows]" $(COLOR_HEADER)
	@Write-Host "    windows.update  - update whole yanoWindows (settings, packages)" $(COLOR_CMD)
endif
